# inventory_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name InventoryNet
extends RefCounted

## Net-synced inventory component held by [FacilityProxy].
##
## Holds resource stocks, ops reserves, in-transits, contracts, rates,
## storage capacity/usage, and AI-set strategic reserves. Arrays are indexed
## by resource_type; storage arrays by storage_class. All values are in
## internal units.
##
## Server-side Inventory pushes changes to [InventoryNet] via sync. All vars
## are proxy read-only except [code]_strategic_reserves[/code], which is
## proxy-authoritative during runtime: data flows proxy -> server. Use
## [method set_strategic_reserve] to modify; the server picks up changes via
## reverse sync. Server is the source only at game start and after load, via
## [method get_network_init] / [method set_network_init]. Only [FacilityProxy]
## has an inventory — [PlayerProxy], [BodyProxy], and [JoinProxy] do not
## aggregate inventory.
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## Warning! Like [Proxy], this object is touched on the proxy thread.
## Containers and many methods are not threadsafe; accessing non-container
## properties is safe.


## Bit flags describing per-resource state and run logic.
enum ResourceFlags {
	# State
	IS_SURPLUS = 1 << 1,
	# Run logics
	IS_MARKET = 1 << 5,
}

# Proxy read-only! Data flows server -> proxy.
## Quarterly clock at last sync, as [code]year * 4 + (quarter - 1)[/code].
var ordinal_qtr := -1

var _stocks: PackedFloat64Array # physically present and owned (>= 0.0)
var _remote_stores: Dictionary[int, PackedFloat64Array] # indexed by owning facility_id
var _ops_reserves: PackedFloat64Array # target operations reserves (tracker only)
var _in_transits: PackedFloat64Array # on the way (>= 0.0), posibly under contract
var _contracteds: PackedFloat64Array # sum of all contracts (+/-), here or elsewhere
var _rates: PackedFloat64Array # current facility production (+) or consumption (-)
var _expected_rates: PackedFloat64Array # smoothed forward-looking; gross_production - gross_consumption
var _resource_flags: PackedInt64Array # enum ResourceFlags
var _storages: PackedFloat64Array # indexed by storage_type; capacity per storage class

# Set via FacilityProxy. Reverse data flow: proxy -> server!
var _strategic_reserves: PackedFloat64Array # target strategic reserves set by AI (tracker only)

# lazy calculations
var _storages_used: PackedFloat64Array # indexed by storage_type; sum of _stocks + values of _remote_stores
var _storages_used_valid := false

# proxy dirty data (dirty indexes as bit flags)
var _dirty_strategic_reserves: PackedInt64Array

var _sync := SyncHelper.new()

static var _is_class_instanced := false
static var _n_resources: int
static var _n_storage_classes: int
static var _resource_storage_classes: PackedInt32Array


static func _on_class_instanced() -> void:
	_n_resources = IVTableData.table_n_rows[&"resources"]
	_n_storage_classes = IVTableData.table_n_rows[&"storage_classes"]
	var resource_table: Dictionary[StringName, Array] = IVTableData.db_tables[&"resources"]
	_resource_storage_classes = PackedInt32Array(resource_table[&"storage_class"])


