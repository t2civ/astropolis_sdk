# operations_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name OperationsNet
extends NetComponent

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# Arrays indexed by operation_type, except where noted.
#
# 'est_' financials are Facility & Player only.
# '_op_logics' and '_op_commands' are Facility only.
# All vars are Interface read-only except for '_op_commands', which has the only
# data that flows Interface -> Server. Use API to set!
#
# Each op_group has 1 or more operations and is (for all purposes) the sum of
# its operations. Some op_groups can shift more easily among their ops (e.g.,
# refining). Others shift only over very long periods (e.g., iron mines don't
# change into mineral mines overnight, but may shift slowly by attrition and
# replacement).
#
# TODO: Make interface component w/out server dirty flags & delta accumulators

enum OpLogics { # current state and why
	IS_IDLE_UNPROFITABLE,
	IS_IDLE_COMMAND,
	MINIMIZE_UNPROFITABLE,
	MINIMIZE_COMMAND,
	MAINTAIN_COMMAND,
	RUN_50_PERCENT_COMMAND,
	MAXIMIZE_NEW_MARKET,
	MAXIMIZE_PROFITABLE,
	MAXIMIZE_SHORTAGES,
	MAXIMIZE_COMMITMENTS,
	MAXIMIZE_COMMAND,
	N_OP_LOGICS,
}

enum OpCommands {
	AUTOMATE, # self-manage for shortages, commitments or profit
	IDLE, # caution! some ops are hard to restart!
	MINIMIZE, # winddown to idle or low rate, depending on operation
	MAINTAIN,
	RUN_50_PERCENT,
	MAXIMIZE, # windup to max
	N_OP_COMMANDS,
}

enum { # _dirty
	DIRTY_LFQ_REVENUE = 1,
	DIRTY_LFQ_GROSS_OUTPUT = 1 << 1,
	DIRTY_LFQ_NET_INCOME = 1 << 2,
	DIRTY_CONSTRUCTIONS = 1 << 3,
}

# save/load persistence for server only
const PERSIST_PROPERTIES2: Array[StringName] = [
	&"_lfq_revenue",
	&"_delta_lfq_revenue",
	&"_lfq_gross_output",
	&"_delta_lfq_gross_output",
	&"_lfq_net_income",
	&"_delta_lfq_net_income",
	&"_constructions",
	&"_delta_constructions",
	&"_crews",
	&"_delta_crews",
	&"_rates",
	&"_delta_rates",
	&"_capacities",
	&"_delta_capacities",
	&"_est_revenues",
	&"_delta_est_revenues",
	&"_est_gross_incomes",
	&"_delta_est_gross_incomes",
	&"_est_gross_margins",
	&"_op_logics",
	&"_op_commands",
	
	&"_has_financials",
	&"_is_facility",
	
	&"_dirty_crew",
	&"_dirty_capacities_1",
	&"_dirty_capacities_2",
	&"_dirty_rates_1",
	&"_dirty_rates_2",
	&"_dirty_est_revenues_1",
	&"_dirty_est_revenues_2",
	&"_dirty_est_gross_incomes_1",
	&"_dirty_est_gross_incomes_2",
	&"_dirty_est_gross_margins_1",
	&"_dirty_est_gross_margins_2",
	&"_dirty_op_logics_1",
	&"_dirty_op_logics_2",
	&"_dirty_op_commands_1",
	&"_dirty_op_commands_2",
]

# Interface read-only! Data flows server -> interface.
var _lfq_revenue := 0.0 # last 4 quarters
var _delta_lfq_revenue := 0.0
var _lfq_gross_output := 0.0 # revenue w/ some exceptions; = "economy"
var _delta_lfq_gross_output := 0.0
var _lfq_net_income := 0.0
var _delta_lfq_net_income := 0.0
var _constructions := 0.0 # total mass of all _constructions
var _delta_constructions := 0.0

var _crews: Array[float] # indexed by population_type (can have crew w/out Population component)
var _delta_crews: Array[float]
var _rates: Array[float] # =mass_flow if has_mass_flow (?)
var _delta_rates: Array[float]
var _capacities: Array[float]
var _delta_capacities: Array[float]

# Facility, Player only (_has_financials = true)
var _est_revenues: Array[float] # per year at current rate & prices
var _delta_est_revenues: Array[float] # _has_financials
var _est_gross_incomes: Array[float] # per year at current prices
var _delta_est_gross_incomes: Array[float] # _has_financials

