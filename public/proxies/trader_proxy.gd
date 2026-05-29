# trader_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
@abstract
class_name TraderProxy
extends Proxy

## [TraderProxy] buys and sells resources for a specific [FacilityProxy].
##
## A trader is paired 1-to-1 with a facility and trades on its behalf via the
## [BrokerProxy] at the facility's body.
##
## To modify AI, see [BaseAI] and the [code]*_base_ai.gd[/code] files.
##
## WARNING: Lives on the proxy thread. Containers and many methods are not
## threadsafe; accessing non-container properties is safe.

var trader_id := -1  ## Index in [member ProxyBus.trader_proxies].
var facility: FacilityProxy  ## Owning [FacilityProxy]. Immutable after init.
var facility_id := -1  ## [member FacilityProxy.facility_id] of [member facility].
var broker: BrokerProxy  ## Immutable after init. Lives on markets thread!
var broker_id := -1  ## [member BrokerProxy.broker_id] of [member broker].
var market: MarketProxy  ## May change at runtime. Lives on markets thread!
var market_id := -1  ## [member MarketProxy.market_id] of [member market].

## Memory of spot ask totals (unit quantity per resource).
var _spot_ask_totals: PackedInt64Array
## Memory of spot bid totals (unit quantity per resource).
var _spot_bid_totals: PackedInt64Array
## Memory of last known spot ask price for each resource. This will be THE
## resource ask price if trader AI only has one ask per resource at a time.
var _spot_ask_prices: PackedInt64Array
## Memory of last known spot bid price for each resource. This will be THE
## resource bid price if trader AI only has one bid per resource at a time.
var _spot_bid_prices: PackedInt64Array
## Memory of last known spot ask_id for each resource. This will be THE
## resource ask_id if trader AI only has one ask per resource at a time.
var _spot_ask_ids: PackedInt64Array
## Memory of last known spot bid_id for each resource. This will be THE
## resource bid_id if trader AI only has one bid per resource at a time.
var _spot_bid_ids: PackedInt64Array


# ************************* VIRTUAL & IMPLEMENTATION **************************

func _init() -> void:
	const ENTITY_TRADER := Proxy.EntityType.ENTITY_TRADER
	super()
	entity_type = ENTITY_TRADER
	persist.append(&"_spot_ask_totals")
	persist.append(&"_spot_bid_totals")
	var n_resources: int = _table_n_rows[&"resources"]
	_spot_ask_totals.resize(n_resources)
	_spot_bid_totals.resize(n_resources)
	_spot_ask_prices.resize(n_resources)
	_spot_bid_prices.resize(n_resources)
	_spot_ask_ids.resize(n_resources)
	_spot_bid_ids.resize(n_resources)
	_spot_ask_ids.fill(-1)
	_spot_bid_ids.fill(-1)


func _clear_for_destruction() -> void:
	# Breaks the FacilityProxy.trader ↔ TraderProxy.facility 2-cycle.
	facility = null
	broker = null
	market = null
	ai = null


# ***************************** THREAD-SAFE READ ******************************

## Returns this trader's [MarketProxy]. Mutable but always exists after init.
@warning_ignore("shadowed_variable")
func get_market(_player_id: int) -> MarketProxy:
	return market


# ******************************** AI METHODS *********************************
# Call on proxy thread. Concrete implementations live on TraderSvrProxy.

## Adds a spot sell order. [param unit_quantity] and [param unit_price] are
## with respect to trade unit. [param expiration] is epoch day.
@abstract func _spot_ask(_resource_type: int, _unit_quantity: int, _unit_price: int, _expiration: int) -> void


## Removes a spot sell order if not processed already.
@abstract func _cancel_spot_ask(_ask_id: int) -> void


## Adds a spot buy order. [param unit_quantity] and [param unit_price] are
## with respect to trade unit. [param expiration] is epoch day.
@abstract func _spot_bid(_resource_type: int, _unit_quantity: int, _unit_price: int, _expiration: int) -> void


## Removes a spot buy order if not processed already.
@abstract func _cancel_spot_bid(_bid_id: int) -> void


# *************************** INCOMING MARKET CALLS ***************************

func _update_ask(data: Array) -> void:
	const BOOKED := TradeOrderStatus.BOOKED
	const PARTIALLY_FILLED := TradeOrderStatus.PARTIALLY_FILLED
	var resource_type: int = data[0]
	var ask_id: int = data[3]
	var ask_status: TradeOrderStatus = data[4]
	if ask_status == BOOKED:
		_spot_ask_ids[resource_type] = ask_id
		return
	var unit_quantity: int = data[1]
	#var unit_price: int = data[2]
	_spot_ask_totals[resource_type] -= unit_quantity
	if ask_status != PARTIALLY_FILLED and ask_id == _spot_ask_ids[resource_type]:
		_spot_ask_ids[resource_type] = -1
		_spot_ask_prices[resource_type] = 0


func _update_bid(data: Array) -> void:
	const BOOKED := TradeOrderStatus.BOOKED
	const PARTIALLY_FILLED := TradeOrderStatus.PARTIALLY_FILLED
	var resource_type: int = data[0]
	var bid_id: int = data[3]
	var bid_status: TradeOrderStatus = data[4]
	if bid_status == BOOKED:
		_spot_bid_ids[resource_type] = bid_id
		return
	var unit_quantity: int = data[1]
	#var unit_price: int = data[2]
	_spot_bid_totals[resource_type] -= unit_quantity
	if bid_status != PARTIALLY_FILLED and bid_id == _spot_bid_ids[resource_type]:
		_spot_bid_ids[resource_type] = -1
		_spot_bid_prices[resource_type] = 0