func _init(is_new := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_on_class_instanced()
	if !is_new: # game load
		return
	_stocks.resize(_n_resources)
	_ops_reserves.resize(_n_resources)
	_in_transits.resize(_n_resources)
	_contracteds.resize(_n_resources)
	_rates.resize(_n_resources)
	_expected_rates.resize(_n_resources)
	_resource_flags.resize(_n_resources)
	_storages.resize(_n_storage_classes)
	_strategic_reserves.resize(_n_resources)
	_storages_used.resize(_n_storage_classes)
	@warning_ignore("integer_division")
	var n_resource_flags := (_n_resources - 1) / 63 + 1
	_dirty_strategic_reserves.resize(n_resource_flags)


# ********************************** READ *************************************
# all threadsafe

## Returns total stock for [param type] (>= 0.0).
func get_stock(type: int) -> float:
	return _stocks[type]


## Returns the remote-store quantity owned by [param facility_id_] for
## [param resource_type], physically present here (>= 0.0).
func get_remote_store(facility_id_: int, resource_type: int) -> float:
	if !_remote_stores.has(facility_id_):
		return 0.0
	return _remote_stores[facility_id_][resource_type]


## Returns the ops-reserve buffer for [param type] (quantity reserved for
## ongoing operations).
func get_ops_reserve(type: int) -> float:
	return _ops_reserves[type]


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


## Returns the strategic reserve for [param type] (AI target —
## [FacilityProxy] is authoritative; see class doc).
func get_strategic_reserve(type: int) -> float:
	return _strategic_reserves[type]


# ***************************** PROXY MODIFY **********************************

## Sets the strategic reserve for [param type] to [param value].
## Proxy-authoritative: this change flows proxy -> server. Returns true if
## the value changed (caller marks [constant Proxy.DirtyFlags.DIRTY_INVENTORY]).
func set_strategic_reserve(type: int, value: float) -> bool:
	assert(!is_nan(value))
	assert(value >= 0.0)
	if _strategic_reserves[type] == value:
		return false
	_strategic_reserves[type] = value
	_sync.set_dirty(_dirty_strategic_reserves, type)
	return true


# ********************************** SYNC *************************************

## Initializes this component from the server-supplied init payload.
func set_network_init(data: Array) -> void:
	ordinal_qtr = data[0]
	_stocks = data[1]
	_remote_stores = data[2]
	_ops_reserves = data[3]
	_in_transits = data[4]
	_contracteds = data[5]
	_rates = data[6]
	_resource_flags = data[7]
	_storages = data[8]
	_expected_rates = data[9]
	_strategic_reserves = data[10]
	_storages_used_valid = false


## Applies a server-supplied dirty payload, updating fields whose dirty flags
## are set. Called by the parent [Proxy] during sync.
func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	var int_data: PackedInt64Array = data[1]
	var float_data: PackedFloat64Array = data[2]

	var svr_qtr := int_data[0]
	ordinal_qtr = svr_qtr # TODO: histories

	_sync.init_for_add(int_data, float_data, int_offset, float_offset)
	_sync.set_floats_dirty(_stocks)
	_sync.add_sparse_floats_dict_delta(_remote_stores, _n_resources)
	_sync.set_floats_dirty(_ops_reserves)
	_sync.set_floats_dirty(_in_transits)
	_sync.set_floats_dirty(_contracteds)
	_sync.set_floats_dirty(_rates)
	_sync.set_floats_dirty(_expected_rates)
	_sync.set_ints_dirty(_resource_flags)
	_sync.set_floats_dirty_63(_storages)
	_storages_used_valid = false


## Returns the reverse-flow payload for proxy-authoritative fields
## ([code]_strategic_reserves[/code]). Mirrors the forward pattern:
## bit-packed dirty flags + dense values via [SyncHelper].
func get_proxy_dirty() -> Array:
	var int_data := PackedInt64Array()
	var float_data := PackedFloat64Array()
	_sync.init_for_take(int_data, float_data)
	_sync.get_floats_dirty(_strategic_reserves, _dirty_strategic_reserves)
	return [int_data, float_data]


func _recompute_storages_used() -> void:
	for storage_class in _n_storage_classes:
		_storages_used[storage_class] = 0.0
	for resource_type in _n_resources:
		var storage_class := _resource_storage_classes[resource_type]
		if storage_class == -1:
			continue
		_storages_used[storage_class] += _stocks[resource_type]
	for arr: PackedFloat64Array in _remote_stores.values():
		for resource_type in _n_resources:
			var storage_class := _resource_storage_classes[resource_type]
			if storage_class == -1:
				continue
			_storages_used[storage_class] += arr[resource_type]
	_storages_used_valid = true
