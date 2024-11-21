# composition_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name CompositionNet
extends RefCounted

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# This is a replacement (NOT a subclass) for I, Voyager's IVComposition class.
#
# A Body can have any number of Compositions, each representing a geological
# layer and/or polity territory. A spacecraft Body will have 0 Compositions.
# The vast majority of asteroids will have one (undifferentiated) Composition.
#
# AI and GUI have access to estimated values only; server has actual.
# This component is different than others because it syncs offset values to
# represent estimation biases. Actual server values will be randomly offset
# from data table values (which are assumed to be public estimations).
#
# All resource indexing here is for the 'is_extraction == true' subset.
# Arrays are never resized after init, so they are threadsafe to read.
# All Composition data flows server -> interface.

enum { # _dirty bit flags
	DIRTY_HEADERS = 1,
	DIRTY_STRATUM = 1 << 1,
	DIRTY_ESTIMATION = 1 << 2,
}

const ivutils := preload("res://addons/ivoyager_core/static/utils.gd")

const FOUR_THIRDS_PI := 4.0 / 3.0 * PI
const FOUR_PI := 4.0 * PI


var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)
var compositions_index := -1
var name: StringName
var stratum_type := -1 # strata.tsv
var polity_name: StringName # "" for commons

var body_radius := 0.0 # same as Body.m_radius
var outer_radius := 0.0 # could be > body_radius (e.g., atmosphere)
var thickness := 0.0 # of the strata, =body_radius for undifferentiated body
var spherical_fraction := 0.0 # of theoretical whole sphere strata
var density := 0.0

var masses: Array[float]
var variances: Array[float] # spatial heterogeneity; this is good for mining!

var survey_type := -1 # surveys.tsv, table errors give estimation uncertainties

var is_atmosphere: bool # from strata.tsv

# derive as needed
var _volume := 0.0
var _total_mass := 0.0
var _needs_volume_mass_calculation := true

var _sync := SyncHelper.new()

# indexing
static var _tables: Dictionary = IVTableData.tables
static var _tables_aux: Dictionary = ThreadsafeGlobal.tables_aux
static var _extraction_resources: Array[int] # maps index to resource_type
static var _resource_extractions: Array[int] # maps resource_type to index
static var _survey_density_errors: Array[float] # coeff of variation
static var _survey_mass_errors: Array[float]
static var _survey_deposits_sigma: Array[float]
static var _res_mass_err_mult: Array[float]
static var _is_class_instanced := false


# TODO: Operations/Extractions organized by strata
#var mine_targets: Array # relative focus; index by is_mine_target
#var well_targets: Array # relative focus; index by is_well_target



func _init(is_new := false, _is_server := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_extraction_resources = _tables_aux[&"extraction_resources"]
		_resource_extractions = _tables_aux[&"resource_extractions"]
		_survey_density_errors = _tables[&"surveys"][&"density_error"]
		_survey_mass_errors = _tables[&"surveys"][&"mass_error"]
		_survey_deposits_sigma = _tables[&"surveys"][&"deposits_sigma"]
		_res_mass_err_mult = _tables[&"resources"][&"mass_err_mult"]
		
	if !is_new: # loaded game
		return
	var n_is_extraction_resources := _extraction_resources.size()
	masses = ivutils.init_array(n_is_extraction_resources, 0.0, TYPE_FLOAT)
	variances = masses.duplicate()

# ********************************** READ *************************************
# all threadsafe

func is_bulk() -> bool:
	return outer_radius == thickness and spherical_fraction == 1.0


func is_whole_depth() -> bool:
	return outer_radius == thickness


func is_whole_area() -> bool:
	return spherical_fraction == 1.0


func get_volume() -> float:
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return _volume


func get_total_mass() -> float:
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return _total_mass


func get_mass(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return masses[index]


func get_mass_fraction(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return masses[index] / _total_mass


func get_variance(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return variances[index]


func get_variance_fraction(resource_type: int) -> float:
	# Fractional variance vanishes as mass approaches 0 or 100% of the total
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var mass: float = masses[index]
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	var p := mass / _total_mass
	return variances[index] * p * (1.0 - p)


func get_density_error() -> float:
	var error: float = _survey_density_errors[survey_type]
	return density * error


func get_mass_error(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var error: float = _survey_mass_errors[survey_type] * _res_mass_err_mult[resource_type]
	return masses[index] * error


func get_mass_error_fraction(resource_type: int) -> float:
	# Fractional error vanishes as mass approaches 0 or 100% of the total
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var error: float = _survey_mass_errors[survey_type] * _res_mass_err_mult[resource_type]
	var mass: float = masses[index]
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	var p := mass / _total_mass
	return error * p * (1.0 - p)


func get_deposit_boost(resource_type: int) -> float:
	# Must have a boost from our survey AND variance
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return _survey_deposits_sigma[survey_type] * variances[index]


func get_deposit_fraction(resource_type: int, zero_if_no_boost := false) -> float:
	# Fictional concept, roughly related to scrape ratio at best known deposits.
	# Max 1.0.
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var deposits_boost: float = _survey_deposits_sigma[survey_type] * variances[index]
	if zero_if_no_boost and deposits_boost == 0.0:
		return 0.0 # allows hide in GUI if deposits would equal mass_fraction
	var mass: float = masses[index]
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	var p := mass / _total_mass # mass fraction
	var fractional_deposits := p + deposits_boost * p * (1.0 - p) # boost from p
	return minf(fractional_deposits, 1.0)


func get_deposits_fraction(resource_types: Array[int]) -> float:
	# E.g., [methane_type, ethane_type, helium_type] for total 'gas' deposits.
	# >1.0 possible but shouldn't happen for actual extraction subsets.
	var sum := 0.0
	for resource_type in resource_types:
		sum += get_deposit_fraction(resource_type)
	return sum


# *****************************************************************************
# sync


func set_network_init(data: Array) -> void:
	# NOT reference-safe!
	compositions_index = data[0]
	name = data[1]
	stratum_type = data[2]
	polity_name = data[3]
	body_radius = data[4]
	outer_radius = data[5]
	thickness = data[6]
	spherical_fraction = data[7]
	density = data[8]
	masses = data[9]
	variances = data[10]
	survey_type = data[11]
	is_atmosphere = data[12]


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
		outer_radius = float_data[float_offset]
		float_offset += 1
		thickness = float_data[float_offset]
		float_offset += 1
		spherical_fraction = float_data[float_offset]
		float_offset += 1
		density = float_data[float_offset]
		float_offset += 1
		_needs_volume_mass_calculation = true
	if dirty & DIRTY_ESTIMATION:
		survey_type = int_data[int_offset]
		int_offset += 1
	
	_sync.init_for_add(int_data, float_data, int_offset, float_offset)
	_sync.set_floats_dirty(masses)
	_sync.set_floats_dirty(variances)

# *****************************************************************************

func calculate_volume_and_total_mass() -> void:
	var inner_radius := outer_radius - thickness
	_volume = spherical_fraction * FOUR_THIRDS_PI * (
			outer_radius * outer_radius * outer_radius
			- inner_radius * inner_radius * inner_radius)
	_total_mass = _volume * density
	_needs_volume_mass_calculation = false
