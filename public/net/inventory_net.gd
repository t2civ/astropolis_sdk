# inventory_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name InventoryNet
extends RefCounted

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# Arrays indexed by resource_type. Only Facilities have an Inventory.
#
# All values in internal units!


# Interface read-only! Data flows server -> interface.
var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)

var _stocks: Array[float] # total present resource quantity (>= 0.0)
var _surplusses: Array[float] # tracker: quantity flagged for sale (not physical)
var _in_transits: Array[float] # on the way (>= 0.0), posibly under contract
var _contracteds: Array[float] # sum of all contracts (+/-), here or elsewhere
var _rates: Array[float] # current facility production (+) or consumption (-)
var _storages: Array[float] # indexed by storage_type; capacity per storage class

# lazy calculations
var _storages_used: Array[float] # indexed by storage_type; sum of _stocks
var _storages_used_valid := false

var _sync := SyncHelper.new()

static var _is_class_instanced := false
static var _n_resources: int
static var _n_storage_classes: int
static var _resource_storage_classes: Array[int]


func _init(is_new := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_n_resources = IVTableData.table_n_rows[&"resources"]
		_n_storage_classes = IVTableData.table_n_rows[&"storage_classes"]
		_resource_storage_classes = IVTableData.db_tables[&"resources"][&"storage_class"]
	if !is_new: # game load
		return
	_stocks = IVArrays.init_array(_n_resources, 0.0, TYPE_FLOAT)
	_surplusses = _stocks.duplicate()
	_in_transits = _stocks.duplicate()
	_contracteds = _stocks.duplicate()
	_rates = _stocks.duplicate()
	_storages = IVArrays.init_array(_n_storage_classes, 0.0, TYPE_FLOAT)
	_storages_used = IVArrays.init_array(_n_storage_classes, 0.0, TYPE_FLOAT)


# ********************************** READ *************************************
# all threadsafe

func get_stock(type: int) -> float:
	return _stocks[type]


func get_surplus(type: int) -> float:
	return _surplusses[type]


func get_in_transit(type: int) -> float:
	return _in_transits[type]


func get_contracted(type: int) -> float:
	return _contracteds[type]


func get_rate(type: int) -> float:
	return _rates[type]


func get_storage(storage_type: int) -> float:
	return _storages[storage_type]


func get_storage_used(storage_type: int) -> float:
	if !_storages_used_valid:
		_recompute_storages_used()
	return _storages_used[storage_type]


# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_stocks = data[1]
	_surplusses = data[2]
	_in_transits = data[3]
	_contracteds = data[4]
	_rates = data[5]
	_storages = data[6]
	_storages_used_valid = false


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# Changes and sets from the server entity.

	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]

	var svr_qtr := int_data[0]
	run_qtr = svr_qtr # TODO: histories

	_sync.init_for_add(int_data, float_data, int_offset, float_offset)
	_sync.set_floats_dirty(_stocks)
	_sync.set_floats_dirty(_surplusses)
	_sync.set_floats_dirty(_in_transits)
	_sync.set_floats_dirty(_contracteds)
	_sync.set_floats_dirty(_rates)
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