# Facility only
var _est_gross_margins: Array[float] # at current prices (even if rate = 0)
var _op_logics: Array[int] # enum; Facility only

# Facility only. '_op_commands' are AI or player settable from FacilityInterface.
# Use API! (Direct change will break!) Data flows Interface -> Server.
var _op_commands: Array[int] # enum; Facility only

# Operations data here
var _has_financials := false
var _is_facility := false


# server dirty data (dirty indexes as bit flags)
var _dirty_crews := 0 # max 64
var _dirty_capacities_1 := 0
var _dirty_capacities_2 := 0 # max 128
var _dirty_rates_1 := 0
var _dirty_rates_2 := 0 # max 128
var _dirty_est_revenues_1 := 0
var _dirty_est_revenues_2 := 0 # max 128
var _dirty_est_gross_incomes_1 := 0
var _dirty_est_gross_incomes_2 := 0 # max 128
var _dirty_est_gross_margins_1 := 0
var _dirty_est_gross_margins_2 := 0 # max 128
var _dirty_op_logics_1 := 0
var _dirty_op_logics_2 := 0 # max 128
var _dirty_op_commands_1 := 0
var _dirty_op_commands_2 := 0 # max 128

# localized indexing & table data
static var _table_operations: Dictionary
static var _n_operations: int
static var _op_groups_operations: Array[Array]
static var _is_class_instanced := false



