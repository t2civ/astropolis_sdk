# composition.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name Composition
extends NetRef

# Follows "Net Ref" pattern for holding and syncing data. DON'T MODIFY!
# This is a replacement (NOT a subclass) for I, Voyager's IVComposition class.
#
# AI and GUI have access to estimated values only; server has actual.
# This Net Ref is different than others because it syncs offset values to
# represent estimation biases. Data table values are game start public
# *estimations*; actual values will differ.
#
# All resource indexing here is for the 'is_extraction = true' subset.
# Arrays are never resized after init, so they are threadsafe to read.
# All data in this Net Ref flows server -> interface.



enum { # _dirty bit flags
	DIRTY_HEADERS = 1,
	DIRTY_STRATUM = 1 << 1,
	DIRTY_ESTIMATION = 1 << 2,
}


const FOUR_THIRDS_PI := 4.0 / 3.0 * PI
const FOUR_PI := 4.0 * PI

const FREE_RESOURCE_MIN_FRACTION := 0.1

const PERSIST_PROPERTIES2: Array[StringName] = [
	&"name",
	&"stratum_type",
	&"polity_name",
	&"body_radius",
	&"outer_depth",
	&"thickness",
	&"spherical_fraction",
	&"area",
	&"density",
	&"volume",
	&"total_mass",
	&"masses",
	&"heterogeneities",
	&"survey_type",
	&"may_have_free_resources",
	&"density_bias",
	&"masses_biases",
	&"heterogeneities_biases",
	&"_dirty_masses",
	&"_dirty_heterogeneities",
]

var name: StringName
var stratum_type := -1 # strata.tsv
var polity_name: StringName # "" for commons

var body_radius := 0.0 # same as Body.m_radius
var outer_depth := 0.0 # of the strata (could be negative for atmosphere)
var thickness := 0.0 # of the strata, =body_radius for undifferentiated body
var spherical_fraction := 0.0 # of theoretical whole sphere strata
var area := 0.0 # determined by spherical_fraction (or visa versa)
var density := 0.0
var volume := 0.0 # calculated! Use API to get refreshed value!
var total_mass := 0.0 # calculated! Use API to get refreshed value!

var masses: Array[float]
var heterogeneities: Array[float] # variation within; this is good for mining!

var survey_type := -1 # surveys.tsv, table errors give estimation uncertainties

var may_have_free_resources: bool # from strata.tsv

# server only TODO: Dictionaries of biases indexed by player
var density_bias := 1.0 # the server is lying to you...
var masses_biases: Array[float]
var heterogeneities_biases: Array[float]

# dirty data
var _dirty_masses := 0 # dirty indexes as bit flags (max index 63)
var _dirty_heterogeneities := 0 # dirty indexes as bit flags (max index 63)

# not propagated
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



