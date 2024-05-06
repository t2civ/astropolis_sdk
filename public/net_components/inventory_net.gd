# inventory_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
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

const ivutils := preload("res://addons/ivoyager_core/static/utils.gd")

# Interface read-only! Data flows server -> interface.
var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)
var _reserves: Array[float] # exists here; we may need it (>= 0.0)
var _markets: Array[float] # exists here; Trader may commit (>= 0.0)
var _in_transits: Array[float] # on the way (>= 0.0), posibly under contract
var _contracteds: Array[float] # sum of all contracts (+/-), here or elsewhere
var _prices: Array[float] # last sale or set by Exchange (NAN if no price)
var _bids: Array[float] # NAN if none
var _asks: Array[float] # NAN if none

var _sync := SyncHelper.new()


func _init(is_new := false) -> void:
	if !is_new: # game load
		return
	var n_resources: int = IVTableData.table_n_rows.resources
	_reserves = ivutils.init_array(n_resources, 0.0, TYPE_FLOAT)
	_markets = _reserves.duplicate()
	_in_transits = _reserves.duplicate()
	_contracteds = _reserves.duplicate()
	_prices = ivutils.init_array(n_resources, NAN, TYPE_FLOAT)
	_bids = _prices.duplicate()
	_asks = _prices.duplicate()


# ********************************** READ *************************************
# all threadsafe

func get_reserve(type: int) -> float:
	return _reserves[type]


func get_market(type: int) -> float:
	return _markets[type]


func get_in_transit(type: int) -> float:
	return _in_transits[type]


func get_contracted(type: int) -> float:
	return _contracteds[type]


func get_price(type: int) -> float:
	return _prices[type]


func get_bid(type: int) -> float:
	return _bids[type]


func get_ask(type: int) -> float:
	return _asks[type]


func get_in_stock(type: int) -> float:
	return _reserves[type] + _markets[type]

# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_reserves = data[1]
	_markets = data[2]
	_in_transits = data[3]
	_contracteds = data[4]
	_prices = data[5]
	_bids = data[6]
	_asks = data[7]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# Changes and sets from the server entity.
	
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]
	
	var svr_qtr := int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	_sync.init(int_data, float_data, int_offset, float_offset)
	_sync.add_floats_delta(_reserves)
	_sync.add_floats_delta(_reserves, 64)
	_sync.add_floats_delta(_markets)
	_sync.add_floats_delta(_markets, 64)
	_sync.add_floats_delta(_in_transits)
	_sync.add_floats_delta(_in_transits, 64)
	_sync.add_floats_delta(_contracteds)
	_sync.add_floats_delta(_contracteds, 64)
	_sync.set_floats_dirty(_prices)
	_sync.set_floats_dirty(_prices, 64)
	_sync.set_floats_dirty(_bids)
	_sync.set_floats_dirty(_bids, 64)
	_sync.set_floats_dirty(_asks)
	_sync.set_floats_dirty(_asks, 64)

