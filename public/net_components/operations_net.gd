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

const PROCESS_GROUP_RENEWABLE := Enums.ProcessGroup.PROCESS_GROUP_RENEWABLE
const PROCESS_GROUP_CONV_POWER := Enums.ProcessGroup.PROCESS_GROUP_CONV_POWER
const PROCESS_GROUP_CONVERSION := Enums.ProcessGroup.PROCESS_GROUP_CONVERSION
const PROCESS_GROUP_EXTRACTION := Enums.ProcessGroup.PROCESS_GROUP_EXTRACTION

# Interface read-only! Data flows server -> interface.
var _lfq_revenue := 0.0 # last 4 quarters
var _lfq_gross_output := 0.0 # revenue w/ some exceptions; = "economy"
var _lfq_net_income := 0.0
var _constructions := 0.0 # total mass of all _constructions

var _crews: Array[float] # indexed by population_type (can have crew w/out Population component)
var _capacities: Array[float] # set by facility modules
var _run_rates: Array[float] # <= capacities; defines operation utilization
var _effective_rates: Array[float] # almost always <= run_rates

# Facility, Player only (_has_financials = true)
var _est_revenues: Array[float] # per year at current rate & prices
var _est_gross_incomes: Array[float] # per year at current prices

# Facility only
var _est_gross_margins: Array[float] # at current prices (even if rate = 0)
var _op_logics: Array[int] # enum; Facility only

# Facility only. '_op_commands' are AI or player settable from FacilityInterface.
# Use API! (Direct change will break!) Data flows Interface -> Server.
var _op_commands: Array[int] # enum; Facility only
var _target_utilizations: Array[float]

# Operations data here
var _has_financials := false
var _is_facility := false

# interface dirty data (dirty indexes as bit flags)
var _dirty_op_commands_1 := 0
var _dirty_op_commands_2 := 0 # max 128

# localized indexing & table data
static var _table_operations: Dictionary
static var _n_operations: int
static var _operation_electricities: Array[float]
static var _operation_process_groups: Array[int]
static var _op_groups_operations: Array[Array]
static var _is_class_instanced := false


