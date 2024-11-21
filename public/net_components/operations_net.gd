# operations_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name OperationsNet
extends RefCounted

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

enum {
	DIRTY_GROSS_OUTPUT_LFQ = 1,
	DIRTY_BUILT_MASS = 1 << 1,
	DIRTY_NOMINAL_INFORMATION = 1 << 2,
	DIRTY_OPERATIONS_LIST = 1 << 3,
}

const ivutils := preload("res://addons/ivoyager_core/static/utils.gd")
const utils := preload("res://public/static/utils.gd")

const PROCESS_GROUP_RENEWABLE := Enums.ProcessGroup.PROCESS_GROUP_RENEWABLE
const PROCESS_GROUP_CONVERSION := Enums.ProcessGroup.PROCESS_GROUP_CONVERSION
const PROCESS_GROUP_EXTRACTION := Enums.ProcessGroup.PROCESS_GROUP_EXTRACTION

# Interface read-only! Data flows server -> interface.
var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)
var _gross_output_lfq := 0.0 # ='Economy'; set by Facility for propagation
var _built_mass := 0.0 # total mass of all things construced
var _nominal_information := 0.0 # only if we don't have Cyberspace here!

var _crews: Array[float] # indexed by population_type (can have crew w/out Population component)

var _capacities: Array[float] # set by facility modules
var _run_rates: Array[float] # <= capacities; defines operation utilization
var _effective_rates: Array[float] # almost always <= run_rates

# Facility, Player only (_has_financials = true)
var _revenue_rates: Array[float] # at current rate & prices
var _cogs_rates: Array[float] # cost of goods sold; at current rate & prices

# Facility only
var _gross_margins: Array[float] # at current prices (even if rate = 0)
var _op_logics: Array[int] # enum; Facility only

# Facility only. '_op_commands' are AI or player settable from FacilityInterface.
# Use API! (Direct change will break!) Data flows Interface -> Server.
var _op_commands: Array[int] # enum; Facility only
var _target_utilizations: Array[float]

# Operations data here
var _has_financials := false
var _is_facility := false
var _operations_list: Array[int] # facility only; all types we have or want for margin test

# interface dirty data (dirty indexes as bit flags)
var _dirty_op_commands_1 := 0
var _dirty_op_commands_2 := 0
var _dirty_op_commands_3 := 0 # max 192

var _sync := SyncHelper.new()

# localized indexing & table data
static var _tables: Dictionary = IVTableData.tables
static var _table_n_rows: Dictionary = IVTableData.table_n_rows
static var _tables_aux: Dictionary = ThreadsafeGlobal.tables_aux
static var _table_operations: Dictionary
static var _n_operations: int
static var _operation_electricities: Array[float]
static var _operation_process_groups: Array[int]
static var _op_group_operations: Array[Array]
static var _is_class_instanced := false


