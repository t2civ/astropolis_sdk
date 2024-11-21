# marketplace_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name MarketplaceNet
extends RefCounted

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# Arrays indexed by resource_type. Only Bodies have Marketplaces.
#
# All values in internal units!

const ivutils := preload("res://addons/ivoyager_core/static/utils.gd")

# Interface read-only! Data flows server -> interface.
var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)
var _prices: Array[float] # last sale or set by Exchange (NAN if no price)
var _bids: Array[float] # NAN if none
var _asks: Array[float] # NAN if none
var _volumes: Array[float] # over previous interval /d

var _sync := SyncHelper.new()


func _init(is_new := false) -> void:
	if !is_new: # game load
		return
	var n_resources: int = IVTableData.table_n_rows.resources
	_prices = ivutils.init_array(n_resources, NAN, TYPE_FLOAT)
	_bids = _prices.duplicate()
	_asks = _prices.duplicate()
	_volumes = ivutils.init_array(n_resources, 0.0, TYPE_FLOAT)


# ********************************** READ *************************************
# all threadsafe

func get_price(type: int) -> float:
	return _prices[type]


func get_bid(type: int) -> float:
	return _bids[type]


func get_ask(type: int) -> float:
	return _asks[type]


func get_volume(type: int) -> float:
	return _volumes[type]

# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_prices = data[1]
	_bids = data[2]
	_asks = data[3]
	_volumes = data[4]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# Changes and sets from the server entity.
	
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]
	
	var svr_qtr := int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	_sync.init_for_add(int_data, float_data, int_offset, float_offset)
	_sync.set_floats_dirty(_prices)
	_sync.set_floats_dirty(_prices, 64)
	_sync.set_floats_dirty(_bids)
	_sync.set_floats_dirty(_bids, 64)
	_sync.set_floats_dirty(_asks)
	_sync.set_floats_dirty(_asks, 64)
	_sync.set_floats_dirty(_volumes)
	_sync.set_floats_dirty(_volumes, 64)