func _init(is_new := false, is_server := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_resource_maybe_free = _tables[&"resources"][&"maybe_free"]
		_extraction_resources = _tables[&"extraction_resources"]
		_resource_extractions = _tables[&"resource_extractions"]
		_survey_density_errors = _tables[&"surveys"][&"density_error"]
		_survey_masses_errors = _tables[&"surveys"][&"masses_error"]
		_survey_deposits_sds = _tables[&"surveys"][&"deposits_sigma"]
		
	if !is_new: # loaded game
		return
	var n_is_extraction_resources := _extraction_resources.size()
	masses = ivutils.init_array(n_is_extraction_resources, 0.0, TYPE_FLOAT)
	heterogeneities = masses.duplicate()
	if !is_server:
		return
	masses_biases = ivutils.init_array(n_is_extraction_resources, 1.0, TYPE_FLOAT)
	heterogeneities_biases = masses_biases.duplicate()


# ********************************** READ *************************************
# all threadsafe

func get_volume() -> float:
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return volume


func get_total_mass() -> float:
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return total_mass


func is_free_resource(resource_type: int) -> bool:
	if !may_have_free_resources:
		return false
	if !_resource_maybe_free[resource_type]:
		return false
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return masses[index] / total_mass >= FREE_RESOURCE_MIN_FRACTION


func get_mass(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	return masses[index]


func get_mass_fraction(resource_type: int) -> float:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	if _needs_volume_mass_calculation:
		calculate_volume_and_total_mass()
	return masses[index] / total_mass


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
	var p := mass / total_mass
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
	var p := mass / total_mass
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
		return mass / total_mass # what we would get below if calculated
	# boost vanishes as mass approaches 0 or 100% of the total
	var p := mass / total_mass
	var fractional_deposits := p + p * (1.0 - p) * deposits_boost
	if fractional_deposits > 1.0:
		fractional_deposits = 1.0
	return fractional_deposits
	


# *****************************************************************************
# server API

func change_mass(resource_type: int, change: float) -> void:
	var index: int = _resource_extractions[resource_type]
	assert(index != -1, "resource_type must have is_extraction == true")
	masses[index] += change
	_dirty_masses |= 1 << index


# *****************************************************************************
# sync

func get_server_init() -> Array:
	
	# reference-safe
	var est_masses := masses.duplicate()
	utils.multiply_float_array_by_array(est_masses, masses_biases)
	var est_heterogeneities := heterogeneities.duplicate()
	utils.multiply_float_array_by_array(est_heterogeneities, heterogeneities_biases)
	return [
		name,
		stratum_type,
		polity_name,
		body_radius,
		outer_depth,
		thickness,
		spherical_fraction,
		area,
		density * density_bias,
		est_masses,
		est_heterogeneities,
		survey_type,
		may_have_free_resources,
	]


func set_server_init(data: Array) -> void:
	# NOT reference-safe!
	name = data[0]
	stratum_type = data[1]
	polity_name = data[2]
	body_radius = data[3]
	outer_depth = data[4]
	thickness = data[5]
	spherical_fraction = data[6]
	area = data[7]
	density = data[8]
	masses = data[9]
	heterogeneities = data[10]
	survey_type = data[11]
	may_have_free_resources = data[12]


func get_server_dirty(data: Array) -> void:
	# get changed values or array indexes only; zero dirty flags
	
	var any_dirty := _dirty or _dirty_masses or _dirty_heterogeneities
	data.append(any_dirty)
	if !any_dirty:
		return

	# non-arrays
	data.append(_dirty)
	if _dirty & DIRTY_HEADERS: # very rare
		data.append(polity_name)
	if _dirty & DIRTY_STRATUM:
		data.append(body_radius)
		data.append(outer_depth)
		data.append(thickness)
		data.append(spherical_fraction)
		data.append(area)
		data.append(density * density_bias)
	if _dirty & DIRTY_ESTIMATION:
		data.append(survey_type)
	_dirty = 0
	
	var lsb: int # least significant bit
	var i: int
	
	# masses
	data.append(_dirty_masses)
	while _dirty_masses:
		lsb = _dirty_masses & -_dirty_masses
		i = LOG2_64[lsb]
		data.append(masses[i] * masses_biases[i])
		_dirty_masses &= ~lsb
	
	# heterogeneities
	data.append(_dirty_heterogeneities)
	while _dirty_heterogeneities:
		lsb = _dirty_heterogeneities & -_dirty_heterogeneities
		i = LOG2_64[lsb]
		data.append(heterogeneities[i] * heterogeneities_biases[i])
		_dirty_heterogeneities &= ~lsb


func sync_server_dirty(data: Array, k: int) -> int:
	# set changed values only
	
	if !data[k]: # any_dirty
		return k + 1
	k += 1
	
	# non-arrays
	var dirty_flags: int = data[k]
	k += 1
	if dirty_flags & DIRTY_HEADERS: # very rare
		polity_name = data[k]
		k += 1
	if dirty_flags & DIRTY_STRATUM:
		body_radius = data[k]
		outer_depth = data[k + 1]
		thickness = data[k + 2]
		spherical_fraction = data[k + 3]
		area = data[k + 4]
		density = data[k + 5]
		k += 6
		_needs_volume_mass_calculation = true
	if dirty_flags & DIRTY_ESTIMATION:
		survey_type = data[k]
		k += 1
	
	var lsb: int # least significant bit
	var i: int
	
	# masses
	dirty_flags = data[k]
	k += 1
	while dirty_flags:
		lsb = dirty_flags & -dirty_flags
		i = LOG2_64[lsb]
		masses[i] = data[k]
		k += 1
		dirty_flags &= ~lsb
	
	# heterogeneities
	dirty_flags = data[k]
	k += 1
	while dirty_flags:
		lsb = dirty_flags & -dirty_flags
		i = LOG2_64[lsb]
		heterogeneities[i] = data[k]
		k += 1
		dirty_flags &= ~lsb

	return k


func calculate_volume_and_total_mass() -> void:
	# area accounts for spherical_fraction, so use either to reduce calculation
	if thickness == body_radius and outer_depth == 0.0: # full sphere
		# spherical_fraction = a / (4 PI r^2)   # area / area of full sphere
		# v = spherical_fraction * 4/3 PI r^3
		# v = a / (4 PI r^2)     * 4/3 PI r^3
		# simplify:
		volume =  area * body_radius / 3.0
	else:
		if thickness / body_radius < 0.01: # thin layer approximation
			volume = area * thickness
		else:
			var outer_radius := body_radius - outer_depth
			var inner_radius := outer_radius - thickness
			volume = spherical_fraction * FOUR_THIRDS_PI * (
					outer_radius * outer_radius * outer_radius
					- inner_radius * inner_radius * inner_radius)
	
	total_mass = volume * density
	_needs_volume_mass_calculation = false