func _init(is_new := false, has_financials_ := false, is_facility_ := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_table_operations = _tables[&"operations"]
		_n_operations = _table_n_rows[&"operations"]
		_operation_electricities = _table_operations[&"electricity"]
		_operation_process_groups = _table_operations[&"process_group"]
		_op_group_operations = _tables_aux[&"op_groups_operations"]
	if !is_new: # game load
		return
	_has_financials = has_financials_
	_is_facility = is_facility_
	var n_populations: int = _table_n_rows[&"populations"]
	_crews = ivutils.init_array(n_populations, 0.0, TYPE_FLOAT)
	_capacities = ivutils.init_array(_n_operations, 0.0, TYPE_FLOAT)
	_run_rates = _capacities.duplicate()
	_effective_rates = _capacities.duplicate()
	if !_has_financials:
		return
	_revenue_rates = _capacities.duplicate()
	_cogs_rates = _capacities.duplicate()
	if !_is_facility:
		return
	_gross_margins = ivutils.init_array(_n_operations, NAN, TYPE_FLOAT)
	_op_logics = ivutils.init_array(_n_operations, OpLogics.IS_IDLE_UNPROFITABLE, TYPE_INT)
	_op_commands = ivutils.init_array(_n_operations, OpCommands.AUTOMATE, TYPE_INT)
	_target_utilizations = ivutils.init_array(_n_operations, 1.0, TYPE_FLOAT)


# ********************************** READ *************************************
# all threadsafe

# dev totals

func get_crew(population_type := -1) -> float:
	if population_type == -1:
		return utils.get_float_array_sum(_crews)
	return _crews[population_type]
	

func get_gross_output_lfq() -> float:
	return _gross_output_lfq


func get_energy_use() -> float:
	# Generation only for the development statistic.
	# For now, we just sum electricity generators. TODO: Handle solar foundries, etc.
	var sum := 0.0
	for type in _n_operations: # TODO: Optimize w/ subset
		sum += get_electricity_rate(type, true)
	return sum


func get_built_mass() -> float:
	return _built_mass


func get_nominal_information() -> float:
	return _nominal_information


func get_construction() -> float:
	# This is really manufacturing. Manufacturing includes production of
	# finished 'resources' and (in the future) will include in situ
	# contruction: i.e., a facility that is upgrading itself.
	var sum := 0.0
	for type in _n_operations: # TODO: Optimize w/ subset
		sum += get_manufacturing(type, true)
	return sum


func get_total_computation() -> float:
	var sum := 0.0
	for type in _n_operations: # TODO: Optimize w/ subset
		sum += get_computation(type, true)
	return sum


func get_nominal_biomass() -> float:
	# FIXME: Terrible ad hoc solution for dev stats now.
	return _crews[0] * 21.0 * IVUnits.KG # dry weight of a person ;)


# misc

func has_financials() -> bool:
	# True for Facilities & Players and Joins of these two only.
	return _has_financials


func is_facility() -> bool:
	return _is_facility


func get_facility_operations_of_interest() -> Array[int]:
	# Facility only. Facilities may have interest in operations they don't
	# have yet.
	return _operations_list


func get_operations_of_interest() -> Array[int]:
	# Facilities may have interest in operations they don't have yet. All
	# others return a list of operations for which they have capacity > 0.0.
	if _is_facility:
		return _operations_list
	var result: Array[int] = []
	for type in _n_operations:
		if _capacities[type]:
			result.append(type)
	return result


# operation-specific

func get_run_rate(type: int) -> float:
	return _run_rates[type]


func get_effective_rate(type: int) -> float:
	return _effective_rates[type]


func get_capacity(type: int) -> float:
	return _capacities[type]


func get_revenue_rate(type: int) -> float:
	if !_has_financials:
		return NAN
	return _revenue_rates[type]


func get_cogs_rate(type: int) -> float:
	if !_has_financials:
		return NAN
	return _cogs_rates[type]


func get_gross_margin(type: int) -> float:
	if !_has_financials:
		return NAN
	if _is_facility: # facilities (only) have margin even if revenue = 0
		return _gross_margins[type]
	var revenue := _revenue_rates[type]
	if revenue == 0.0:
		return NAN
	return (revenue - _cogs_rates[type]) / revenue


func get_utilization(type: int) -> float:
	var capacity := _capacities[type]
	if !capacity:
		return 0.0
	return _run_rates[type] / capacity


func get_target_utilization(type: int) -> float:
	return _target_utilizations[type]


func get_electricity_rate(type: int, positive_only := false) -> float:
	# +/- for power generators/consumers.
	var operation_electricity := _operation_electricities[type]
	if operation_electricity > 0.0:
		return get_effective_rate(type) * operation_electricity # generator
	if positive_only:
		return 0.0
	return get_run_rate(type) * operation_electricity # consumer


func get_extraction_rate(type: int) -> float:
	return get_effective_rate(type) * _table_operations[&"extraction_multiplier"][type]


func get_mass_conversion_rate(type: int) -> float:
	if _operation_electricities[type] > 0.0:
		return get_run_rate(type) * _table_operations[&"mass_conversion"][type] # power generator
	return get_effective_rate(type) * _table_operations[&"mass_conversion"][type] # power consumer


func get_fuel_rate(type: int) -> float:
	if _operation_electricities[type] > 0.0:
		return get_run_rate(type) * _table_operations[&"fuel_rate"][type] # power generator
	return NAN


func get_manufacturing(type: int, positive_only := false) -> float:
	var base_manufacturing: float = _table_operations[&"manufacturing"][type]
	if base_manufacturing > 0.0:
		return get_effective_rate(type) * base_manufacturing # manufacturer
	if positive_only:
		return 0.0
	return NAN


func get_computation(type: int, positive_only := false) -> float:
	var base_computation: float =  _table_operations[&"computation"][type]
	if base_computation > 0.0:
		return get_effective_rate(type) * base_computation # producer (ie, server cluster)
	if positive_only:
		return 0.0
	return get_run_rate(type) * base_computation # user or NAN


func get_n_operations_in_same_group(type: int) -> int:
	var op_group: int = _table_operations[&"op_group"][type]
	var op_group_ops: Array[int] = _op_group_operations[op_group]
	return op_group_ops.size()


func is_singular(type: int) -> bool:
	var op_group: int = _table_operations[&"op_group"][type]
	var op_group_ops: Array[int] = _op_group_operations[op_group]
	return op_group_ops.size() == 1


# op_group-specific

func get_n_operations_in_group(op_group: int) -> int:
	var op_group_ops: Array[int] = _op_group_operations[op_group]
	return op_group_ops.size()


func get_group_utilization(op_group: int) -> float:
	var op_group_ops: Array[int] = _op_group_operations[op_group]
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
	for type: int in _op_group_operations[op_group]:
		sum += get_electricity_rate(type)
	return sum


func get_group_revenue(op_group: int) -> float:
	if !_has_financials:
		return NAN
	var op_group_ops: Array[int] = _op_group_operations[op_group]
	var sum := 0.0
	for type in op_group_ops:
		sum += _revenue_rates[type]
	return sum


func get_group_cogs_rate(op_group: int) -> float:
	if !_has_financials:
		return NAN
	var op_group_ops: Array[int] = _op_group_operations[op_group]
	var sum := 0.0
	for type in op_group_ops:
		sum += get_cogs_rate(type)
	return sum


func get_group_gross_margin(op_group: int) -> float:
	if !_has_financials:
		return NAN
	var op_group_ops: Array[int] = _op_group_operations[op_group]
	var sum_cogs := 0.0
	var sum_revenue := 0.0
	for type in op_group_ops:
		sum_cogs += get_cogs_rate(type)
		sum_revenue += get_revenue_rate(type)
	if sum_revenue == 0.0:
		return NAN
	return (sum_revenue - sum_cogs) / sum_revenue


func get_group_extraction_rate(op_group: int) -> float:
	var sum := 0.0
	for type: int in _op_group_operations[op_group]:
		sum += get_extraction_rate(type)
	return sum


func get_group_mass_conversion_rate(op_group: int) -> float:
	var sum := 0.0
	for type: int in _op_group_operations[op_group]:
		sum += get_mass_conversion_rate(type)
	return sum


func get_group_fuel_rate(op_group: int) -> float:
	var sum := 0.0
	for type: int in _op_group_operations[op_group]:
		sum += get_fuel_rate(type)
	return sum


func get_group_computation(op_group: int) -> float:
	var sum := 0.0
	for type: int in _op_group_operations[op_group]:
		sum += get_computation(type)
	return sum



# **************************** INTERFACE MODIFY *******************************

func set_op_command(type: int, command: int) -> void:
	assert(command < OpCommands.N_OP_COMMANDS)
	if _op_commands[type] == command:
		return
	_op_commands[type] = command
	if type < 64:
		_dirty_op_commands_1 |= 1 << type
	elif type < 128:
		_dirty_op_commands_2 |= 1 << (type - 64)
	else:
		_dirty_op_commands_3 |= 1 << (type - 128)

# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_gross_output_lfq = data[1]
	_built_mass = data[2]
	_nominal_information = data[3]
	_crews = data[4]
	_capacities = data[5]
	_run_rates = data[6]
	_effective_rates = data[7]
	_revenue_rates = data[8]
	_cogs_rates = data[9]
	_gross_margins = data[10]
	_op_logics = data[11]
	_op_commands = data[12]
	_target_utilizations = data[13]
	_has_financials = data[14]
	_is_facility = data[15]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# Changes and sets from the server entity.
	
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]
	
	var svr_qtr := int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	var dirty := int_data[int_offset]
	int_offset += 1
	if dirty & DIRTY_GROSS_OUTPUT_LFQ:
		_gross_output_lfq += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_BUILT_MASS:
		_built_mass += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_NOMINAL_INFORMATION:
		_nominal_information += float_data[float_offset]
		float_offset += 1
	
	_sync.init_for_add(int_data, float_data, int_offset, float_offset)
	_sync.add_floats_delta(_crews)
	_sync.add_floats_delta(_capacities)
	_sync.add_floats_delta(_capacities, 64)
	_sync.add_floats_delta(_capacities, 128)
	_sync.add_floats_delta(_run_rates)
	_sync.add_floats_delta(_run_rates, 64)
	_sync.add_floats_delta(_run_rates, 128)
	_sync.add_floats_delta(_effective_rates)
	_sync.add_floats_delta(_effective_rates, 64)
	_sync.add_floats_delta(_effective_rates, 128)
	
	if !_has_financials:
		return
	
	_sync.add_floats_delta(_revenue_rates)
	_sync.add_floats_delta(_revenue_rates, 64)
	_sync.add_floats_delta(_revenue_rates, 128)
	_sync.add_floats_delta(_cogs_rates)
	_sync.add_floats_delta(_cogs_rates, 64)
	_sync.add_floats_delta(_cogs_rates, 128)

	if !_is_facility:
		return
	
	_sync.set_floats_dirty(_gross_margins) # not accumulator!
	_sync.set_floats_dirty(_gross_margins, 64) # not accumulator!
	_sync.set_floats_dirty(_gross_margins, 128) # not accumulator!
	_sync.set_ints_dirty(_op_logics) # not accumulator!
	_sync.set_ints_dirty(_op_logics, 64) # not accumulator!
	_sync.set_ints_dirty(_op_logics, 128) # not accumulator!


func get_interface_dirty() -> Array:
	# TODO: parallel server pattern
	var data := []
	#_append_dirty(data, _op_commands, _dirty_op_commands_1)
	#_append_dirty(data, _op_commands, _dirty_op_commands_2, 64)
	#_dirty_op_commands_1 = 0
	#_dirty_op_commands_2 = 0
	return data
