# exchange_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ExchangeInterface
extends Interface

## [ExchangeInterface] is a per-body resource market. One per [BodyInterface]
## with 2+ facilities.
##
## Holds current trade prices, bid/ask prices, and volumes, all indexed by
## resource_type. A value of 0.0 in [code]_prices[/code], [code]_bid_prices[/code],
## or [code]_ask_prices[/code] means "no current price". Data flows
## server -> interface only.
##
## Server-side Exchange pushes changes to [ExchangeInterface].
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## Warning! This object lives and dies on the AI thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.


## All [ExchangeInterface] instances, indexed by [member exchange_id].
static var exchange_interfaces: Array[ExchangeInterface] = []

var exchange_id := -1  ## Index into [member exchange_interfaces].
## Hosting [BodyInterface]. Immutable post-init; resolved in
## [method process_ai_init] (deferred because [code]MktsAI[/code] drains
## before [code]OpsAI[/code] does).
var body: BodyInterface
var body_name: StringName  ## Name of the hosting body.

# 0.0 means no current price (no ask price, no bid price, etc.)
var _prices: Array[float]
var _bid_prices: Array[float]
var _ask_prices: Array[float]
var _volumes: Array[float] # over previous interval /d

var _sync := SyncHelper.new()



func _init() -> void:
	super()
	entity_type = ENTITY_EXCHANGE


func _clear_circular_references() -> void:
	body = null


# *****************************************************************************
# interface API

func has_markets() -> bool:
	return true


func get_exchange() -> ExchangeInterface:
	return self


# ********************************** READ *************************************
# all threadsafe

## Returns the current trade price for [param type], or 0.0 if no current
## price.
func get_price(type: int) -> float:
	return _prices[type]


## Returns the current bid price for [param type], or 0.0 if no current bid.
func get_bid_price(type: int) -> float:
	return _bid_prices[type]


## Returns the current ask price for [param type], or 0.0 if no current ask.
func get_ask_price(type: int) -> float:
	return _ask_prices[type]


## Returns the trading volume for [param type] over the previous interval
## (per day).
func get_volume(type: int) -> float:
	return _volumes[type]


# *****************************************************************************
# sync - DON'T MODIFY!

func set_network_init(data: Array) -> void:
	exchange_id = data[2]
	name = data[3]
	gui_name = data[4]
	body_name = data[5]
	# body is resolved in process_ai_init — BodyInterface may not yet be in
	# interfaces_by_name because MktsAI is drained before OpsAI.
	run_qtr = data[6]
	_prices = data[7]
	_bid_prices = data[8]
	_ask_prices = data[9]
	_volumes = data[10]


func process_ai_init() -> void:
	if !body:
		body = interfaces_by_name[body_name]
		body.exchange = self


func sync_server_dirty(data: Array) -> void:
	var offsets: Array[int] = data[0]
	var int_data: Array[int] = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset

	if dirty & DIRTY_EXCHANGE:
		var float_data: Array[float] = data[2]
		_sync.init_for_add(int_data, float_data, offsets[k], offsets[k + 1])
		_sync.set_floats_dirty(_prices)
		_sync.set_floats_dirty(_bid_prices)
		_sync.set_floats_dirty(_ask_prices)
		_sync.set_floats_dirty(_volumes)
		k += 2

	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated
