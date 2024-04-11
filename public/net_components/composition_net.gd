# composition_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name CompositionNet
extends NetComponent

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
# This NetComponent is different than others because it syncs offset values to
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


const FOUR_THIRDS_PI := 4.0 / 3.0 * PI
const FOUR_PI := 4.0 * PI

const FREE_RESOURCE_MIN_FRACTION := 0.1


var compositions_index := -1
var name: StringName
var stratum_type := -1 # strata.tsv
var polity_name: StringName # "" for commons

var body_radius := 0.0 # same as Body.m_radius
var outer_depth := 0.0 # of the strata (could be negative for atmosphere)
var thickness := 0.0 # of the strata, =body_radius for undifferentiated body
var spherical_fraction := 0.0 # of theoretical whole sphere strata
var area := 0.0 # determined by spherical_fraction (or visa versa)
var density := 0.0

var masses: Array[float]
var heterogeneities: Array[float] # variation within; this is good for mining!

var survey_type := -1 # surveys.tsv, table errors give estimation uncertainties

var may_have_free_resources: bool # from strata.tsv

# derive as needed
var _volume := 0.0
var _total_mass := 0.0
var _needs_volume_mass_calculation := true

# indexing
static var _resource_maybe_free: Array[bool]
static var _extraction_resources: Array[int] # maps index to resource_type
static var _resource_extractions: Array[int] # maps resource_type to index
static var _survey_density_errors: Array[float] # coeff of variation
static var _survey_masses_errors: Array[float]
static var _survey_deposits_sds: Array[float]
static var _is_class_instanced := false


# TODO: Operations/Extractions organized by strata
#var mine_targets: Array # relative focus; index by is_mine_target
#var well_targets: Array # relative focus; index by is_well_target



func _init(is_new := false, _is_server := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_resource_maybe_free = _tables[&"resources"][&"maybe_free"]
		_extraction_resources = tables_aux[&"extraction_resources"]
		_resource_extractions = tables_aux[&"resource_extractions"]
		_survey_density_errors = _tables[&"surveys"][&"density_error"]
		_survey_masses_errors = _tables[&"surveys"][&"masses_error"]
		_survey_deposits_sds = _tables[&"surveys"][&"deposits_sigma"]
		
	if !is_new: # loaded game
		return
	var n_is_extraction_resources := _extraction_resources.size()
	masses = ivutils.init_array(n_is_extraction_resources, 0.0, TYPE_FLOAT)
	heterogeneities = masses.duplicate()

# ********************************** READ *************************************
# all threadsafe


func get_volume() -> float:
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return _volume


func get_total_mass() -> float:
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return _total_mass


func is_free_resource(resource_type: int) -> bool:
	if !may_have_free_resources:
		return false
	if !_resource_maybe_free[resource_type]:
		return false
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return masses[index] / _total_mass >= FREE_RESOURCE_MIN_FRACTION


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


func get_heterogeneity(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return heterogeneities[index]


func get_fractional_heterogeneity(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var mass: float = masses[index]
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	# fractional_heterogeneity vanishes as mass approaches 0 or 100% of the total
	var p := mass / _total_mass
	return p * (1.0 - p) * heterogeneities[index]


func get_density_uncertainty() -> float:
	var error: float = _survey_density_errors[survey_type]
	return density * error


func get_mass_uncertainty(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var error: float = _survey_masses_errors[survey_type]
	return masses[index] * error


func get_fractional_mass_uncertainty(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var error: float = _survey_masses_errors[survey_type]
	var mass: float = masses[index]
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	# fraction error vanishes as mass approaches 0 or 100% of the total
	var p := mass / _total_mass
	return p * (1.0 - p) * error # tested on example data


func get_deposits_boost(resource_type: int) -> float:
	# must have a boost from our survey AND heterogeneity
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return _survey_deposits_sds[survey_type] * heterogeneities[index]


func get_fractional_deposits(resource_type: int, zero_if_no_boost := false) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	var deposits_boost: float = _survey_deposits_sds[survey_type] * heterogeneities[index]
	if zero_if_no_boost and deposits_boost == 0.0:
		return 0.0 # allows hide in GUI if deposits would equal mass_fraction
	var mass: float = masses[index]
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	if deposits_boost == 0.0:
		return mass / _total_mass # what we would get below if calculated
	# boost vanishes as mass approaches 0 or 100% of the total
	var p := mass / _total_mass
	var fractional_deposits := p + p * (1.0 - p) * deposits_boost
	if fractional_deposits > 1.0:
		fractional_deposits = 1.0
	return fractional_deposits


# *****************************************************************************
# sync


func set_network_init(data: Array) -> void:
	# NOT reference-safe!
	compositions_index = data[0]
	name = data[1]
	stratum_type = data[2]
	polity_name = data[3]
	body_radius = data[4]
	outer_depth = data[5]
	thickness = data[6]
	spherical_fraction = data[7]
	area = data[8]
	density = data[9]
	masses = data[10]
	heterogeneities = data[11]
	survey_type = data[12]
	may_have_free_resources = data[13]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# apply deltas and sets
	_int_data = data[1]
	_float_data = data[2]
	_int_offset = int_offset
	_float_offset = float_offset
	
	var svr_qtr := _int_data[0]
	run_qtr = svr_qtr # Do we need this?
	
	var dirty := _int_data[_int_offset]
	_int_offset += 1
	
	if dirty & DIRTY_STRATUM:
		body_radius = _float_data[_float_offset]
		_float_offset += 1
		outer_depth = _float_data[_float_offset]
		_float_offset += 1
		thickness = _float_data[_float_offset]
		_float_offset += 1
		spherical_fraction = _float_data[_float_offset]
		_float_offset += 1
		area = _float_data[_float_offset]
		_float_offset += 1
		density = _float_data[_float_offset]
		_float_offset += 1
		_needs_volume_mass_calculation = true
	if dirty & DIRTY_ESTIMATION:
		survey_type = _int_data[_int_offset]
		_int_offset += 1
	
	_set_floats_dirty(masses)
	_set_floats_dirty(heterogeneities)

# *****************************************************************************

func calculate_volume_and_total_mass() -> void:
	# area accounts for spherical_fraction, so use either to reduce calculation
	if thickness == body_radius and outer_depth == 0.0: # full sphere
		# spherical_fraction = a / (4 PI r^2)   # area / area of full sphere
		# v = spherical_fraction * 4/3 PI r^3
		# v = a / (4 PI r^2)     * 4/3 PI r^3
		# simplify:
		_volume =  area * body_radius / 3.0
	else:
		if thickness / body_radius < 0.01: # thin layer approximation
			_volume = area * thickness
		else:
			var outer_radius := body_radius - outer_depth
			var inner_radius := outer_radius - thickness
			_volume = spherical_fraction * FOUR_THIRDS_PI * (
					outer_radius * outer_radius * outer_radius
					- inner_radius * inner_radius * inner_radius)
	
	_total_mass = _volume * density
	_needs_volume_mass_calculation = false

