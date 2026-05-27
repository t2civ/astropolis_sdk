# operations_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name OperationsNet
extends RefCounted

## Proxy-side operations state for a [FacilityProxy].
##
## Held by [FacilityProxy] and its [PlayerProxy], [BodyProxy], [JoinProxy]
## aggregate hosts.[br][br]
##
## WARNING: This object is maintained on the proxy thread. Only fixed-size
## properties (and their getters) are safe; see method comments.


## Per-operation bit flags represent server-origin information (bits 0 - 31)
## and proxy-origin command (bits 32 - 63).
enum OperationsFlags {
	CAN_HAVE = 1,
	FROM_SERVER_MASK = (1 << 32) - 1, ## Reserved bits 0 - 31 are server origin.

	COMMAND_PLACEHOLDER = 1 << 32,
	FROM_PROXY_MASK = ~((1 << 32) - 1), ## Reserved bits 32 - 63 are proxy origin.
}


## Bit flags marking which scalar fields of this component are dirty for sync.
enum {
	DIRTY_GROSS_OUTPUT_LFQ = 1,
	DIRTY_CONSTRUCTIONS = 1 << 1,
	DIRTY_NOMINAL_INFORMATION = 1 << 2,
}


# Proxy read-only! Data flows server -> proxy.

var ordinal_qtr := -1 ## Ordinal quarter at last sync.

var _gross_output_lfq := 0.0 # ='Economy'; set by Facility for propagation
var _constructions := 0.0 # total mass of all things construced
var _nominal_information := 0.0 # only if we don't have Cyberspace here!

var _crews: PackedFloat64Array # indexed by population_type (can have crew w/out Population component)

var _capacities: PackedFloat64Array # set by facility modules
var _run_rates: PackedFloat64Array # <= capacities; defines operation utilization
var _effective_rates: PackedFloat64Array # may differ from run rates, usually less

# Facility, Player only (_has_financials = true)
var _revenue_rates: PackedFloat64Array # at current rate & prices
var _cogs_rates: PackedFloat64Array # cost of goods sold; at current rate & prices

# Facility only
var _capacity_factors: PackedFloat64Array # environmental limit (renewable power) or historical (others)
var _gross_margins: PackedFloat64Array # at current prices (even if rate = 0)

# Bidirectional (FROM_SERVER bits server-authoritative, FROM_PROXY bits proxy-authoritative)
var _flags: PackedInt64Array # see OperationsFlags

# Facility only. Reverse data flow: proxy -> server!
var _target_utilizations: PackedFloat64Array

# Operations data here
var _has_financials := false
var _is_facility := false


# proxy dirty data (dirty indexes as bit flags)
var _dirty_flags: PackedInt64Array # FROM_PROXY-side dirty for _flags
var _dirty_target_utilizations: PackedInt64Array

var _sync := SyncHelper.new()

# localized indexing & table data
static var _db_tables := IVTableData.db_tables
static var _table_n_rows := IVTableData.table_n_rows
static var _table_modules: Dictionary[StringName, Array]
static var _module_operations: Array[PackedInt32Array]
static var _table_operations: Dictionary[StringName, Array]
static var _n_operations: int
static var _operation_electricities: PackedFloat32Array
static var _operation_process_groups: PackedInt32Array
static var _is_class_instanced := false


static func _on_class_instanced() -> void:
	_table_modules = _db_tables[&"modules"]
	_module_operations = Utils.to_array_of_packed_int32(_table_modules[&"operations"])
	_table_operations = _db_tables[&"operations"]
	_n_operations = _table_n_rows[&"operations"]
	_operation_electricities = PackedFloat32Array(_table_operations[&"electricity"])
	_operation_process_groups = PackedInt32Array(_table_operations[&"process_group"])


