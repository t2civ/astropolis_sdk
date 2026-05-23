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
## All trade orders are implemented as "limit orders". Traders can specify a
## "market order", in effect, by specifying a permisive price and near-future
## expiration. Traders for "market maker" facilities (i.e., those representing
## large ports) will try to keep a surplus (trade reserve) of all relevant
## resources and have standing bids and asks for all.[br][br]
## 
## Spot orders (bids and asks) are fixed-size [PackedInt64Array] structures
## with the following elements:[br][br]
##
##   [0] id (sequential per order type)[br]
##   [1] resource_type[br]
##   [2] unit price (USD per trade_unit)[br]
##   [3] order_quantity (in trade_unit)[br]
##   [4] unfilled_quantity (in trade_unit)[br]
##   [-2] expiration (epoch days)[br]
##   [-1] trader_id[br]
##   (Note: Negative indexes allow consistant indexing with futures below.)[br][br]
##
## Markets also list futures contracts for delivery at the market [member body].
## Futures contracts specify time of delivery (ordinal quarter) of a specific
## resource quantity at a specific facility. They can be traded by anyone (a
## local or remote trader) and are the means for inter-body resource trades.
## The futures market is the driving force behind interplanetary commerce and
## remote resupply. Futures orders (bids and asks) are fixed-size
## [PackedInt64Array] structures with the following elements:[br][br]
##
##   [0] id (sequential per order type)[br]
##   [1] resource_type[br]
##   [2] unit price (USD per trade_unit)[br]
##   [3] order_quantity (in trade_unit)[br]
##   [4] unfilled_quantity (in trade_unit)[br]
##   [5] delivery facility_id[br]
##   [6] delivery ordinal quarter[br]
##   [-2] expiration (epoch days)[br]
##   [-1] trader_id[br][br]
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
## centralized "Exchange" possibly elsewhere. E.g., futures contracts for
## delivery to Earth-orbiting stations or a Moon Base are likely to originate
## and trade at an Earth futures exchange (such as the Chicago Mercantile
## Exchange). Only highly developed bodies have physical exchanges.[br][br]
##
## [MarketProxy] times, prices, and order quantities are all in integer "ticks",
## where time is specified in integer seconds (class assumes
## IVUnits.SECOND == 1.0), price in integer USD (class assumes
## IVUnits.USD == 1.0), and order quantity in integer "trade units"
## (specified by `trade_unit` in table resources.tsv). Note that this differs
## from almost all other code which uses internal "sim units" defined in
## [IVUnits]. API convention here is to provide regular sim units in functions
## like [method get_spot_price] and use "unit" in the name to provide
## [Market]-internal values (e.g. [method get_spot_unit_price]). Volume is the
## exception: it is float in sim units in both the storage and the API.[br][br]
##
## Arrays are indexed by resource_type unless indicated otherwise. A stored
## value of 0 in any internal "price" variable means N/A or no current price
## (sim-unit getters return 0.0 in that case).[br][br]
##
## Server-side Market pushes changes to [MarketProxy]. Market also recieves
## channel method calls from [TraderProxy]. This object lives and dies on the
## proxy thread! Resizeable containers and associated methods are not
## threadsafe. Accessing non-container properties is safe.

const SPOT_ORDER_SIZE := 7
const FUTURES_ORDER_SIZE := 9


static var _is_class_instanced := false
static var _resource_trade_unit_multipliers: PackedFloat64Array # convert trade -> sim


var market_id := -1  ## Index into [member ProxyBus.market_proxies].
## Hosting [BodyProxy]. Immutable post-init; resolved in
## [method process_ai_init] (deferred because [code]MktsProxy[/code] drains
## before [code]OpsProxy[/code] does).
var body: BodyProxy ## [Body] of the spot market and futures contract delivery.
var body_name: StringName  ## @deprecate: why is this here?

var _spot_prices: PackedInt64Array
var _spot_ask_prices: PackedInt64Array
var _spot_bid_prices: PackedInt64Array
var _spot_volumes: PackedFloat64Array
var _spot_asks: Dictionary[int, PackedInt64Array] = {}  # indexed by ask_id.
var _spot_bids: Dictionary[int, PackedInt64Array] = {}  # indexed by bid_id.

var _sync := SyncHelper.new()



static func _on_class_instanced() -> void:
	_resource_trade_unit_multipliers = ThreadsafeGlobal.resource_trade_unit_multipliers


func _init() -> void:
	const ENTITY_MARKET := Proxy.EntityType.ENTITY_MARKET
	super()
	entity_type = ENTITY_MARKET
	if !_is_class_instanced:
		_is_class_instanced = true
		_on_class_instanced()


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

## Returns the current trade price for [param type] in sim units, or 0.0 if no
## current price.
func get_spot_price(type: int) -> float:
	return _spot_prices[type] / _resource_trade_unit_multipliers[type]


## Returns the current ask price for [param type] in sim units, or 0.0 if no
## current ask.
func get_spot_ask_price(type: int) -> float:
	return _spot_ask_prices[type] / _resource_trade_unit_multipliers[type]


## Returns the current bid price for [param type] in sim units, or 0.0 if no
## current bid.
func get_spot_bid_price(type: int) -> float:
	return _spot_bid_prices[type] / _resource_trade_unit_multipliers[type]


## Returns the [Market]-internal unit price for [param type], or 0 if no
## current price.
func get_spot_unit_price(type: int) -> int:
	return _spot_prices[type]


## Returns the [Market]-internal ask unit price for [param type], or 0 if no
## current ask.
func get_spot_ask_unit_price(type: int) -> int:
	return _spot_ask_prices[type]


## Returns the [Market]-internal bid unit price for [param type], or 0 if no
## current bid.
func get_spot_bid_unit_price(type: int) -> int:
	return _spot_bid_prices[type]


## Returns the trading volume for [param type] in trade units per day, smoothed
## over 7 days.
func get_spot_unit_volume(type: int) -> float:
	return _spot_volumes[type]

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
	_spot_prices = data[7]
	_spot_ask_prices = data[8]
	_spot_bid_prices = data[9]
	_spot_volumes = data[10]
	_spot_asks = data[11]
	_spot_bids = data[12]


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
		_sync.set_ints_dirty(_spot_prices)
		_sync.set_ints_dirty(_spot_ask_prices)
		_sync.set_ints_dirty(_spot_bid_prices)
		_sync.set_floats_dirty(_spot_volumes)
		_add_orders_delta(_spot_asks, int_data, SPOT_ORDER_SIZE)
		_add_orders_delta(_spot_bids, int_data, SPOT_ORDER_SIZE)
		k += 2

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated


func _add_orders_delta(target: Dictionary[int, PackedInt64Array], int_data: PackedInt64Array,
		order_size: int) -> void:
	var int_offset := _sync.int_offset
	var upserts_count := int_data[int_offset]
	int_offset += 1
	var i := 0
	while i < upserts_count:
		var order: PackedInt64Array
		order.resize(order_size)
		for j in order_size:
			order[j] = int_data[int_offset + j]
		int_offset += order_size
		target[order[0]] = order
		i += 1
	var removes_count := int_data[int_offset]
	int_offset += 1
	i = 0
	while i < removes_count:
		var id := int_data[int_offset]
		int_offset += 1
		target.erase(id)
		i += 1
	_sync.int_offset = int_offset
