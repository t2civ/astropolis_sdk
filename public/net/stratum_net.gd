# stratum_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name StratumNet
extends RefCounted

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# A Body can have any number of Strata, each representing a geological
# layer and/or polity territory. A spacecraft Body will have 0 Strata.
# The vast majority of asteroids will have one (undifferentiated) Stratum.
#
# AI and GUI have access to estimated values only; server has actual.
# This component is different than others because it syncs offset values to
# represent estimation biases. Actual server values will be randomly offset
# from data table values (which are assumed to be public estimations).
#
# All resource indexing here is for the 'is_extraction == true' subset.
# Arrays are threadsafe (they are never resized after init).
# All Stratum data flows server -> interface.

enum { # _dirty bit flags
	DIRTY_HEADERS = 1,
	DIRTY_STRATUM = 1 << 1,
	DIRTY_SURVEY = 1 << 2,
}

var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)
var stratum_index := -1
var name: StringName
var stratum_group := -1 # stratum_groups.tsv
var polity_name: StringName # "" for commons

var body_radius := 0.0 # same as Body.m_radius
var inner_radius := 0.0 # 0.0 for undifferentiated body
var thickness := 0.0 # =body_radius for undifferentiated body
var spherical_fraction := 0.0 # of theoretical whole sphere strata
var volume := 0.0
var density := 0.0
var total_mass := 0.0
var is_atmosphere: bool # from strata.tsv
var survey_level := 0.0
var survey_type := -1 # surveys.tsv

var masses: Array[float]
var masses_cv: Array[float]
var dispersions: Array[float] # spatial heterogeneity; good for mining!
var dispersions_cv: Array[float]
var discoveries: Array[float] # derived from mass/total, dispersion, and survey_level


# indexing
static var _db_tables := IVTableData.db_tables
static var _extraction_resources: PackedInt32Array # maps index to resource_type
static var _resource_extractions: PackedInt32Array # maps resource_type to index
static var _survey_density_errors: PackedFloat32Array # coeff of variation
static var _survey_mass_errors: PackedFloat32Array
static var _survey_deposits_sigma: PackedFloat32Array
static var _res_mass_err_mult: PackedFloat32Array
static var _n_extraction_resources: int
static var _is_class_instanced := false


# TODO: Operations/Extractions organized by strata
#var mine_targets: Array # relative focus; index by is_mine_target
#var well_targets: Array # relative focus; index by is_well_target



static func _on_instanced() -> void:
	_extraction_resources = PackedInt32Array(IVTableData.get_db_true_rows(&"resources",
			&"is_extraction"))
	_resource_extractions = Utils.invert_packed_subset_indexing(_extraction_resources,
			IVTableData.table_n_rows[&"resources"])
	var surveys_table: Dictionary[StringName, Array] = _db_tables[&"surveys"]
	_survey_density_errors = PackedFloat32Array(surveys_table[&"density_error"])
	_survey_mass_errors = PackedFloat32Array(surveys_table[&"mass_error"])
	_survey_deposits_sigma = PackedFloat32Array(surveys_table[&"deposits_sigma"])
	var resources_table: Dictionary[StringName, Array] = _db_tables[&"resources"]
	_res_mass_err_mult = PackedFloat32Array(resources_table[&"mass_err_mult"])
	_n_extraction_resources = _extraction_resources.size()


func _init(is_new := false) -> void:
	const arrays := preload("uid://bv7xrcpcm24nc")
	if !_is_class_instanced:
		_is_class_instanced = true
		_on_instanced()

	if !is_new: # loaded game
		return
	masses = arrays.init_array(_n_extraction_resources, 0.0, TYPE_FLOAT)
	masses_cv = masses.duplicate()
	dispersions = masses.duplicate()
	dispersions_cv = masses.duplicate()
	discoveries = masses.duplicate()

# ********************************** READ *************************************
# all threadsafe

func get_volume() -> float:
	return volume


func get_total_mass() -> float:
	return total_mass


func get_mass(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return masses[index]


func get_mass_fraction(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return masses[index] / total_mass


func get_dispersion(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return dispersions[index]


## Return is [abundance, abundance_sd, dispersion, dispersion_sd, base_deposit,
## discovered], where abundance, base_deposit and discovered are fractions and
## dispersion is in log10 units.
func get_resource_data(resource_type: int) -> Array[float]:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var abundance := masses[index] / total_mass
	var abundance_sd := abundance * masses_cv[index]
	var dispersion := dispersions[index]
	var dispersion_sd := dispersion * dispersions_cv[index]
	var base_deposit := minf(1.0, abundance * 10 ** dispersion)
	var discovered := discoveries[index]
	return [abundance, abundance_sd, dispersion, dispersion_sd, base_deposit, discovered]


func get_base_deposit(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var abundance := masses[index] / total_mass
	var dispersion := dispersions[index]
	return minf(1.0, abundance * 10 ** dispersion)


func get_discovered(resource_type: int) -> float:
	# Roughly related to "scrape ratio" (inversely).
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return discoveries[index]


func get_max_discovered(resource_types: PackedInt32Array) -> float:
	# Roughly related to "scrape ratio" (inversely) for best target resource.
	var max_discovered := 0.0
	for resource_type in resource_types:
		var index: int = _resource_extractions[resource_type]
		assert(index != -1, "resource_type must have is_extraction == true")
		max_discovered = maxf(max_discovered, discoveries[index])
	return max_discovered

# *****************************************************************************
# sync


func set_network_init(data: Array) -> void:
	# NOT reference-safe!
	stratum_index = data[0]
	name = data[1]
	stratum_group = data[2]
	polity_name = data[3]
	body_radius = data[4]
	inner_radius = data[5]
	thickness = data[6]
	spherical_fraction = data[7]
	volume = data[8]
	density = data[9]
	total_mass = data[10]
	is_atmosphere = data[11]
	survey_level = data[12]
	survey_type = data[13]
	masses = data[14]
	masses_cv = data[15]
	dispersions = data[16]
	dispersions_cv = data[17]
	discoveries = data[18]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# Changes and sets from the server entity.
	const BIT_INDEXES := Utils.BIT_INDEXES
	
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]
	
	var svr_qtr := int_data[0]
	run_qtr = svr_qtr # Do we need this?
	
	var dirty := int_data[int_offset]
	int_offset += 1
	
	if dirty & DIRTY_STRATUM:
		body_radius = float_data[float_offset]
		float_offset += 1
		inner_radius = float_data[float_offset]
		float_offset += 1
		thickness = float_data[float_offset]
		float_offset += 1
		spherical_fraction = float_data[float_offset]
		float_offset += 1
		density = float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_SURVEY:
		survey_level = float_data[float_offset]
		float_offset += 1
		survey_type = int_data[int_offset]
		int_offset += 1
		masses_cv = float_data.slice(float_offset, float_offset + _n_extraction_resources)
		float_offset += _n_extraction_resources
		dispersions_cv = float_data.slice(float_offset, float_offset + _n_extraction_resources)
		float_offset += _n_extraction_resources
		discoveries = float_data.slice(float_offset, float_offset + _n_extraction_resources)
		float_offset += _n_extraction_resources
	
	var flags := int_data[int_offset]
	int_offset += 1
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		masses[index] = float_data[float_offset]
		float_offset += 1
		flags &= ~lsb
	flags = int_data[int_offset]
	int_offset += 1
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		dispersions[index] = float_data[float_offset]
		float_offset += 1
		flags &= ~lsb
	flags = int_data[int_offset]
	int_offset += 1
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		discoveries[index] = float_data[float_offset]
		float_offset += 1
		flags &= ~lsb
