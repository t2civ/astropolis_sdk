# inventory_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name InventoryNet
extends NetComponent

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# Arrays indexed by resource_type. Only Facilities have an Inventory.
#
# TODO: Make interface component w/out server dirty flags & delta accumulators
#
# Quantities in internal units; however prices, bids, asks refer to trade_unit.

# save/load persistence for server only
const PERSIST_PROPERTIES2: Array[StringName] = [
	&"_reserves",
	&"_delta_reserves",
	&"_markets",
	&"_delta_markets",
	&"_in_transits",
	&"_delta_in_transits",
	&"_contracteds",
	&"_delta_contracteds",
	&"_prices",
	&"_bids",
	&"_asks",
	
	&"_dirty_reserves_1",
	&"_dirty_reserves_2",
	&"_dirty_markets_1",
	&"_dirty_markets_2",
	&"_dirty_in_transits_1",
	&"_dirty_in_transits_2",
	&"_dirty_contracteds_1",
	&"_dirty_contracteds_2",
	&"_dirty_prices_1",
	&"_dirty_prices_2",
	&"_dirty_bids_1",
	&"_dirty_bids_2",
	&"_dirty_asks_1",
	&"_dirty_asks_2",
]


# Interface read-only! Data flows server -> interface.
var _reserves: Array[float] # exists here; we may need it (>= 0.0)
var _delta_reserves: Array[float]
var _markets: Array[float] # exists here; Trader may commit (>= 0.0)
var _delta_markets: Array[float]
var _in_transits: Array[float] # on the way (>= 0.0), posibly under contract
var _delta_in_transits: Array[float]
var _contracteds: Array[float] # sum of all contracts (+/-), here or elsewhere
var _delta_contracteds: Array[float]
var _prices: Array[float] # last sale or set by Exchange (NAN if no price)
var _bids: Array[float] # NAN if none
var _asks: Array[float] # NAN if none

# dirty flags
var _dirty_reserves_1 := 0
var _dirty_reserves_2 := 0 # max 128
var _dirty_markets_1 := 0
var _dirty_markets_2 := 0 # max 128
var _dirty_in_transits_1 := 0
var _dirty_in_transits_2 := 0 # max 128
var _dirty_contracteds_1 := 0
var _dirty_contracteds_2 := 0 # max 128
var _dirty_prices_1 := 0
var _dirty_prices_2 := 0 # max 128
var _dirty_bids_1 := 0
var _dirty_bids_2 := 0 # max 128
var _dirty_asks_1 := 0
var _dirty_asks_2 := 0 # max 128



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
	_delta_reserves = _reserves.duplicate()
	_delta_markets = _reserves.duplicate()
	_delta_in_transits = _reserves.duplicate()
	_delta_contracteds = _reserves.duplicate()


# ********************************** READ *************************************
# all threadsafe

func get_reserve(type: int) -> float:
	return _reserves[type] + _delta_reserves[type]


func get_market(type: int) -> float:
	return _markets[type] + _delta_markets[type]


func get_in_transit(type: int) -> float:
	return _in_transits[type] + _delta_in_transits[type]


func get_contracted(type: int) -> float:
	return _contracteds[type] + _delta_contracteds[type]


func get_price(type: int) -> float:
	return _prices[type]


func get_bid(type: int) -> float:
	return _bids[type]


func get_ask(type: int) -> float:
	return _asks[type]


func get_in_stock(type: int) -> float:
	return _reserves[type] + _delta_reserves[type] + _markets[type] + _delta_markets[type]


# ****************************** SERVER MODIFY ********************************

func change_reserve(type: int, change: float) -> void:
	assert(change >= 0.0 or change + get_reserve(type) >= 0.0)
	if !change:
		return
	_delta_reserves[type] += change
	if type < 64:
		_dirty_reserves_1 |= 1 << type
	else:
		_dirty_reserves_2 |= 1 << (type - 64)


func set_price(type: int, value: float) -> void:
	# NAN ok
	var current := _prices[type]
	if value == current:
		return
	if is_nan(value) and is_nan(current):
		return
	_prices[type] = value
	if type < 64:
		_dirty_prices_1 |= 1 << type
	else:
		_dirty_prices_2 |= 1 << (type - 64)
	

# ********************************** SYNC *************************************

func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# apply delta & dirty flags
	_int_data = data[1]
	_float_data = data[2]
	_int_offset = int_offset
	_float_offset = float_offset
	
	var svr_qtr := _int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	_dirty_reserves_1 |= _add_floats_delta(_delta_reserves)
	_dirty_reserves_2 |= _add_floats_delta(_delta_reserves, 64)
	_dirty_markets_1 |= _add_floats_delta(_delta_markets)
	_dirty_markets_2 |= _add_floats_delta(_delta_markets, 64)
	_dirty_in_transits_1 |= _add_floats_delta(_delta_in_transits)
	_dirty_in_transits_2 |= _add_floats_delta(_delta_in_transits, 64)
	_dirty_contracteds_1 |= _add_floats_delta(_delta_contracteds)
	_dirty_contracteds_2 |= _add_floats_delta(_delta_contracteds, 64)
	_dirty_prices_1 |= _set_floats_dirty(_prices)
	_dirty_prices_2 |= _set_floats_dirty(_prices, 64)
	_dirty_bids_1 |= _set_floats_dirty(_bids)
	_dirty_bids_2 |= _set_floats_dirty(_bids, 64)
	_dirty_asks_1 |= _set_floats_dirty(_asks)
	_dirty_asks_2 |= _set_floats_dirty(_asks, 64)

