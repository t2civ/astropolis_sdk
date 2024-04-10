# population_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name PopulationNet
extends NetComponent

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# Arrays indexed by population_type unless noted otherwise.
#
# TODO: Make interface component w/out server dirty flags & delta accumulators

# save/load persistence for server only
const PERSIST_PROPERTIES2: Array[StringName] = [
	&"_numbers",
	&"_delta_numbers",
	&"_intrinsic_growths",
	&"_carrying_capacities",
	&"_migration_pressures",
	&"_history_numbers",
	&"_is_facility",
	&"_dirty_numbers",
	&"_dirty_intrinsic_growths",
	&"_dirty_carrying_capacities",
	&"_dirty_migration_pressures",
]

# All data flows server -> interface.
var _numbers: Array[float]
var _delta_numbers: Array[float]
var _intrinsic_growths: Array[float] # Facility only
var _carrying_capacities: Array[float] # Facility only; indexed by carrying_capacity_group
var _migration_pressures: Array[float] # Facility only; +/- emigration/immigration

var _history_numbers: Array[Array] # Array for ea pop type; [..., qrt_before_last, last_qrt]

var _is_facility := false

# accumulators

# server dirty data (dirty indexes as bit flags; max 64)
var _dirty_numbers := 0
var _dirty_intrinsic_growths := 0
var _dirty_carrying_capacities := 0
var _dirty_migration_pressures := 0

static var _n_populations: int
static var _table_populations: Dictionary
static var _carrying_capacity_groups: Array[int]
static var _carrying_capacity_group2s: Array[int]
static var _is_class_instanced := false