func _init(is_new := false, has_financials := false, is_facility := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_table_operations = _tables[&"operations"]
		_n_operations = _table_n_rows[&"operations"]
		_operation_electricities = _table_operations[&"electricity"]
		_operation_process_groups = _table_operations[&"process_group"]
		_op_groups_operations = tables_aux[&"op_groups_operations"]
	if !is_new: # game load
		return
	_has_financials = has_financials
	_is_facility = is_facility
	var n_populations: int = _table_n_rows[&"populations"]
	_crews = ivutils.init_array(n_populations, 0.0, TYPE_FLOAT)
	_capacities = ivutils.init_array(_n_operations, 0.0, TYPE_FLOAT)
	_run_rates = _capacities.duplicate()
	_effective_rates = _capacities.duplicate()
	if !has_financials:
		return
	_est_revenues = _capacities.duplicate()
	_est_gross_incomes = _capacities.duplicate()
	if !is_facility:
		return
	_est_gross_margins = ivutils.init_array(_n_operations, NAN, TYPE_FLOAT)
	_op_logics = ivutils.init_array(_n_operations, OpLogics.IS_IDLE_UNPROFITABLE, TYPE_INT)
	_op_commands = ivutils.init_array(_n_operations, OpCommands.AUTOMATE, TYPE_INT)
	_target_utilizations = ivutils.init_array(_n_operations, 1.0, TYPE_FLOAT)


# ********************************** READ *************************************
# all threadsafe


func get_lfq_gross_output() -> float:
	return _lfq_gross_output


func get_constructions() -> float:
	return _constructions


func get_crew(population_type := -1) -> float:
	if population_type == -1:
		return utils.get_float_array_sum(_crews)
	return _crews[population_type]


func get_run_rate(type: int) -> float:
	return _run_rates[type]


func get_effective_rate(type: int) -> float:
	return _effective_rates[type]


func get_capacity(type: int) -> float:
	return _capacities[type]


func get_est_revenue(type: int) -> float:
	if !_has_financials:
		return NAN
	return _est_revenues[type]


func get_est_gross_income(type: int) -> float:
	if !_has_financials:
		return NAN
	return _est_gross_incomes[type]


func get_est_gross_margin(type: int) -> float:
	if !_has_financials:
		return NAN
	if _is_facility: # facilities (only) have margin even if revenue = 0
		return _est_gross_margins[type]
	var est_revenue := _est_revenues[type]
	if est_revenue == 0.0:
		return NAN
	return _est_gross_incomes[type] / est_revenue


func get_utilization(type: int) -> float:
	var capacity := _capacities[type]
	if !capacity:
		return 0.0
	return _run_rates[type] / capacity


func get_electricity(type: int) -> float:
	# Negative for power consumers.
	var operation_electricity := _operation_electricities[type]
	if operation_electricity > 0.0: # power generating
		return get_effective_rate(type) * operation_electricity
	return get_run_rate(type) * operation_electricity


func get_development_energy() -> float:
	# For now, we just sum power generation. TODO: Handle solar foundries, etc.
	var sum := 0.0
	for type in _n_operations:
		var electricity := get_electricity(type)
		if electricity > 0.0:
			sum += electricity
	return sum


func get_extraction_rate(type: int) -> float:
	return get_run_rate(type) * _table_operations[&"extraction_rate"][type]


func get_gui_flow(type: int) -> float:
	return get_run_rate(type) * _table_operations[&"gui_flow"][type]


func get_fuel_burn(type: int) -> float:
	return get_run_rate(type) * _table_operations[&"fuel_burn"][type]



func get_mass_flow(type: int) -> float:
	return get_run_rate(type) * _table_operations[&"mass_flow"][type]


func get_development_manufacturing() -> float:
	var mass_flows: Array[float] = _table_operations[&"mass_flow"]
	var sum := 0.0
	for type: int in tables_aux[&"is_manufacturing_operations"]:
		sum += get_run_rate(type) * mass_flows[type]
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
		sum_rates += get_run_rate(type)
	return sum_rates / sum_capacities


func get_group_electricity(op_group: int) -> float:
	var sum := 0.0
	for type: int in _op_groups_operations[op_group]:
		sum += get_electricity(type)
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


func get_target_utilization(type: int) -> float:
	return _target_utilizations[type]


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

# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_lfq_revenue = data[1]
	_lfq_gross_output = data[2]
	_lfq_net_income = data[3]
	_constructions = data[4]
	_crews = data[5]
	_capacities = data[6]
	_run_rates = data[7]
	_effective_rates = data[8]
	_est_revenues = data[9]
	_est_gross_incomes = data[10]
	_est_gross_margins = data[11]
	_op_logics = data[12]
	_op_commands = data[13]
	_target_utilizations = data[14]
	_has_financials = data[15]
	_is_facility = data[16]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# apply deltas and sets
	_int_data = data[1]
	_float_data = data[2]
	_int_offset = int_offset
	_float_offset = float_offset
	
	var svr_qtr := _int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	var dirty := _int_data[_int_offset]
	_int_offset += 1
	if dirty & DIRTY_LFQ_REVENUE:
		_lfq_revenue += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_LFQ_GROSS_OUTPUT:
		_lfq_gross_output += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_LFQ_NET_INCOME:
		_lfq_net_income += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_CONSTRUCTIONS:
		_constructions += _float_data[_float_offset]
		_float_offset += 1
	
	_add_floats_delta(_crews)
	_add_floats_delta(_capacities)
	_add_floats_delta(_capacities, 64)
	_add_floats_delta(_run_rates)
	_add_floats_delta(_run_rates, 64)
	_add_floats_delta(_effective_rates)
	_add_floats_delta(_effective_rates, 64)
	
	if !_has_financials:
		return
	
	_add_floats_delta(_est_revenues)
	_add_floats_delta(_est_revenues, 64)
	_add_floats_delta(_est_gross_incomes)
	_add_floats_delta(_est_gross_incomes, 64)

	if !_is_facility:
		return
	
	_set_floats_dirty(_est_gross_margins) # not accumulator!
	_set_floats_dirty(_est_gross_margins, 64) # not accumulator!
	_set_ints_dirty(_op_logics) # not accumulator!
	_set_ints_dirty(_op_logics, 64) # not accumulator!


func get_interface_dirty() -> Array:
	# TODO: parallel server pattern
	var data := []
	#_append_dirty(data, _op_commands, _dirty_op_commands_1)
	#_append_dirty(data, _op_commands, _dirty_op_commands_2, 64)
	#_dirty_op_commands_1 = 0
	#_dirty_op_commands_2 = 0
	return data


