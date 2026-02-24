# stratum_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
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
var strata_index := -1
var name: StringName
var stratum_group := -1 # stratum_groups.tsv
var polity_name: StringName # "" for commons

var body_radius := 0.0 # same as Body.m_radius
var inner_radius := 0.0 # 0.0 for undifferentiated body
var thickness := 0.0 # =body_radius for undifferentiated body
var spherical_fraction := 0.0 # of theoretical whole sphere strata
var density := 0.0

var masses: Array[float]
var masses_cv: Array[float]
var dispersions: Array[float] # spatial heterogeneity; good for mining!
var dispersions_cv: Array[float]

var survey_type := -1 # surveys.tsv, table errors give estimation uncertainties

var is_atmosphere: bool # from strata.tsv

# derive when needed
var _volume := 0.0
var _total_mass := 0.0
var _dirty_volume_mass := true

var _sync := SyncHelper.new()

# indexing
static var _db_tables := IVTableData.db_tables
static var _tables_aux: Dictionary = ThreadsafeGlobal.tables_aux
static var _extraction_resources: Array[int] # maps index to resource_type
static var _resource_extractions: Array[int] # maps resource_type to index
static var _survey_density_errors: Array[float] # coeff of variation
static var _survey_mass_errors: Array[float]
static var _survey_deposits_sigma: Array[float]
static var _res_mass_err_mult: Array[float]
static var _is_class_instanced := false
static var _n_extraction_resources: int


# TODO: Operations/Extractions organized by strata
#var mine_targets: Array # relative focus; index by is_mine_target
#var well_targets: Array # relative focus; index by is_well_target



func _init(is_new := false, _is_server := false) -> void:
	const arrays := preload("uid://bv7xrcpcm24nc")
	if !_is_class_instanced:
		_is_class_instanced = true
		_extraction_resources = _tables_aux[&"extraction_resources"]
		_resource_extractions = _tables_aux[&"resource_extractions"]
		_survey_density_errors = _db_tables[&"surveys"][&"density_error"]
		_survey_mass_errors = _db_tables[&"surveys"][&"mass_error"]
		_survey_deposits_sigma = _db_tables[&"surveys"][&"deposits_sigma"]
		_res_mass_err_mult = _db_tables[&"resources"][&"mass_err_mult"]
		_n_extraction_resources = _extraction_resources.size()
		
	if !is_new: # loaded game
		return
	masses = arrays.init_array(_n_extraction_resources, 0.0, TYPE_FLOAT)
	masses_cv = masses.duplicate()
	dispersions = masses.duplicate()
	dispersions_cv = masses.duplicate()

# ********************************** READ *************************************
# all threadsafe

func get_volume() -> float:
	if _dirty_volume_mass:
		reset_volume_mass()
	return _volume


func get_total_mass() -> float:
	if _dirty_volume_mass:
		reset_volume_mass()
	return _total_mass


func get_mass(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return masses[index]


func get_mass_fraction(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	if _dirty_volume_mass:
		reset_volume_mass()
	return masses[index] / _total_mass


func get_dispersion(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return dispersions[index]


## Return is [abundance, abundance_sd, dispersion, dispersion_sd, base_deposits,
## kn_deposits], where abundance and kn_deposits are fractions of 1.0 and
## dispersion is in log10 units.
## FIXME: kn_deposits = base_deposits for now. Needs survey_level adjustment.
func get_resource_data(resource_type: int) -> Array[float]:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	if _dirty_volume_mass:
		reset_volume_mass()
	var abundance := masses[index] / _total_mass
	var abundance_sd := abundance * masses_cv[index]
	var dispersion := dispersions[index]
	var dispersion_sd := dispersion * dispersions_cv[index]
	var base_deposits := minf(1.0, abundance * 10 ** dispersion)
	return [abundance, abundance_sd, dispersion, dispersion_sd, base_deposits, base_deposits]


func get_base_deposit(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	if _dirty_volume_mass:
		reset_volume_mass()
	var abundance := masses[index] / _total_mass
	var dispersion := dispersions[index]
	return minf(1.0, abundance * 10 ** dispersion)


func get_discovered(resource_type: int) -> float:
	# FIXME: discovered == base_deposits for now. Needs survey_level adjustment.
	return get_base_deposit(resource_type)


func get_max_discovered(resource_types: Array[int]) -> float:
	# Roughly related to "scrape ratio" (inversely) for best target resource.
	var max_discovered := 0.0
	for resource_type in resource_types:
		var discovered := get_discovered(resource_type)
		if discovered == 1.0:
			return 1.0
		if max_discovered < discovered:
			max_discovered = discovered
	return max_discovered

# *****************************************************************************
# sync


func set_network_init(data: Array) -> void:
	# NOT reference-safe!
	strata_index = data[0]
	name = data[1]
	stratum_group = data[2]
	polity_name = data[3]
	body_radius = data[4]
	inner_radius = data[5]
	thickness = data[6]
	spherical_fraction = data[7]
	density = data[8]
	masses = data[9]
	masses_cv = data[10]
	dispersions = data[11]
	dispersions_cv = data[12]
	survey_type = data[13]
	is_atmosphere = data[14]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# Changes and sets from the server entity.
	
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
		_dirty_volume_mass = true
	if dirty & DIRTY_SURVEY:
		survey_type = int_data[int_offset]
		int_offset += 1
		masses_cv = float_data.slice(float_offset, float_offset + _n_extraction_resources)
		float_offset += _n_extraction_resources
		dispersions_cv = float_data.slice(float_offset, float_offset + _n_extraction_resources)
		float_offset += _n_extraction_resources
	
	_sync.init_for_add(int_data, float_data, int_offset, float_offset)
	_sync.set_floats_dirty(masses)
	_sync.set_floats_dirty(dispersions)

# *****************************************************************************

func reset_volume_mass() -> void:
	const FOUR_THIRDS_PI := 4.0 / 3.0 * PI
	var outer_radius := inner_radius + thickness
	_volume = spherical_fraction * FOUR_THIRDS_PI * (
			outer_radius * outer_radius * outer_radius
			- inner_radius * inner_radius * inner_radius)
	_total_mass = _volume * density
	_dirty_volume_mass = false