func _init(is_new := false, is_facility_ := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_n_populations = _table_n_rows[&"populations"]
		_table_populations = _tables[&"populations"]
		_carrying_capacity_groups = _table_populations[&"carrying_capacity_group"]
		_carrying_capacity_group2s = _table_populations[&"carrying_capacity_group2"]
	if !is_new: # game load
		return
	_numbers = ivutils.init_array(_n_populations, 0.0, TYPE_FLOAT)
	_delta_numbers = _numbers.duplicate()
	_history_numbers = ivutils.init_array(_n_populations, [] as Array[float], TYPE_ARRAY)
	if !is_facility_:
		return
	_is_facility = true
	_intrinsic_growths = _numbers.duplicate()
	var n_carrying_capacity_groups: int = _table_n_rows.carrying_capacity_groups
	_carrying_capacities = ivutils.init_array(n_carrying_capacity_groups, 0.0, TYPE_FLOAT)
	_migration_pressures = _numbers.duplicate()


# ********************************* READ **************************************


func get_number(type := -1) -> float:
	if type == -1:
		return utils.get_float_array_sum(_numbers) + utils.get_float_array_sum(_delta_numbers)
	return _numbers[type] + _delta_numbers[type]


func get_intrinsic_growth(type: int) -> float:
	assert(_is_facility)
	return _intrinsic_growths[type]


func get_carrying_capacity(carrying_capacity_group: int) -> float:
	assert(_is_facility)
	return _carrying_capacities[carrying_capacity_group]


func get_carrying_capacity_for_population(type: int) -> float:
	# sums the _carrying_capacities that this population can occupy
	assert(_is_facility)
	var group: int = _carrying_capacity_groups[type]
	var group2: int = _carrying_capacity_group2s[type]
	var carrying_capacity: float = _carrying_capacities[group]
	if group2 != -1:
		carrying_capacity += _carrying_capacities[group2]
	return carrying_capacity


func get_number_for_carrying_capacity_group(carrying_capacity_group: int) -> float:
	# sums all populations that share this carrying_capacity_group
	assert(_is_facility)
	var number := 0.0
	var i := 0
	while i < _n_populations:
		if (_carrying_capacity_groups[i] == carrying_capacity_group
				or _carrying_capacity_group2s[i] == carrying_capacity_group):
			number += _numbers[i]
		i += 1
	return number


func get_effective_pk_ratio(population_type: int) -> float:
	# 'p/k' is 'population / carrying_capacity' from classic growth model:
	# https://en.wikipedia.org/wiki/Population_growth
	# This function attempts to account for populations that share overlapping
	# carrying_capacity_group. I.e., they can occupy the same "space", while
	# either may have alternative spaces to live in.
	# Returns INF if carrying_capacity == 0.0.
	assert(_is_facility)

	var carrying_capacity := get_carrying_capacity_for_population(population_type)
	if carrying_capacity == 0.0:
		return INF
	var init_ratio: float = _numbers[population_type] / carrying_capacity
	var group: int = _carrying_capacity_groups[population_type]
	# Sum ratios for populations that share our primary space. This will give
	# smaller penalty from other populations that have large alternative spaces
	# (due to large denominator).
	var pk_ratio := INF
	if _carrying_capacities[group] > 0.0:
		pk_ratio = init_ratio
		var i := 0
		while i < _n_populations:
			if i != population_type and _numbers[i] > 0.0:
				if _carrying_capacity_groups[i] == group or _carrying_capacity_group2s[i] == group:
					pk_ratio += _numbers[i] / get_carrying_capacity_for_population(i)
			i += 1
	
	var group2: int = _carrying_capacity_group2s[population_type]
	if group2 == -1:
		return pk_ratio
	
	# Do sum ratio for populations that share our secondary space. Perhaps this
	# space is less occupied and will give more favorable ratio.
	var pk_ratio2 := INF
	if _carrying_capacities[group2] > 0.0:
		pk_ratio2 = init_ratio
		var i := 0
		while i < _n_populations:
			if i != population_type and _numbers[i] > 0.0:
				if _carrying_capacity_groups[i] == group2 or _carrying_capacity_group2s[i] == group2:
					pk_ratio2 += _numbers[i] / get_carrying_capacity_for_population(i)
			i += 1
	
	if pk_ratio2 < pk_ratio:
		return pk_ratio2
	return pk_ratio


# **************************** SERVER ONLY !!!! ******************************


func change_number(type: int, change: float) -> void:
	assert(change == floor(change), "Expected integral value!")
	assert(change >= 0.0 or change >= -get_number(type))
	_delta_numbers[type] += change
	_dirty_numbers |= 1 << type


func set_intrinsic_growth(type: int, value: float) -> void:
	_intrinsic_growths[type] = value
	_dirty_intrinsic_growths |= 1 << type


func set_carrying_capacity(carrying_capacity_group: int, value: float) -> void:
	_carrying_capacities[carrying_capacity_group] = value
	_dirty_carrying_capacities |= 1 << carrying_capacity_group





# ********************************* SYNC **************************************


func take_dirty(data: Array) -> void:
	# save delta in data, apply & zero delta, reset dirty flags
	
	_int_data = data[1]
	_float_data = data[2]
	
	_take_floats_delta(_numbers, _delta_numbers, _dirty_numbers)
	
	_dirty_numbers = 0
	
	if !_is_facility:
		return
	
	_get_floats_dirty(_intrinsic_growths, _dirty_intrinsic_growths)
	_get_floats_dirty(_carrying_capacities, _dirty_carrying_capacities)
	_get_floats_dirty(_migration_pressures, _dirty_migration_pressures)
	
	_dirty_intrinsic_growths = 0
	_dirty_carrying_capacities = 0
	_dirty_migration_pressures = 0


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# apply delta & dirty flags
	_int_data = data[1]
	_float_data = data[2]
	_int_offset = int_offset
	_float_offset = float_offset
	
	var svr_qtr: int = _int_data[0]
	if run_qtr < svr_qtr:
		_update_history(svr_qtr) # before new quarter changes
	
	_dirty_numbers |= _add_floats_delta(_delta_numbers)
	
	if !_is_facility:
		return
	
	_dirty_intrinsic_growths |= _set_floats_dirty(_intrinsic_growths)
	_dirty_carrying_capacities |= _set_floats_dirty(_carrying_capacities)
	_dirty_migration_pressures |= _set_floats_dirty(_migration_pressures)


func _update_history(svr_qtr: int) -> void:
	if run_qtr == -1: # new - no history to save yet
		run_qtr = svr_qtr
		return
	while run_qtr < svr_qtr: # loop in case we missed a quarter
		var i := 0
		while i < _n_populations:
			_history_numbers[i].append(_numbers[i])
			i += 1
		run_qtr += 1

