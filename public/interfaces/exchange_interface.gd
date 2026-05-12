# exchange_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ExchangeInterface
extends Interface

## [ExchangeInterface] is a per-body resource market.
##
## Created when a [BodyInterface] gains >1 [FacilityInterface]. Hosts local and
## remote [TraderInterface]es.[br][br]
##
## Arrays are indexed by resource_type unless indicated otherwise. A value of
## 0.0 in any "price" variable means N/A or no current price.[br][br]
##
## Asks and Bids ("orders") are fixed-size PackedInt64Array structures with the
## following elements:[br][br]
##
##   [0] id (ask_id or bid_id)[br]
##   [1] resource_type[br]
##   [2] order_quantity (in trade_unit)[br]
##   [3] unfilled_quantity (in trade_unit)[br]
##   [4] price (per trade_unit)[br]
##   [5] expiration (epoch seconds)[br]
##   [6] trader_id[br][br]
##
## Server-side Exchange pushes changes to [ExchangeInterface]. Data flows
## server -> interface only.[br][br]
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.[br][br]
##
## Warning! This object lives and dies on the AI thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.

const ORDER_SIZE := 7

## All [ExchangeInterface] instances, indexed by [member exchange_id].
static var exchange_interfaces: Array[ExchangeInterface] = []

var exchange_id := -1  ## Index into [member exchange_interfaces].
## Hosting [BodyInterface]. Immutable post-init; resolved in
## [method process_ai_init] (deferred because [code]MktsAI[/code] drains
## before [code]OpsAI[/code] does).
var body: BodyInterface
var body_name: StringName  ## Name of the hosting body.

var _prices: Array[float]
var _ask_prices: Array[float]
var _bid_prices: Array[float]
var _volumes: Array[float]

var _asks: Dictionary[int, PackedInt64Array] = {}  ## Asks indexed by ask_id.
var _bids: Dictionary[int, PackedInt64Array] = {}  ## Bids indexed by bid_id.

var _sync := SyncHelper.new()

# Recycled orders.
var _free_orders: Array[PackedInt64Array] = []



func _init() -> void:
	const ENTITY_EXCHANGE := Interface.EntityType.ENTITY_EXCHANGE
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


## Returns the current ask price for [param type], or 0.0 if no current ask.
func get_ask_price(type: int) -> float:
	return _ask_prices[type]


## Returns the current bid price for [param type], or 0.0 if no current bid.
func get_bid_price(type: int) -> float:
	return _bid_prices[type]


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
	_ask_prices = data[8]
	_bid_prices = data[9]
	_volumes = data[10]
	_asks = data[11]
	_bids = data[12]


func process_ai_init() -> void:
	if !body:
		body = interfaces_by_name[body_name]


func sync_server_dirty(data: Array) -> void:
	const DIRTY_EXCHANGE := Interface.DirtyFlags.DIRTY_EXCHANGE
	var offsets: Array[int] = data[0]
	var int_data: Array[int] = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset

	if dirty & DIRTY_EXCHANGE:
		var float_data: Array[float] = data[2]
		_sync.init_for_add(int_data, float_data, offsets[k], offsets[k + 1])
		_sync.set_floats_dirty(_prices)
		_sync.set_floats_dirty(_ask_prices)
		_sync.set_floats_dirty(_bid_prices)
		_sync.set_floats_dirty(_volumes)
		_add_orders_delta(_asks, int_data)
		_add_orders_delta(_bids, int_data)
		k += 2

	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated


# Recycles removed orders.
func _add_orders_delta(target: Dictionary[int, PackedInt64Array], int_data: Array[int]) -> void:
	var int_offset := _sync.int_offset
	var upserts_count := int_data[int_offset]
	int_offset += 1
	var i := 0
	while i < upserts_count:
		var order: PackedInt64Array
		if _free_orders:
			order = _free_orders.pop_back()
		else:
			order = PackedInt64Array()
			order.resize(ORDER_SIZE)
		for j in ORDER_SIZE:
			order[j] = int_data[int_offset + j]
		int_offset += ORDER_SIZE
		target[order[0]] = order
		i += 1
	var removes_count := int_data[int_offset]
	int_offset += 1
	i = 0
	while i < removes_count:
		var id := int_data[int_offset]
		int_offset += 1
		_free_orders.append(target[id])
		target.erase(id)
		i += 1
	_sync.int_offset = int_offset
