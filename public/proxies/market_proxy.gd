# market_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
@abstract
class_name MarketProxy
extends Proxy

## Provides resource spot prices and a market for spot and futures trading.
##
## A [BodyProxy] with a [FacilityProxy] always gains a market. At minimum, the
## market provides "spot" prices for relevant resources, determined either
## via spot market trades or by fiat using a market maker functionality.[br][br]
##
## If a body has >1 facilities, the market provides a resource spot market.
## The spot market processes spot orders for within-body, immediate-delivery
## trades only. These orders originate from local [TraderProxy]s only.[br][br]
##
## All trade orders are implemented as "limit orders". Traders can specify a
## "market order", in effect, by specifying a permissive price and near-future
## expiration.[br][br]
##
## Markets also list futures contracts for delivery at the market [member body].
## Futures contracts specify time of delivery (ordinal quarter) of a specific
## resource quantity at a specific facility. They can be traded by anyone (a
## local or remote trader) and are the means for inter-body resource trades.[br][br]
##
## Times, prices, and order quantities are integer "ticks": time in integer
## seconds (assumes [code]IVUnits.SECOND == 1.0[/code]), price in integer USD
## (assumes [code]IVUnits.USD == 1.0[/code]), and order quantity in integer
## "trade units" (specified by [code]trade_unit[/code] in
## [code]resources.tsv[/code]). The API convention provides regular sim
## units in [method get_spot_price] and uses "unit" in the name for
## Market-internal values ([method get_spot_unit_price]).[br][br]
##
## Arrays are indexed by [code]resource_type[/code] unless indicated otherwise.
## A stored value of 0 in any internal "price" variable means N/A or no current
## price (sim-unit getters return 0.0 in that case).
##
## WARNING: Lives on the proxy thread. Resizable containers and associated
## methods are not threadsafe; non-container properties are safe.


const SPOT_ORDER_SIZE := 7
const FUTURES_ORDER_SIZE := 9


static var _is_class_instanced := false
static var _resource_trade_unit_multipliers: PackedFloat64Array # convert trade -> sim


var market_id := -1  ## Index into [member ProxyBus.market_proxies].
var body: BodyProxy ## Body of the spot market and futures contract delivery.

var _spot_prices: PackedInt64Array
var _spot_ask_prices: PackedInt64Array
var _spot_bid_prices: PackedInt64Array
var _spot_volumes: PackedFloat64Array


# ************************* VIRTUAL & IMPLEMENTATION **************************

static func _on_class_instanced() -> void:
	_resource_trade_unit_multipliers = ThreadsafeGlobal.resource_trade_unit_multipliers


func _init() -> void:
	super()
	if !_is_class_instanced:
		_is_class_instanced = true
		_on_class_instanced()


func _clear_for_destruction() -> void:
	body = null


# ********************************* PROXY API *********************************

func has_markets() -> bool:
	return true


func get_market(_player_id: int) -> MarketProxy:
	return self


# ********************************** READ *************************************
# all threadsafe

## Returns the current trade price for [param type] in sim units, or 0.0 if
## no current price.
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


## Returns the Market-internal unit price for [param type], or 0 if no
## current price.
func get_spot_unit_price(type: int) -> int:
	return _spot_prices[type]


## Returns the Market-internal ask unit price for [param type], or 0 if no
## current ask.
func get_spot_ask_unit_price(type: int) -> int:
	return _spot_ask_prices[type]


## Returns the Market-internal bid unit price for [param type], or 0 if no
## current bid.
func get_spot_bid_unit_price(type: int) -> int:
	return _spot_bid_prices[type]


## Returns the trading volume for [param type] in trade units per day, smoothed
## over 7 days.
func get_spot_unit_volume(type: int) -> float:
	return _spot_volumes[type]
