# population.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name Population
extends NetRef

# Arrays indexed by population_type unless noted otherwise.

# save/load persistence for server only
const PERSIST_PROPERTIES2: Array[StringName] = [
	&"numbers",
	&"growth_rates",
	&"carrying_capacities",
	&"immigration_attractions",
	&"emigration_pressures",
	&"history_numbers",
	&"_is_facility",
	&"_dirty_numbers",
	&"_dirty_carrying_capacities",
	&"_dirty_growth_rates",
	&"_dirty_immigration_attractions",
	&"_dirty_emigration_pressures",
]

# Interface read-only! All data flows server -> interface.
var numbers: Array[float]
var growth_rates: Array[float] # Facility only
var carrying_capacities: Array[float] # Facility only; indexed by carrying_capacity_group
var immigration_attractions: Array[float] # Facility only
var emigration_pressures: Array[float] # Facility only
var history_numbers: Array[Array] # Array for ea pop type; [..., qrt_before_last, last_qrt]

var _is_facility := false

# server dirty data (dirty indexes as bit flags; max 64)
var _dirty_numbers := 0
var _dirty_growth_rates := 0
var _dirty_carrying_capacities := 0
var _dirty_immigration_attractions := 0
var _dirty_emigration_pressures := 0

static var _n_populations: int
static var _table_populations: Dictionary
static var _carrying_capacity_groups: Array[int]
static var _carrying_capacity_group2s: Array[int]
static var _is_class_instanced := false



