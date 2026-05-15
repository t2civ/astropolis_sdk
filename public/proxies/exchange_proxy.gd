# exchange_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ExchangeProxy
extends Proxy

## Provides resource spot prices and spot and futures markets.
##
## A [BodyProxy] with a [FacilityProxy] always gains an exchange. At minimum, the
## exchange provides "spot" prices for relevant resources, determined either
## via spot market trades or by fiat (using a market maker functionality).[br][br]
##
## If a body has >1 facilities, [ExchangeProxy] provides a resource spot market.
## The spot market processes spot orders for within-body, immediate-delivery
## trades only. These orders originate from local [TraderProxy]s only. Note that
## more than one exchange per body will be implemented in the future to support
## player sanctions (this may result in runtime changes in [member
## Proxy.spot_exchage]).[br][br]
##
## Spot orders (spot bids and spot asks) are fixed-size [PackedInt64Array]
## structures with the following elements:[br][br]
##
##   [0] id (ask_id or bid_id)[br]
##   [1] resource_type[br]
##   [2] order_quantity (in trade_unit)[br]
##   [3] unfilled_quantity (in trade_unit)[br]
##   [4] price (per trade_unit)[br]
##   [5] expiration (epoch seconds)[br]
##   [6] trader_id[br][br]
##
## Exchanges also design and list (or delist) futures contracts as appropriate.
## Futures contracts specify time and place of delivery of a resource. They can
## be traded by anyone (a local or remote trader) but are the only means for
## inter-body resource trades. I.e., this is how interplanetary commerce and
## remote resupply happen. The single [BrokerProxy] at a body lists available
## futures contracts for delivery at a body and routes futures orders to an
## appropriate exchange (more than one exchange may list the same futures
## delivery contract).[br][br]
##
## WIP: Futuers contracts and orders...[br][br]
##
## WIP: code planning...[br][br]
##
##   - Phase 1: Implement spot trading so that Earth nations can trade and the
##     Earth economy simulation basically "works" and can be tunned.
##   - Phase 2: Implement futures trading to support ISS, Tiangong, and
##     runtime-added Moon Base, etc. This will require a functioning transport
##     system with a transport schedular and market.[br][br]
##
## Arrays are indexed by resource_type unless indicated otherwise. A value of
## 0.0 in any "price" variable means N/A or no current price.[br][br]
##
## Server-side Exchange pushes changes to [ExchangeProxy]. Data flows
## server -> proxy only. WARNING: This object lives and dies on the AI thread!
## Containers and many methods are not threadsafe. Accessing non-container
## properties is safe.

const ORDER_SIZE := 7

## All [ExchangeProxy] instances, indexed by [member exchange_id].
static var exchange_proxies: Array[ExchangeProxy] = []

var exchange_id := -1  ## Index into [member exchange_proxies].
## Hosting [BodyProxy]. Immutable post-init; resolved in
## [method process_ai_init] (deferred because [code]MktsAI[/code] drains
## before [code]OpsAI[/code] does).
var body: BodyProxy
var body_name: StringName  ## Name of the hosting body.

var _prices: PackedFloat64Array
var _ask_prices: PackedFloat64Array
var _bid_prices: PackedFloat64Array
var _volumes: PackedFloat64Array

var _asks: Dictionary[int, PackedInt64Array] = {}  ## Asks indexed by ask_id.
var _bids: Dictionary[int, PackedInt64Array] = {}  ## Bids indexed by bid_id.

var _sync := SyncHelper.new()

# Recycled orders.
var _free_orders: Array[PackedInt64Array] = []



func _init() -> void:
	const ENTITY_EXCHANGE := Proxy.EntityType.ENTITY_EXCHANGE
	super()
	entity_type = ENTITY_EXCHANGE


func _clear_circular_references() -> void:
	body = null


# *****************************************************************************
# proxy API

func has_markets() -> bool:
	return true


func get_spot_exchange(_player_id: int) -> ExchangeProxy:
	return self


# ********************************** READ *************************************
# all threadsafe

## Returns the current trade price for [param type], or 0.0 if no current
## price.
func get_spot_price(type: int) -> float:
	return _prices[type]


## Returns the current ask price for [param type], or 0.0 if no current ask.
func get_spot_ask_price(type: int) -> float:
	return _ask_prices[type]


## Returns the current bid price for [param type], or 0.0 if no current bid.
func get_spot_bid_price(type: int) -> float:
	return _bid_prices[type]


## Returns the trading volume for [param type] over the previous interval
## (per day).
func get_spot_volume(type: int) -> float:
	return _volumes[type]


# *****************************************************************************
# sync - DON'T MODIFY!

func set_network_init(data: Array) -> void:
	exchange_id = data[2]
	name = data[3]
	gui_name = data[4]
	body_name = data[5]
	# body is resolved in process_ai_init — BodyProxy may not yet be in
	# proxies_by_name because MktsAI is drained before OpsAI.
	ordinal_qtr = data[6]
	_prices = data[7]
	_ask_prices = data[8]
	_bid_prices = data[9]
	_volumes = data[10]
	_asks = data[11]
	_bids = data[12]


func process_ai_init() -> void:
	if !body:
		body = proxies_by_name[body_name]


func sync_server_dirty(data: Array) -> void:
	const DIRTY_EXCHANGE := Proxy.DirtyFlags.DIRTY_EXCHANGE
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset

	if dirty & DIRTY_EXCHANGE:
		var float_data: PackedFloat64Array = data[2]
		_sync.init_for_add(int_data, float_data, offsets[k], offsets[k + 1])
		_sync.set_floats_dirty(_prices)
		_sync.set_floats_dirty(_ask_prices)
		_sync.set_floats_dirty(_bid_prices)
		_sync.set_floats_dirty(_volumes)
		_add_orders_delta(_asks, int_data)
		_add_orders_delta(_bids, int_data)
		k += 2

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated


# Recycles removed orders.
func _add_orders_delta(target: Dictionary[int, PackedInt64Array], int_data: PackedInt64Array) -> void:
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
