# operations.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name Operations
extends NetRef

# Arrays indexed by operation_type, except where noted.
#
# 'public_capacities' and 'est_' financials are Facility & Player only.
# 'op_logics' and 'op_commands' are Facility only.
# All vars are Interface read-only except for 'op_commands', which has the only
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

# save/load persistence for server only
const PERSIST_PROPERTIES2: Array[StringName] = [
	&"lfq_revenue",
	&"lfq_gross_output",
	&"lfq_net_income",
	&"constructions",
	&"crews",
	&"capacities",
	&"rates",
	&"public_capacities",
	&"est_revenues",
	&"est_gross_incomes",
	&"est_gross_margins",
	&"op_logics",
	&"op_commands",
	
	&"has_financials",
	&"is_facility",
	
	&"_dirty_crew",
	&"_dirty_capacities_1",
	&"_dirty_capacities_2",
	&"_dirty_rates_1",
	&"_dirty_rates_2",
	&"_dirty_public_capacities_1",
	&"_dirty_public_capacities_2",
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
var lfq_revenue := 0.0 # last 4 quarters
var lfq_gross_output := 0.0 # revenue w/ some exceptions; = "economy"
var lfq_net_income := 0.0
var constructions := 0.0 # total mass of all constructions

var crews: Array[float] # indexed by population_type (can have crew w/out Population component)

var capacities: Array[float]
var rates: Array[float] # =mass_flow if has_mass_flow (?)

# Facility, Player only (has_financials = true)
var public_capacities: Array[float] # =capacities if public sector, 0.0 if private sector
var est_revenues: Array[float] # per year at current rate & prices
var est_gross_incomes: Array[float] # per year at current prices


# Facility only
var est_gross_margins: Array[float] # at current prices (even if rate = 0)
var op_logics: Array[int] # enum; Facility only

# Facility only. 'op_commands' are AI or player settable from FacilityInterface.
# Use API! (Direct change will break!) Data flows Interface -> Server.
var op_commands: Array[int] # enum; Facility only


var has_financials := false
var is_facility := false

# server dirty data (dirty indexes as bit flags)
var _dirty_crews := 0 # max 64
var _dirty_capacities_1 := 0
var _dirty_capacities_2 := 0 # max 128
var _dirty_rates_1 := 0
var _dirty_rates_2 := 0 # max 128
var _dirty_public_capacities_1 := 0
var _dirty_public_capacities_2 := 0 # max 128
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



func _init(is_new := false, has_financials_ := false, is_facility_ := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_table_operations = _tables[&"operations"]
		_n_operations = _table_n_rows[&"operations"]
		_op_groups_operations = _tables[&"op_groups_operations"]
	if !is_new: # game load
		return
	has_financials = has_financials_
	is_facility = is_facility_
	var n_populations: int = _table_n_rows[&"populations"]
	crews = ivutils.init_array(n_populations, 0.0, TYPE_FLOAT)
	capacities = ivutils.init_array(_n_operations, 0.0, TYPE_FLOAT)
	rates = capacities.duplicate()
	if !has_financials_:
		return
	public_capacities  = capacities.duplicate()
	est_revenues = capacities.duplicate()
	est_gross_incomes = capacities.duplicate()
	if !is_facility_:
		return
	est_gross_margins = ivutils.init_array(_n_operations, NAN, TYPE_FLOAT)
	op_logics = ivutils.init_array(_n_operations, OpLogics.IS_IDLE_UNPROFITABLE, TYPE_INT)
	op_commands = ivutils.init_array(_n_operations, OpCommands.AUTOMATE, TYPE_INT)


# ********************************** READ *************************************
# all threadsafe


func get_crew(population_type: int) -> float:
	return crews[population_type]


func get_crew_total() -> float:
	return utils.get_float_array_sum(crews)


func get_capacity(type: int) -> float:
	return capacities[type]


func get_public_portion(type: int) -> float:
	# always 0.0 - 1.0
	if capacities[type] == 0.0:
		return 0.0
	return public_capacities[type] / capacities[type]


func get_utilization(type: int) -> float:
	if capacities[type] == 0.0:
		return 0.0
	return rates[type] / capacities[type]


func get_electricity(type: int) -> float:
	return rates[type] * _table_operations[&"electricity"][type]


func get_total_electricity() -> float:
	var operation_electricities: Array = _table_operations[&"electricity"]
	var sum := 0.0
	var i := 0
	while i < _n_operations:
		sum += rates[i] * operation_electricities[i]
		i += 1
	return sum


func get_energy(type: int) -> float:
	return rates[type] * _table_operations[&"energy"][type]


func get_total_energy() -> float:
	var operation_energies: Array = _table_operations[&"energy"]
	var sum := 0.0
	var i := 0
	while i < _n_operations:
		sum += rates[i] * operation_energies[i]
		i += 1
	return sum


func get_gui_flow(type: int) -> float:
	return rates[type] * _table_operations.gui_flow[type]


func get_fuel_burn(type: int) -> float:
	return rates[type] * _table_operations.fuel_burn[type]


func get_extraction_rate(type: int) -> float:
	return rates[type] * _table_operations.extraction_rate[type]


func get_mass_flow(type: int) -> float:
	return rates[type] * _table_operations.mass_flow[type]


func get_total_manufacturing() -> float:
	var mass_flows: Array = _table_operations.mass_flow
	var sum := 0.0
	for type in _tables.is_manufacturing_operations:
		sum += rates[type] * mass_flows[type]
	return sum


func get_est_revenue(type: int) -> float:
	if !has_financials:
		return NAN
	return est_revenues[type]


func get_est_gross_income(type: int) -> float:
	if !has_financials:
		return NAN
	return est_gross_incomes[type]


func get_est_gross_margin(type: int) -> float:
	if !has_financials:
		return NAN
	if is_facility: # facilities (only) have margin even if revenue = 0
		return est_gross_margins[type]
	if est_revenues[type] == 0.0:
		return NAN
	return est_gross_incomes[type] / est_revenues[type]


func get_n_operations_in_same_group(type: int) -> int:
	var op_group: int = _table_operations.op_group[type]
	var op_group_ops: Array = _op_groups_operations[op_group]
	return op_group_ops.size()


func is_singular(type: int) -> bool:
	var op_group: int = _table_operations.op_group[type]
	var op_group_ops: Array = _op_groups_operations[op_group]
	return op_group_ops.size() == 1


func get_n_operations_in_group(op_group: int) -> int:
	var op_group_ops: Array = _op_groups_operations[op_group]
	return op_group_ops.size()


func get_group_utilization(op_group: int) -> float:
	var sum_capacities := 0.0
	for type in _op_groups_operations[op_group]:
		sum_capacities += capacities[type]
	if sum_capacities == 0.0:
		return 0.0
	var sum_rates := 0.0
	for type in _op_groups_operations[op_group]:
		sum_rates += rates[type]
	return sum_rates / sum_capacities


func get_group_energy(op_group: int) -> float:
	var energies: Array = _table_operations[&"energy"]
	var sum := 0.0
	for type in _op_groups_operations[op_group]:
		sum += rates[type] * energies[type]
	return sum


func get_group_gui_flow(op_group: int) -> float:
	var gui_flows: Array = _table_operations.gui_flow
	var sum := 0.0
	for type in _op_groups_operations[op_group]:
		sum += rates[type] * gui_flows[type]
	return sum


func get_group_est_revenue(op_group: int) -> float:
	if !has_financials:
		return NAN
	var sum := 0.0
	for type in _op_groups_operations[op_group]:
		sum += est_revenues[type]
	return sum


func get_group_est_gross_income(op_group: int) -> float:
	if !has_financials:
		return NAN
	var sum := 0.0
	for type in _op_groups_operations[op_group]:
		sum += est_gross_incomes[type]
	return sum


func get_group_est_gross_margin(op_group: int) -> float:
	if !has_financials:
		return NAN
	var sum_income := 0.0
	var sum_revenue := 0.0
	for type in _op_groups_operations[op_group]:
		sum_income += est_gross_incomes[type]
		sum_revenue += est_revenues[type]
	if sum_revenue == 0.0:
		return NAN
	return sum_income / sum_revenue


# **************************** INTERFACE MODIFY *******************************

func set_op_command(type: int, command: int) -> void:
	assert(command < OpCommands.N_OP_COMMANDS)
	if op_commands[type] == command:
		return
	op_commands[type] = command
	if type < 64:
		_dirty_op_commands_1 |= 1 << type
	else:
		_dirty_op_commands_2 |= 1 << (type - 64)


# ****************************** SERVER MODIFY ********************************


func change_crew(population_type: int, change: float) -> void:
	crews[population_type] += change
	_dirty_crews |= 1 << population_type


func change_capacity(type: int, change: float) -> void:
	capacities[type] += change
	if type < 64:
		_dirty_capacities_1 |= 1 << type
	else:
		_dirty_capacities_2 |= 1 << (type - 64)


func change_rate(type: int, change: float) -> void:
	rates[type] += change
	if type < 64:
		_dirty_rates_1 |= 1 << type
	else:
		_dirty_rates_2 |= 1 << (type - 64)


func change_public_capacity(type: int, change: float) -> void:
	public_capacities[type] += change
	if type < 64:
		_dirty_public_capacities_1 |= 1 << type
	else:
		_dirty_public_capacities_2 |= 1 << (type - 64)


func change_est_revenue(type: int, change: float) -> void:
	est_revenues[type] += change
	if type < 64:
		_dirty_est_revenues_1 |= 1 << type
	else:
		_dirty_est_revenues_2 |= 1 << (type - 64)


func change_est_gross_income(type: int, change: float) -> void:
	est_gross_incomes[type] += change
	if type < 64:
		_dirty_est_gross_incomes_1 |= 1 << type
	else:
		_dirty_est_gross_incomes_2 |= 1 << (type - 64)


func set_est_gross_margin(type: int, value: float) -> void:
	est_gross_margins[type] = value
	if type < 64:
		_dirty_est_gross_margins_1 |= 1 << type
	else:
		_dirty_est_gross_margins_2 |= 1 << (type - 64)


func get_dirty_capacities_1() -> int:
	return _dirty_capacities_1


func get_dirty_capacities_2() -> int:
	return _dirty_capacities_2


# ********************************** SYNC *************************************

func take_server_delta(data: Array) -> void:
	# facility accumulator only; zero accumulators and dirty flags
	
	_int_data = data[0]
	_float_data = data[1]
	
	_int_data[2] = _int_data.size()
	_int_data[3] = _float_data.size()
	
	_int_data.append(_dirty)
	if _dirty & DIRTY_LFQ_REVENUE:
		_float_data.append(lfq_revenue)
		lfq_revenue = 0.0
	if _dirty & DIRTY_LFQ_GROSS_OUTPUT:
		_float_data.append(lfq_gross_output)
		lfq_gross_output = 0.0
	if _dirty & DIRTY_LFQ_NET_INCOME:
		_float_data.append(lfq_net_income)
		lfq_net_income = 0.0
	if _dirty & DIRTY_CONSTRUCTIONS:
		_float_data.append(constructions)
		constructions = 0.0
	_dirty = 0
	
	_append_and_zero_dirty_floats(crews, _dirty_crews)
	_dirty_crews = 0
	_append_and_zero_dirty_floats(capacities, _dirty_capacities_1)
	_dirty_capacities_1 = 0
	_append_and_zero_dirty_floats(capacities, _dirty_capacities_2, 64)
	_dirty_capacities_2 = 0
	_append_and_zero_dirty_floats(rates, _dirty_rates_1)
	_dirty_rates_1 = 0
	_append_and_zero_dirty_floats(rates, _dirty_rates_2, 64)
	_dirty_rates_2 = 0
	_append_and_zero_dirty_floats(public_capacities, _dirty_public_capacities_1)
	_dirty_public_capacities_1 = 0
	_append_and_zero_dirty_floats(public_capacities, _dirty_public_capacities_2, 64)
	_dirty_public_capacities_2 = 0
	_append_and_zero_dirty_floats(est_revenues, _dirty_est_revenues_1)
	_dirty_est_revenues_1 = 0
	_append_and_zero_dirty_floats(est_revenues, _dirty_est_revenues_2, 64)
	_dirty_est_revenues_2 = 0
	_append_and_zero_dirty_floats(est_gross_incomes, _dirty_est_gross_incomes_1)
	_dirty_est_gross_incomes_1 = 0
	_append_and_zero_dirty_floats(est_gross_incomes, _dirty_est_gross_incomes_2, 64)
	_dirty_est_gross_incomes_2 = 0
	_append_dirty_floats(est_gross_margins, _dirty_est_gross_margins_1) # not accumulator!
	_dirty_est_gross_margins_1 = 0
	_append_dirty_floats(est_gross_margins, _dirty_est_gross_margins_2, 64) # not accumulator!
	_dirty_est_gross_margins_2 = 0
	_append_dirty_ints(op_logics, _dirty_op_logics_1) # not accumulator!
	_dirty_op_logics_1 = 0
	_append_dirty_ints(op_logics, _dirty_op_logics_2, 64) # not accumulator!
	_dirty_op_logics_2 = 0


func add_server_delta(data: Array) -> void:
	# any target
	
	_int_data = data[0]
	_float_data = data[1]
	
	_int_offset = _int_data[2]
	_float_offset = _int_data[3]
	
	var svr_qtr := _int_data[0]
	run_qtr = svr_qtr # TODO: histories
		
	var flags := _int_data[_int_offset]
	_int_offset += 1
	if flags & DIRTY_LFQ_REVENUE:
		lfq_revenue += _float_data[_float_offset]
		_float_offset += 1
	if flags & DIRTY_LFQ_GROSS_OUTPUT:
		lfq_gross_output += _float_data[_float_offset]
		_float_offset += 1
	if flags & DIRTY_LFQ_NET_INCOME:
		lfq_net_income += _float_data[_float_offset]
		_float_offset += 1
	if flags & DIRTY_CONSTRUCTIONS:
		constructions += _float_data[_float_offset]
		_float_offset += 1
	
	_add_dirty_floats(crews)
	_add_dirty_floats(capacities)
	_add_dirty_floats(capacities, 64)
	_add_dirty_floats(rates)
	_add_dirty_floats(rates, 64)
	if !has_financials:
		return
	_add_dirty_floats(public_capacities)
	_add_dirty_floats(public_capacities, 64)
	_add_dirty_floats(est_revenues)
	_add_dirty_floats(est_revenues, 64)
	_add_dirty_floats(est_gross_incomes)
	_add_dirty_floats(est_gross_incomes, 64)
	if !is_facility:
		return
	_set_dirty_floats(est_gross_margins) # not accumulator!
	_set_dirty_floats(est_gross_margins, 64) # not accumulator!
	_set_dirty_ints(op_logics) # not accumulator!
	_set_dirty_ints(op_logics, 64) # not accumulator!


func get_interface_dirty() -> Array:
	# TODO: parallel pattern above to get FacilityInterface data
	var data := []
	#_append_dirty(data, op_commands, _dirty_op_commands_1)
	#_append_dirty(data, op_commands, _dirty_op_commands_2, 64)
	#_dirty_op_commands_1 = 0
	#_dirty_op_commands_2 = 0
	return data


func sync_interface_dirty(_data: Array) -> void:
	# TODO: parallel pattern above to set FacilityInterface data
	pass
	#_set_dirty(data, op_commands)
	#_set_dirty(data, op_commands, 64)



# ******************************** PRIVATE ************************************