func _init(is_new := false, is_facility := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_n_populations = _table_n_rows[&"populations"]
		_table_populations = _tables[&"populations"]
		_carrying_capacity_groups = _table_populations[&"carrying_capacity_group"]
		_carrying_capacity_group2s = _table_populations[&"carrying_capacity_group2"]
	if !is_new: # game load
		return
	numbers = ivutils.init_array(_n_populations, 0.0, TYPE_FLOAT)
	history_numbers = ivutils.init_array(_n_populations, [] as Array[float], TYPE_ARRAY)
	if !is_facility:
		return
	_is_facility = true
	growth_rates = numbers.duplicate()
	var n_carrying_capacity_groups: int = _table_n_rows.carrying_capacity_groups
	carrying_capacities = ivutils.init_array(n_carrying_capacity_groups, 0.0, TYPE_FLOAT)
	immigration_attractions = numbers.duplicate()
	emigration_pressures = numbers.duplicate()


# ********************************* READ **************************************


func get_number(population_type: int) -> float:
	return numbers[population_type]


func get_number_total() -> float:
	return utils.get_float_array_sum(numbers)


func get_carrying_capacity_for_population(population_type: int) -> float:
	# sums the carrying_capacities that this population can occupy
	var group: int = _carrying_capacity_groups[population_type]
	var group2: int = _carrying_capacity_group2s[population_type]
	var carrying_capacity: float = carrying_capacities[group]
	if group2 != -1:
		carrying_capacity += carrying_capacities[group2]
	return carrying_capacity


func get_number_for_carrying_capacity_group(carrying_capacity_group: int) -> float:
	# sums all populations that share this carrying_capacity_group
	var number := 0.0
	var i := 0
	while i < _n_populations:
		if _carrying_capacity_groups[i] == carrying_capacity_group \
				or _carrying_capacity_group2s[i] == carrying_capacity_group:
			number += numbers[i]
		i += 1
	return number


func get_effective_pk_ratio(population_type: int) -> float:
	# 'p/k' is 'population / carrying_capacity' from classic growth model:
	# https://en.wikipedia.org/wiki/Population_growth
	# This function attempts to account for populations that share overlapping
	# carrying_capacity_group. I.e., they can occupy the same "space", while
	# either may have alternative spaces to live in.
	# Returns INF if carrying_capacity == 0.0.

	var carrying_capacity := get_carrying_capacity_for_population(population_type)
	if carrying_capacity == 0.0:
		return INF
	var init_ratio: float = numbers[population_type] / carrying_capacity
	var group: int = _carrying_capacity_groups[population_type]
	# Sum ratios for populations that share our primary space. This will give
	# smaller penalty from other populations that have large alternative spaces
	# (due to large denominator).
	var pk_ratio := INF
	if carrying_capacities[group] > 0.0:
		pk_ratio = init_ratio
		var i := 0
		while i < _n_populations:
			if i != population_type and numbers[i] > 0.0:
				if _carrying_capacity_groups[i] == group or _carrying_capacity_group2s[i] == group:
					pk_ratio += numbers[i] / get_carrying_capacity_for_population(i)
			i += 1
	
	var group2: int = _carrying_capacity_group2s[population_type]
	if group2 == -1:
		return pk_ratio
	
	# Do sum ratio for populations that share our secondary space. Perhaps this
	# space is less occupied and will give more favorable ratio.
	var pk_ratio2 := INF
	if carrying_capacities[group2] > 0.0:
		pk_ratio2 = init_ratio
		var i := 0
		while i < _n_populations:
			if i != population_type and numbers[i] > 0.0:
				if _carrying_capacity_groups[i] == group2 or _carrying_capacity_group2s[i] == group2:
					pk_ratio2 += numbers[i] / get_carrying_capacity_for_population(i)
			i += 1
	
	if pk_ratio2 < pk_ratio:
		return pk_ratio2
	return pk_ratio


# **************************** SERVER ONNLY !!!! ******************************


func change_number(population_type: int, change: float) -> void:
	assert(change == floor(change), "Expected integral value!")
	numbers[population_type] += change
	_dirty_numbers |= 1 << population_type


func change_growth_rate(population_type: int, change: float) -> void:
	growth_rates[population_type] += change
	_dirty_growth_rates |= 1 << population_type


func change_carrying_capacity(carrying_capacity_group: int, change: float) -> void:
	carrying_capacities[carrying_capacity_group] += change
	_dirty_carrying_capacities |= 1 << carrying_capacity_group





# ********************************* SYNC **************************************

func take_server_delta(data: Array) -> void:
	# facility accumulator only; zero values and dirty flags
	
	_int_data = data[0]
	_float_data = data[1]
	
	_int_data[8] = _int_data.size()
	_int_data[9] = _float_data.size()
	
	_append_and_zero_dirty_floats(numbers, _dirty_numbers)
	_dirty_numbers = 0
	_append_and_zero_dirty_floats(growth_rates, _dirty_growth_rates)
	_dirty_growth_rates = 0
	_append_and_zero_dirty_floats(carrying_capacities, _dirty_carrying_capacities)
	_dirty_carrying_capacities = 0
	_append_and_zero_dirty_floats(immigration_attractions, _dirty_immigration_attractions)
	_dirty_immigration_attractions = 0
	_append_and_zero_dirty_floats(emigration_pressures, _dirty_emigration_pressures)
	_dirty_emigration_pressures = 0


func add_server_delta(data: Array) -> void:
	# any target; reference safe
	
	_int_data = data[0]
	_float_data = data[1]
	
	_int_offset = _int_data[8]
	_float_offset = _int_data[9]
	
	var svr_qtr: int = _int_data[0]
	if run_qtr < svr_qtr:
		_update_history(svr_qtr) # before new quarter changes
	
	_add_dirty_floats(numbers)
	
	if !_is_facility:
		return
	
	_add_dirty_floats(growth_rates)
	_add_dirty_floats(carrying_capacities)
	_add_dirty_floats(immigration_attractions)
	_add_dirty_floats(emigration_pressures)


func _update_history(svr_qtr: int) -> void:
	if run_qtr == -1: # new - no history to save yet
		run_qtr = svr_qtr
		return
	while run_qtr < svr_qtr: # loop in case we missed a quarter
		var i := 0
		while i < _n_populations:
			history_numbers[i].append(numbers[i])
			i += 1
		run_qtr += 1

