# inventory_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name InventoryNet
extends RefCounted

## Net-synced inventory component held by [FacilityInterface].
##
## Holds resource stocks, reserves (ops, trade), in-transits, contracts,
## rates, and storage capacity/usage. Arrays are indexed by resource_type;
## storage arrays by storage_class. All values are in internal units.
##
## Server-side Inventory pushes changes to [InventoryNet] via sync. Only
## [FacilityInterface] has an inventory — [PlayerInterface], [BodyInterface],
## and [JoinInterface] do not aggregate inventory.
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## Warning! Like [Interface], this object is touched on the AI thread.
## Containers and many methods are not threadsafe; accessing non-container
## properties is safe.


## Bit flags describing per-resource state and run logic.
enum ResourceFlags {
	# State
	IS_SURPLUS = 1 << 1,
	# Run logics
	IS_MARKET = 1 << 5,
}

# Interface read-only! Data flows server -> interface.
## Quarterly clock at last sync, as [code]year * 4 + (quarter - 1)[/code].
var run_qtr := -1

var _stocks: Array[float] # total present resource quantity (>= 0.0)
var _ops_reserves: Array[float] # tracker: quantity reserved for operations
var _trade_reserves: Array[float] # tracker: quantity reserved for trade
var _in_transits: Array[float] # on the way (>= 0.0), posibly under contract
var _contracteds: Array[float] # sum of all contracts (+/-), here or elsewhere
var _rates: Array[float] # current facility production (+) or consumption (-)
var _expected_rates: Array[float] # smoothed forward-looking; gross_production - gross_consumption
var _resource_flags: Array[int] # enum ResourceFlags
var _storages: Array[float] # indexed by storage_type; capacity per storage class

# lazy calculations
var _storages_used: Array[float] # indexed by storage_type; sum of _stocks
var _storages_used_valid := false

var _sync := SyncHelper.new()

static var _is_class_instanced := false
static var _n_resources: int
static var _n_storage_classes: int
static var _resource_storage_classes: PackedInt32Array


static func _on_instanced() -> void:
	_n_resources = IVTableData.table_n_rows[&"resources"]
	_n_storage_classes = IVTableData.table_n_rows[&"storage_classes"]
	var resource_table: Dictionary[StringName, Array] = IVTableData.db_tables[&"resources"]
	_resource_storage_classes = PackedInt32Array(resource_table[&"storage_class"])


func _init(is_new := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_on_instanced()
	if !is_new: # game load
		return
	_stocks = IVArrays.init_array(_n_resources, 0.0, TYPE_FLOAT)
	_ops_reserves = _stocks.duplicate()
	_trade_reserves = _stocks.duplicate()
	_in_transits = _stocks.duplicate()
	_contracteds = _stocks.duplicate()
	_rates = _stocks.duplicate()
	_expected_rates = _stocks.duplicate()
	_resource_flags = IVArrays.init_array(_n_resources, 0, TYPE_INT)
	_storages = IVArrays.init_array(_n_storage_classes, 0.0, TYPE_FLOAT)
	_storages_used = IVArrays.init_array(_n_storage_classes, 0.0, TYPE_FLOAT)


# ********************************** READ *************************************
# all threadsafe

## Returns total stock for [param type] (>= 0.0).
func get_stock(type: int) -> float:
	return _stocks[type]


## Returns the ops-reserve buffer for [param type] (quantity reserved for
## ongoing operations).
func get_ops_reserve(type: int) -> float:
	return _ops_reserves[type]


## Returns the trade-reserve buffer for [param type] (quantity reserved for
## active trades).
func get_trade_reserve(type: int) -> float:
	return _trade_reserves[type]


## Returns in-transit quantity for [param type] (>= 0.0; possibly under
## contract).
func get_in_transit(type: int) -> float:
	return _in_transits[type]


## Returns net contracted quantity for [param type] (sum of all contracts).
func get_contracted(type: int) -> float:
	return _contracteds[type]


## Returns the most recent measured rate for [param type] (positive =
## production, negative = consumption).
func get_rate(type: int) -> float:
	return _rates[type]


## Returns the smoothed expected rate for [param type]
## (gross_production - gross_consumption).
func get_expected_rate(type: int) -> float:
	return _expected_rates[type]


## Returns resource flags for [param type] (see [enum ResourceFlags]).
func get_resource_flags(type: int) -> int:
	return _resource_flags[type]


## Returns total storage capacity for [param storage_type].
func get_storage(storage_type: int) -> float:
	return _storages[storage_type]


## Returns total stock currently using [param storage_type] (lazy-recomputed).
func get_storage_used(storage_type: int) -> float:
	if !_storages_used_valid:
		_recompute_storages_used()
	return _storages_used[storage_type]


# ********************************** SYNC *************************************

## Initializes this component from the server-supplied init payload.
func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_stocks = data[1]
	_ops_reserves = data[2]
	_trade_reserves = data[3]
	_in_transits = data[4]
	_contracteds = data[5]
	_rates = data[6]
	_resource_flags = data[7]
	_storages = data[8]
	_expected_rates = data[9]
	_storages_used_valid = false


## Applies a server-supplied dirty payload, updating fields whose dirty flags
## are set. Called by the parent [Interface] during sync.
func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]

	var svr_qtr := int_data[0]
	run_qtr = svr_qtr # TODO: histories

	_sync.init_for_add(int_data, float_data, int_offset, float_offset)
	_sync.set_floats_dirty(_stocks)
	_sync.set_floats_dirty(_ops_reserves)
	_sync.set_floats_dirty(_trade_reserves)
	_sync.set_floats_dirty(_in_transits)
	_sync.set_floats_dirty(_contracteds)
	_sync.set_floats_dirty(_rates)
	_sync.set_floats_dirty(_expected_rates)
	_sync.set_ints_dirty(_resource_flags)
	_sync.set_floats_dirty_63(_storages)
	_storages_used_valid = false


func _recompute_storages_used() -> void:
	for storage_class in _n_storage_classes:
		_storages_used[storage_class] = 0.0
	for resource_type in _n_resources:
		var storage_class := _resource_storage_classes[resource_type]
		if storage_class == -1:
			continue
		_storages_used[storage_class] += _stocks[resource_type]
	_storages_used_valid = true