func _init(is_new := false, has_financials := false, is_facility := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_table_operations = _tables[&"operations"]
		_n_operations = _table_n_rows[&"operations"]
		_op_groups_operations = tables_aux[&"op_groups_operations"]
	if !is_new: # game load
		return
	_has_financials = has_financials
	_is_facility = is_facility
	var n_populations: int = _table_n_rows[&"populations"]
	_crews = ivutils.init_array(n_populations, 0.0, TYPE_FLOAT)
	_delta_crews = _crews.duplicate()
	_rates = ivutils.init_array(_n_operations, 0.0, TYPE_FLOAT)
	_delta_rates = _rates.duplicate()
	_capacities = _rates.duplicate()
	_delta_capacities = _rates.duplicate()
	if !has_financials:
		return
	_est_revenues = _rates.duplicate()
	_delta_est_revenues = _rates.duplicate()
	_est_gross_incomes = _rates.duplicate()
	_delta_est_gross_incomes = _rates.duplicate()
	if !is_facility:
		return
	_est_gross_margins = ivutils.init_array(_n_operations, NAN, TYPE_FLOAT)
	_op_logics = ivutils.init_array(_n_operations, OpLogics.IS_IDLE_UNPROFITABLE, TYPE_INT)
	_op_commands = ivutils.init_array(_n_operations, OpCommands.AUTOMATE, TYPE_INT)


# ********************************** READ *************************************
# all threadsafe


func get_lfq_gross_output() -> float:
	return _lfq_gross_output + _delta_lfq_gross_output


func get_constructions() -> float:
	return _constructions + _delta_constructions


func get_crew(population_type := -1) -> float:
	if population_type == -1:
		return utils.get_float_array_sum(_crews) + utils.get_float_array_sum(_delta_crews)
	return _crews[population_type] + _delta_crews[population_type]


func get_rate(type: int) -> float:
	return _rates[type] + _delta_rates[type]


func get_capacity(type: int) -> float:
	return _capacities[type] + _delta_capacities[type]


func get_est_revenue(type: int) -> float:
	if !_has_financials:
		return NAN
	return _est_revenues[type] + _delta_est_revenues[type]


func get_est_gross_income(type: int) -> float:
	if !_has_financials:
		return NAN
	return _est_gross_incomes[type] + _delta_est_gross_incomes[type]


func get_est_gross_margin(type: int) -> float:
	if !_has_financials:
		return NAN
	if _is_facility: # facilities (only) have margin even if revenue = 0
		return _est_gross_margins[type]
	var est_revenue := _est_revenues[type] + _delta_est_revenues[type]
	if est_revenue == 0.0:
		return NAN
	return (_est_gross_incomes[type] + _delta_est_gross_incomes[type]) / est_revenue


func get_utilization(type: int) -> float:
	var capacity := _capacities[type] + _delta_capacities[type]
	if !capacity:
		return 0.0
	return (_rates[type] + _delta_rates[type]) / capacity


func get_electricity(type: int) -> float:
	return get_rate(type) * _table_operations[&"electricity"][type]


func get_total_electricity() -> float:
	var operation_electricities: Array[float] = _table_operations[&"electricity"]
	var sum := 0.0
	var i := 0
	while i < _n_operations:
		sum += get_rate(i) * operation_electricities[i]
		i += 1
	return sum


func get_development_energy() -> float:
	var dev_energies: Array[float] = _table_operations[&"dev_energy"]
	var sum := 0.0
	var i := 0
	while i < _n_operations:
		sum += get_rate(i) * dev_energies[i]
		i += 1
	return sum


func get_gui_flow(type: int) -> float:
	return get_rate(type) * _table_operations[&"gui_flow"][type]


func get_fuel_burn(type: int) -> float:
	return get_rate(type) * _table_operations[&"fuel_burn"][type]


func get_extraction_rate(type: int) -> float:
	return get_rate(type) * _table_operations[&"extraction_rate"][type]


func get_mass_flow(type: int) -> float:
	return get_rate(type) * _table_operations[&"mass_flow"][type]


func get_development_manufacturing() -> float:
	var mass_flows: Array[float] = _table_operations[&"mass_flow"]
	var sum := 0.0
	for type: int in tables_aux[&"is_manufacturing_operations"]:
		sum += get_rate(type) * mass_flows[type]
	return sum


func get_n_operations_in_same_group(type: int) -> int:
	var op_group: int = _table_operations[&"op_group"][type]
	var op_group_ops: Array[int] = _op_groups_operations[op_group]
	return op_group_ops.size()


func is_singular(type: int) -> bool:
	var op_group: int = _table_operations[&"op_group"][type]
	var op_group_ops: Array[int] = _op_groups_operations[op_group]
	return op_group_ops.size() == 1


func get_n_operations_in_group(op_group: int) -> int:
	var op_group_ops: Array[int] = _op_groups_operations[op_group]
	return op_group_ops.size()


func get_group_utilization(op_group: int) -> float:
	var op_group_ops: Array[int] = _op_groups_operations[op_group]
	var sum_capacities := 0.0
	for type in op_group_ops:
		sum_capacities += get_capacity(type)
	if sum_capacities == 0.0:
		return 0.0
	var sum_rates := 0.0
	for type in op_group_ops:
		sum_rates += get_rate(type)
	return sum_rates / sum_capacities


func get_group_electricity(op_group: int) -> float:
	var electricities: Array[float] = _table_operations[&"dev_energy"]
	var op_group_ops: Array[int] = _op_groups_operations[op_group]
	var sum := 0.0
	for type in op_group_ops:
		sum += get_rate(type) * electricities[type]
	return sum


func get_group_est_revenue(op_group: int) -> float:
	if !_has_financials:
		return NAN
	var op_group_ops: Array[int] = _op_groups_operations[op_group]
	var sum := 0.0
	for type in op_group_ops:
		sum += _est_revenues[type]
	return sum


func get_group_est_gross_income(op_group: int) -> float:
	if !_has_financials:
		return NAN
	var op_group_ops: Array[int] = _op_groups_operations[op_group]
	var sum := 0.0
	for type in op_group_ops:
		sum += get_est_gross_income(type)
	return sum


func get_group_est_gross_margin(op_group: int) -> float:
	if !_has_financials:
		return NAN
	var op_group_ops: Array[int] = _op_groups_operations[op_group]
	var sum_income := 0.0
	var sum_revenue := 0.0
	for type in op_group_ops:
		sum_income += get_est_gross_income(type)
		sum_revenue += get_est_revenue(type)
	if sum_revenue == 0.0:
		return NAN
	return sum_income / sum_revenue


# **************************** INTERFACE MODIFY *******************************

func set_op_command(type: int, command: int) -> void:
	assert(command < OpCommands.N_OP_COMMANDS)
	if _op_commands[type] == command:
		return
	_op_commands[type] = command
	if type < 64:
		_dirty_op_commands_1 |= 1 << type
	else:
		_dirty_op_commands_2 |= 1 << (type - 64)


# ****************************** SERVER MODIFY ********************************


func change_crew(population_type: int, change: float) -> void:
	assert(population_type >= 0)
	assert(!is_nan(change))
	assert(change >= 0.0 or change + get_crew(population_type) >= 0.0)
	if !change:
		return
	_delta_crews[population_type] += change
	_dirty_crews |= 1 << population_type


func set_crew(population_type: int, value: float) -> void:
	change_crew(population_type, value - get_crew(population_type))


func change_rate(type: int, change: float) -> void:
	assert(!is_nan(change))
	assert(change >= 0.0 or change + get_rate(type) >= 0.0)
	assert(change + get_rate(type) <= get_capacity(type))
	if !change:
		return
	_delta_rates[type] += change
	if type < 64:
		_dirty_rates_1 |= 1 << type
	else:
		_dirty_rates_2 |= 1 << (type - 64)


func set_rate(type: int, value: float) -> void:
	change_rate(type, value - get_rate(type))


func change_capacity(type: int, change: float, keep_utilization := true) -> void:
	# WARNING: Aggregate minus and plus effects before calling.
	assert(!is_nan(change))
	assert(change >= 0.0 or change + get_capacity(type) >= 0.0)
	if !change:
		return
	if keep_utilization:
		var utilization := get_utilization(type)
		_delta_capacities[type] += change
		set_rate(type, utilization * get_capacity(type))
	else:
		_delta_capacities[type] += change
		var capacity := get_capacity(type)
		if capacity < get_rate(type):
			set_rate(type, capacity)
	if type < 64:
		_dirty_capacities_1 |= 1 << type
	else:
		_dirty_capacities_2 |= 1 << (type - 64)


func set_capacity(type: int, value: float, keep_utilization := true) -> void:
	change_capacity(type, value - get_capacity(type), keep_utilization)


func change_est_revenue(type: int, change: float) -> void:
	assert(_has_financials)
	assert(!is_nan(change))
	assert(change >= 0.0 or change + get_est_revenue(type) >= 0.0)
	if !change:
		return
	_delta_est_revenues[type] += change
	if type < 64:
		_dirty_est_revenues_1 |= 1 << type
	else:
		_dirty_est_revenues_2 |= 1 << (type - 64)


func set_est_revenue(type: int, value: float) -> void:
	change_est_revenue(type, value - get_est_revenue(type))


func change_est_gross_income(type: int, change: float) -> void:
	assert(_has_financials)
	assert(!is_nan(change))
	assert(change >= 0.0 or change + get_est_gross_income(type) >= 0.0)
	if !change:
		return
	_delta_est_gross_incomes[type] += change
	if type < 64:
		_dirty_est_gross_incomes_1 |= 1 << type
	else:
		_dirty_est_gross_incomes_2 |= 1 << (type - 64)


func set_est_gross_income(type: int, value: float) -> void:
	change_est_gross_income(type, value - get_est_gross_income(type))


func set_est_gross_margin(type: int, value: float) -> void:
	# NAN ok
	assert(_is_facility)
	if value == _est_gross_margins[type]:
		return
	if is_nan(value) and is_nan(_est_gross_margins[type]):
		return
	_est_gross_margins[type] = value
	if type < 64:
		_dirty_est_gross_margins_1 |= 1 << type
	else:
		_dirty_est_gross_margins_2 |= 1 << (type - 64)



# ********************************** SYNC *************************************

func take_dirty(data: Array) -> void:
	# save delta in data, apply & zero delta, reset dirty flags
	
	_int_data = data[1]
	_float_data = data[2]
	
	_int_data.append(_dirty)
	if _dirty & DIRTY_LFQ_REVENUE:
		_float_data.append(_delta_lfq_revenue)
		_lfq_revenue += _delta_lfq_revenue
		_delta_lfq_revenue = 0.0
	if _dirty & DIRTY_LFQ_GROSS_OUTPUT:
		_float_data.append(_delta_lfq_gross_output)
		_lfq_gross_output += _delta_lfq_gross_output
		_delta_lfq_gross_output = 0.0
	if _dirty & DIRTY_LFQ_NET_INCOME:
		_float_data.append(_delta_lfq_net_income)
		_lfq_net_income += _delta_lfq_net_income
		_delta_lfq_net_income = 0.0
	if _dirty & DIRTY_CONSTRUCTIONS:
		_float_data.append(_delta_constructions)
		_constructions += _delta_constructions
		_delta_constructions = 0.0
	
	_take_floats_delta(_crews, _delta_crews, _dirty_crews)
	_take_floats_delta(_rates, _delta_rates, _dirty_rates_1)
	_take_floats_delta(_rates, _delta_rates, _dirty_rates_2, 64)
	_take_floats_delta(_capacities, _delta_capacities, _dirty_capacities_1)
	_take_floats_delta(_capacities, _delta_capacities, _dirty_capacities_2, 64)
	
	_dirty = 0
	_dirty_crews = 0
	_dirty_rates_1 = 0
	_dirty_rates_2 = 0
	_dirty_capacities_1 = 0
	_dirty_capacities_2 = 0
	
	if !_has_financials:
		return
	
	_take_floats_delta(_est_revenues, _delta_est_revenues, _dirty_est_revenues_1)
	_take_floats_delta(_est_revenues, _delta_est_revenues, _dirty_est_revenues_2, 64)
	_take_floats_delta(_est_gross_incomes, _delta_est_gross_incomes, _dirty_est_gross_incomes_1)
	_take_floats_delta(_est_gross_incomes, _delta_est_gross_incomes, _dirty_est_gross_incomes_2, 64)
	
	_dirty_est_revenues_1 = 0
	_dirty_est_revenues_2 = 0
	_dirty_est_gross_incomes_1 = 0
	_dirty_est_gross_incomes_2 = 0
	
	if !_is_facility:
		return
	
	_get_floats_dirty(_est_gross_margins, _dirty_est_gross_margins_1) # not accumulator!
	_get_floats_dirty(_est_gross_margins, _dirty_est_gross_margins_2, 64) # not accumulator!
	_get_ints_dirty(_op_logics, _dirty_op_logics_1) # not accumulator!
	_get_ints_dirty(_op_logics, _dirty_op_logics_2, 64) # not accumulator!
	
	_dirty_est_gross_margins_1 = 0
	_dirty_est_gross_margins_2 = 0
	_dirty_op_logics_1 = 0
	_dirty_op_logics_2 = 0


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# apply delta & dirty flags
	_int_data = data[1]
	_float_data = data[2]
	_int_offset = int_offset
	_float_offset = float_offset
	
	var svr_qtr := _int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	var dirty := _int_data[_int_offset]
	_int_offset += 1
	_dirty |= dirty
	if dirty & DIRTY_LFQ_REVENUE:
		_delta_lfq_revenue += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_LFQ_GROSS_OUTPUT:
		_delta_lfq_gross_output += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_LFQ_NET_INCOME:
		_delta_lfq_net_income += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_CONSTRUCTIONS:
		_delta_constructions += _float_data[_float_offset]
		_float_offset += 1
	
	_dirty_crews |= _add_floats_delta(_delta_crews)
	_dirty_rates_1 |= _add_floats_delta(_delta_rates)
	_dirty_rates_2 |= _add_floats_delta(_delta_rates, 64)
	_dirty_capacities_1 |= _add_floats_delta(_delta_capacities)
	_dirty_capacities_2 |= _add_floats_delta(_delta_capacities, 64)
	
	if !_has_financials:
		return
	
	_dirty_est_revenues_1 |= _add_floats_delta(_delta_est_revenues)
	_dirty_est_revenues_2 |= _add_floats_delta(_delta_est_revenues, 64)
	_dirty_est_gross_incomes_1 |= _add_floats_delta(_delta_est_gross_incomes)
	_dirty_est_gross_incomes_2 |= _add_floats_delta(_delta_est_gross_incomes, 64)

	if !_is_facility:
		return
	
	_dirty_est_gross_margins_1 |= _set_floats_dirty(_est_gross_margins) # not accumulator!
	_dirty_est_gross_margins_2 |= _set_floats_dirty(_est_gross_margins, 64) # not accumulator!
	_dirty_op_logics_1 |= _set_ints_dirty(_op_logics) # not accumulator!
	_dirty_op_logics_2 |= _set_ints_dirty(_op_logics, 64) # not accumulator!


func get_interface_dirty() -> Array:
	# TODO: parallel pattern above to get FacilityInterface data
	var data := []
	#_append_dirty(data, _op_commands, _dirty_op_commands_1)
	#_append_dirty(data, _op_commands, _dirty_op_commands_2, 64)
	#_dirty_op_commands_1 = 0
	#_dirty_op_commands_2 = 0
	return data


func sync_interface_dirty(_data: Array) -> void:
	# TODO: parallel pattern above to set FacilityInterface data
	pass
	#_set_dirty(data, _op_commands)
	#_set_dirty(data, _op_commands, 64)