func _init(is_new := false, has_financials_ := false, is_facility_ := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_on_class_instanced()
	if !is_new: # game load
		return
	_has_financials = has_financials_
	_is_facility = is_facility_
	var n_populations: int = _table_n_rows[&"populations"]
	_crews.resize(n_populations)
	_capacities.resize(_n_operations)
	_run_rates.resize(_n_operations)
	_effective_rates.resize(_n_operations)
	if !_has_financials:
		return
	_revenue_rates.resize(_n_operations)
	_cogs_rates.resize(_n_operations)
	if !_is_facility:
		return
	_capacity_factors.resize(_n_operations)
	_gross_margins.resize(_n_operations)
	_gross_margins.fill(NAN)
	_flags.resize(_n_operations)
	_target_utilizations.resize(_n_operations)
	_target_utilizations.fill(1.0)
	@warning_ignore("integer_division")
	var n_op_flags := (_n_operations - 1) / 63 + 1
	_dirty_flags.resize(n_op_flags)
	_dirty_target_utilizations.resize(n_op_flags)


# ********************************** READ *************************************
# all threadsafe

# dev totals

## Returns gross output (last full quarter), the development "economy" total.
func get_gross_output_lfq() -> float:
	return _gross_output_lfq


## Returns total electricity generation (positive contributors only). Used
## for the development "power" statistic.
func get_power() -> float:
	# TODO: Handle solar foundries, etc.
	var sum := 0.0
	for type in _n_operations: # TODO: Optimize w/ subset
		sum += get_electricity_rate(type, true)
	return sum


## Returns total mass of constructions completed.
func get_constructions() -> float:
	return _constructions


## Returns nominal "information" produced (only when no [CyberspaceNet]
## component is present here).
func get_nominal_information() -> float:
	return _nominal_information


## Returns total manufacturing (production of finished resources, plus
## eventually in situ self-construction).
func get_total_manufacturing() -> float:
	var sum := 0.0
	for type in _n_operations: # TODO: Optimize w/ subset
		sum += get_manufacturing(type, true)
	return sum


## Returns total computation (positive contributors only).
func get_total_computation() -> float:
	var sum := 0.0
	for type in _n_operations: # TODO: Optimize w/ subset
		sum += get_computation(type, true)
	return sum


## Returns nominal biomass approximation derived from human crew dry weight.
func get_nominal_biomass() -> float:
	# FIXME: Terrible ad hoc solution for dev stats now.
	return _crews[0] * 21.0 * IVUnits.KG # dry weight of a person ;)


# misc

## Returns true if this component carries financials. Always true for
## [FacilityProxy] and [PlayerProxy], and for [JoinProxy]s of
## those.
func has_financials() -> bool:
	return _has_financials


## Returns true if this component is hosted by a [FacilityProxy].
func is_facility() -> bool:
	return _is_facility


# modules & crew

## Returns the module count of [param module_type] (sum of capacities of its
## operations).
func get_module_number(module_type: int) -> float:
	var op_types: PackedInt32Array = _module_operations[module_type]
	var module_number := 0.0
	for op_type in op_types:
		module_number += _capacities[op_type]
	return module_number


## Returns the crew count for [param population_type], or the total across
## all types if [param population_type] is -1.
func get_crew(population_type := -1) -> float:
	const utils := preload("uid://bxjs8bk7ksxr2")
	if population_type == -1:
		return utils.get_float_array_sum(_crews)
	return _crews[population_type]


# operation-specific

## Returns true if this facility may run operation [param type] (always
## false for non-facility hosts).
func is_can_have(type: int) -> bool:
	const CAN_HAVE := OperationsFlags.CAN_HAVE
	if _is_facility:
		return bool(_flags[type] & CAN_HAVE)
	return false


## Returns true if operation [param type] is "of interest" — either runnable
## here (facility) or non-zero capacity (aggregate hosts).
func is_of_interest(type: int) -> bool:
	const CAN_HAVE := OperationsFlags.CAN_HAVE
	if _is_facility:
		return bool(_flags[type] & CAN_HAVE)
	return _capacities[type] > 0.0


## Returns the full bidirectional flag value for operation [param type]
## (see [enum OperationsFlags]). The [code]FROM_SERVER_MASK[/code] half is
## server-authoritative; the [code]FROM_PROXY_MASK[/code] half is
## proxy-authoritative.
func get_flags(type: int) -> int:
	return _flags[type]


## Returns current run rate for operation [param type].
func get_run_rate(type: int) -> float:
	return _run_rates[type]


## Returns effective rate for operation [param type] (may differ from run
## rate, usually less).
func get_effective_rate(type: int) -> float:
	return _effective_rates[type]


## Returns capacity for operation [param type].
func get_capacity(type: int) -> float:
	return _capacities[type]


## Returns revenue rate for operation [param type], or NAN if no financials.
func get_revenue_rate(type: int) -> float:
	if !_has_financials:
		return NAN
	return _revenue_rates[type]


## Returns cost-of-goods-sold rate for operation [param type], or NAN if no
## financials.
func get_cogs_rate(type: int) -> float:
	if !_has_financials:
		return NAN
	return _cogs_rates[type]


## Returns capacity factor (environmental or historical limit) for operation
## [param type].
func get_capacity_factor(type: int) -> float:
	return _capacity_factors[type]


## Returns gross margin for operation [param type], or NAN if undefined
## (e.g., no financials, or non-facility with zero revenue).
func get_gross_margin(type: int) -> float:
	if !_has_financials:
		return NAN
	if _is_facility: # facilities (only) have margin even if revenue = 0
		return _gross_margins[type]
	var revenue := _revenue_rates[type]
	if revenue == 0.0:
		return NAN
	return (revenue - _cogs_rates[type]) / revenue


## Returns utilization (run_rate / capacity) for operation [param type], or
## 0.0 if capacity is 0.
func get_utilization(type: int) -> float:
	var capacity := _capacities[type]
	if !capacity:
		return 0.0
	return _run_rates[type] / capacity


## Returns target utilization for operation [param type] (player or AI
## intent — proxy-authoritative for facilities).
func get_target_utilization(type: int) -> float:
	return _target_utilizations[type]


## Returns electricity rate for operation [param type]. Positive for
## generators, negative for consumers. With [param positive_only] true,
## consumers return 0.0.
func get_electricity_rate(type: int, positive_only := false) -> float:
	var operation_electricity := _operation_electricities[type]
	if operation_electricity > 0.0:
		return get_effective_rate(type) * operation_electricity # generator
	if positive_only:
		return 0.0
	return get_run_rate(type) * operation_electricity # consumer


## Returns extraction rate for operation [param type].
func get_extraction_rate(type: int) -> float:
	return get_effective_rate(type) * _table_operations[&"target_rate"][type]


## Returns mass conversion rate for operation [param type] (uses run rate
## for power generators, effective rate otherwise).
func get_mass_conversion_rate(type: int) -> float:
	if _operation_electricities[type] > 0.0:
		return get_run_rate(type) * _table_operations[&"mass_conversion"][type] # power generator
	return get_effective_rate(type) * _table_operations[&"mass_conversion"][type] # power consumer


## Returns fuel rate for operation [param type] (power generators only;
## NAN otherwise).
func get_fuel_rate(type: int) -> float:
	if _operation_electricities[type] > 0.0:
		return get_run_rate(type) * _table_operations[&"fuel_rate"][type] # power generator
	return NAN


## Returns manufacturing output for operation [param type] (manufacturers
## only). With [param positive_only] true, non-manufacturers return 0.0
## instead of NAN.
func get_manufacturing(type: int, positive_only := false) -> float:
	var base_manufacturing: float = _table_operations[&"manufacturing"][type]
	if base_manufacturing > 0.0:
		return get_effective_rate(type) * base_manufacturing # manufacturer
	if positive_only:
		return 0.0
	return NAN


## Returns computation for operation [param type]. Positive for producers
## (e.g., server clusters), negative for consumers. With [param positive_only]
## true, consumers return 0.0.
func get_computation(type: int, positive_only := false) -> float:
	var base_computation: float =  _table_operations[&"computation"][type]
	if base_computation > 0.0:
		return get_effective_rate(type) * base_computation # producer (ie, server cluster)
	if positive_only:
		return 0.0
	return get_run_rate(type) * base_computation # user or NAN


# module-specific

## Returns true if any operation in [param module_type] is runnable here.
func is_can_have_module(module_type: int) -> bool:
	var module_ops: PackedInt32Array = _module_operations[module_type]
	for type in module_ops:
		if is_can_have(type):
			return true
	return false


## Returns true if any operation in [param module_type] is "of interest" here.
func is_of_interest_module(module_type: int) -> bool:
	var module_ops: PackedInt32Array = _module_operations[module_type]
	for type in module_ops:
		if is_of_interest(type):
			return true
	return false


## Returns the number of operations in [param module_type].
func get_n_operations_in_module(module_type: int) -> int:
	var module_ops: PackedInt32Array = _module_operations[module_type]
	return module_ops.size()


## Returns aggregate utilization for [param module_type] (sum of run rates
## divided by sum of capacities).
func get_module_utilization(module_type: int) -> float:
	var module_ops: PackedInt32Array = _module_operations[module_type]
	var sum_capacities := 0.0
	for type in module_ops:
		sum_capacities += get_capacity(type)
	if sum_capacities == 0.0:
		return 0.0
	var sum_rates := 0.0
	for type in module_ops:
		sum_rates += get_run_rate(type)
	return sum_rates / sum_capacities


## Returns net electricity for [param module_type] (sum of operation
## electricity rates).
func get_module_electricity(module_type: int) -> float:
	var sum := 0.0
	for type: int in _module_operations[module_type]:
		sum += get_electricity_rate(type)
	return sum


## Returns total revenue rate for [param module_type], or NAN if no
## financials.
func get_module_revenue(module_type: int) -> float:
	if !_has_financials:
		return NAN
	var module_ops: PackedInt32Array = _module_operations[module_type]
	var sum := 0.0
	for type in module_ops:
		sum += _revenue_rates[type]
	return sum


## Returns total cost-of-goods-sold rate for [param module_type], or NAN if
## no financials.
func get_module_cogs_rate(module_type: int) -> float:
	if !_has_financials:
		return NAN
	var module_ops: PackedInt32Array = _module_operations[module_type]
	var sum := 0.0
	for type in module_ops:
		sum += get_cogs_rate(type)
	return sum


## Returns aggregate gross margin for [param module_type], or NAN if no
## financials or zero revenue.
func get_module_gross_margin(module_type: int) -> float:
	if !_has_financials:
		return NAN
	var module_ops: PackedInt32Array = _module_operations[module_type]
	var sum_cogs := 0.0
	var sum_revenue := 0.0
	for type in module_ops:
		sum_cogs += get_cogs_rate(type)
		sum_revenue += get_revenue_rate(type)
	if sum_revenue == 0.0:
		return NAN
	return (sum_revenue - sum_cogs) / sum_revenue


## Returns total extraction rate for [param module_type].
func get_module_extraction_rate(module_type: int) -> float:
	var sum := 0.0
	for type: int in _module_operations[module_type]:
		sum += get_extraction_rate(type)
	return sum


## Returns total mass conversion rate for [param module_type].
func get_module_mass_conversion_rate(module_type: int) -> float:
	var sum := 0.0
	for type: int in _module_operations[module_type]:
		sum += get_mass_conversion_rate(type)
	return sum


## Returns total fuel rate for [param module_type] (power generators only).
func get_module_fuel_rate(module_type: int) -> float:
	var sum := 0.0
	for type: int in _module_operations[module_type]:
		sum += get_fuel_rate(type)
	return sum


## Returns total computation for [param module_type].
func get_module_computation(module_type: int) -> float:
	var sum := 0.0
	for type: int in _module_operations[module_type]:
		sum += get_computation(type)
	return sum


# ***************************** PROXY MODIFY **********************************

## Sets the [code]FROM_PROXY_MASK[/code] bits of flags for operation
## [param type] to [param value], preserving the server-authoritative
## [code]FROM_SERVER_MASK[/code] bits. Proxy-authoritative: this change
## flows proxy -> server. Returns true if the value changed (caller marks
## [constant Proxy.DirtyFlags.DIRTY_OPERATIONS]).
func set_flags(type: int, value: int) -> bool:
	const FROM_PROXY_MASK := OperationsFlags.FROM_PROXY_MASK
	assert((value & ~FROM_PROXY_MASK) == 0)
	var current := _flags[type]
	var new_value := (current & ~FROM_PROXY_MASK) | (value & FROM_PROXY_MASK)
	if new_value == current:
		return false
	_flags[type] = new_value
	_sync.set_dirty(_dirty_flags, type)
	return true


## Sets the target utilization for operation [param type] to [param value].
## Proxy-authoritative: this change flows proxy -> server. Returns
## true if the value changed (caller marks [constant Proxy.DirtyFlags.DIRTY_OPERATIONS]).
func set_target_utilization(type: int, value: float) -> bool:
	assert(!is_nan(value))
	assert(value >= 0.0)
	if _target_utilizations[type] == value:
		return false
	_target_utilizations[type] = value
	_sync.set_dirty(_dirty_target_utilizations, type)
	return true

# ********************************** SYNC *************************************

## Initializes this component from the server-supplied init payload.
func set_network_init(data: Array) -> void:
	ordinal_qtr = data[0]
	_gross_output_lfq = data[1]
	_constructions = data[2]
	_nominal_information = data[3]
	_crews = data[4]
	_capacities = data[5]
	_run_rates = data[6]
	_effective_rates = data[7]
	_revenue_rates = data[8]
	_cogs_rates = data[9]
	_capacity_factors = data[10]
	_gross_margins = data[11]
	_flags = data[12]
	_target_utilizations = data[13]
	_has_financials = data[14]
	_is_facility = data[15]


## Applies a server-supplied dirty payload, updating fields whose dirty flags
## are set. Called by the parent [Proxy] during sync.
func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	const FROM_SERVER_MASK := OperationsFlags.FROM_SERVER_MASK
	var int_data: PackedInt64Array = data[1]
	var float_data: PackedFloat64Array = data[2]

	var svr_qtr := int_data[0]
	ordinal_qtr = svr_qtr # TODO: histories

	var dirty := int_data[int_offset]
	int_offset += 1
	if dirty & DIRTY_GROSS_OUTPUT_LFQ:
		_gross_output_lfq += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_CONSTRUCTIONS:
		_constructions += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_NOMINAL_INFORMATION:
		_nominal_information += float_data[float_offset]
		float_offset += 1

	_sync.init_for_add(int_data, float_data, int_offset, float_offset)
	_sync.add_floats_delta(_crews)
	_sync.add_floats_delta(_capacities)
	_sync.add_floats_delta(_run_rates)
	_sync.add_floats_delta(_effective_rates)

	if !_has_financials:
		return

	_sync.add_floats_delta(_revenue_rates)
	_sync.add_floats_delta(_cogs_rates)

	if !_is_facility:
		return

	_sync.set_floats_dirty(_capacity_factors) # not accumulator!
	_sync.set_floats_dirty(_gross_margins) # not accumulator!
	_sync.set_ints_dirty_masked(_flags, FROM_SERVER_MASK) # not accumulator!


## Returns the reverse-flow payload for proxy-authoritative fields
## ([code]_target_utilizations[/code] and the [code]FROM_PROXY_MASK[/code]
## half of [code]_flags[/code]). Mirrors the forward pattern: bit-packed
## dirty flags + dense values via [SyncHelper].
func get_proxy_dirty() -> Array:
	const FROM_PROXY_MASK := OperationsFlags.FROM_PROXY_MASK
	var int_data := PackedInt64Array()
	var float_data := PackedFloat64Array()
	_sync.init_for_take(int_data, float_data)
	_sync.get_floats_dirty(_target_utilizations, _dirty_target_utilizations)
	_sync.get_ints_dirty_masked(_flags, _dirty_flags, FROM_PROXY_MASK)
	return [int_data, float_data]
