# market_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name MarketProxy
extends Proxy

## Provides resource spot prices and a market for spot and futures trading.
##
## A [BodyProxy] with a [FacilityProxy] always gains a market. At minimum, the
## market provides "spot" prices for relevant resources, determined either
## via spot market trades or by fiat using a market maker functionality.[br][br]
##
## If a body has >1 facilities, [MarketProxy] provides a resource spot market.
## The spot market processes spot orders for within-body, immediate-delivery
## trades only. These orders originate from local [TraderProxy]s only. Note that
## more than one market per body will be implemented in the future to support
## player sanctions (this may result in runtime changes in [member
## FacilityProxy.market] and [member TraderProxy.market]).[br][br]
##
## Spot limit orders (bids and asks) are fixed-size [PackedInt64Array]
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
## Markets also list futures contracts for delivery at the market [member body].
## Futures contracts specify time of delivery of a specific resource quantity.
## They can be traded by anyone (a local or remote trader) and are the means for
## inter-body resource trades. The futures market is the driving force behind
## interplanetary commerce and remote resupply.[br][br]
##
## WIP: Futuers contracts and orders...[br][br]
##
## WIP: code planning...[br][br]
##
##   - Phase 1: Implement spot trading so that Earth nations can trade and the
##     Earth economy simulation basically "works" and can be tunned.
##   - Phase 2: Implement futures trading to support ISS, Tiangong, and
##     runtime-added Moon Base, etc. This will require a functioning transport
##     system.[br][br]
##
## TODO: Although [Market] provides the "interface" for futures contracts delivered
## at [member body], the physical machinery of futures trading happens at a
## centralized [Exchange] possibly elsewhere. E.g., futures contracts for
## delivery to Earth-orbiting stations or a Moon Base are likely to originate
## and trade at an Earth futures exchange (such as the Chicago Mercantile
## Exchange). Only highly developed bodies have physical exchanges.[br][br]
##
## Arrays are indexed by resource_type unless indicated otherwise. A value of
## 0.0 in any "price" variable means N/A or no current price.[br][br]
##
## Server-side Market pushes changes to [MarketProxy]. Data flows
## server -> proxy only. WARNING: This object lives and dies on the proxy thread!
## Containers and many methods are not threadsafe. Accessing non-container
## properties is safe.

const SPOT_LIMIT_ORDER_SIZE := 7

var market_id := -1  ## Index into [member ProxyBus.market_proxies].
## Hosting [BodyProxy]. Immutable post-init; resolved in
## [method process_ai_init] (deferred because [code]MktsProxy[/code] drains
## before [code]OpsProxy[/code] does).
var body: BodyProxy ## [Body] of the spot market and futures contract delivery.
var body_name: StringName  ## @deprecate: why is this here?

var _prices: PackedFloat64Array
var _ask_prices: PackedFloat64Array
var _bid_prices: PackedFloat64Array
var _volumes: PackedFloat64Array

var _asks: Dictionary[int, PackedInt64Array] = {}  # indexed by ask_id.
var _bids: Dictionary[int, PackedInt64Array] = {}  # indexed by bid_id.

var _recycled_limit_orders: Array[PackedInt64Array] = []

var _sync := SyncHelper.new()



func _init() -> void:
	const ENTITY_MARKET := Proxy.EntityType.ENTITY_MARKET
	super()
	entity_type = ENTITY_MARKET


func _clear_for_destruction() -> void:
	body = null


# *****************************************************************************
# proxy API

func has_markets() -> bool:
	return true


func get_market(_player_id: int) -> MarketProxy:
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
	market_id = data[2]
	name = data[3]
	gui_name = data[4]
	body_name = data[5]
	# body is resolved in process_ai_init — BodyProxy may not yet be in
	# proxy_bus.proxies_by_name because MktsProxy is drained before OpsProxy.
	ordinal_qtr = data[6]
	_prices = data[7]
	_ask_prices = data[8]
	_bid_prices = data[9]
	_volumes = data[10]
	_asks = data[11]
	_bids = data[12]


func process_ai_init() -> void:
	if !body:
		body = proxy_bus.proxies_by_name[body_name]


func _sync_server_dirty(data: Array) -> void:
	const DIRTY_MARKET := Proxy.DirtyFlags.DIRTY_MARKET
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset

	if dirty & DIRTY_MARKET:
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
		if _recycled_limit_orders:
			order = _recycled_limit_orders.pop_back()
		else:
			order = PackedInt64Array()
			order.resize(SPOT_LIMIT_ORDER_SIZE)
		for j in SPOT_LIMIT_ORDER_SIZE:
			order[j] = int_data[int_offset + j]
		int_offset += SPOT_LIMIT_ORDER_SIZE
		target[order[0]] = order
		i += 1
	var removes_count := int_data[int_offset]
	int_offset += 1
	i = 0
	while i < removes_count:
		var id := int_data[int_offset]
		int_offset += 1
		_recycled_limit_orders.append(target[id])
		target.erase(id)
		i += 1
	_sync.int_offset = int_offset
