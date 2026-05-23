# trader_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name TraderProxy
extends Proxy

## [TraderProxy] buys and sells resources for a specific [FacilityProxy].
##
## A trader is paired 1-to-1 with a facility and trades on its behalf via the
## [BrokerProxy] at the facility's body. Server-side Trader pushes changes
## to [TraderProxy].
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## To modify AI, see comments in '_base_ai.gd' files.
##
## Warning! This object lives and dies on the proxy thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.


var trader_id := -1  ## Index in [member ProxyBus.trader_proxies].
var facility: FacilityProxy  ## Owning [FacilityProxy]. Immutable after init.
var facility_id := -1  ## [member FacilityProxy.facility_id] of [member facility].
var broker: BrokerProxy  ## Immutable after init. Lives on markets thread!
var broker_id := -1  ## [member BrokerProxy.broker_id] of [member broker].
var market: MarketProxy  ## May change at runtime. Lives on markets thread!
var market_id := -1  ## [member MarketProxy.market_id] of [member market].


# ************************* VIRTUAL & IMPLIMENTATION **************************

func _init() -> void:
	const ENTITY_TRADER := Proxy.EntityType.ENTITY_TRADER
	super()
	entity_type = ENTITY_TRADER


func _clear_for_destruction() -> void:
	# Breaks the FacilityProxy.trader ↔ TraderProxy.facility 2-cycle.
	facility = null
	broker = null
	market = null


func set_network_init(data: Array) -> void:
	trader_id = data[2]
	name = data[3]
	facility_id = data[4]
	facility = proxy_bus.facility_proxies[facility_id]
	assert(facility)
	facility.trader = self
	facility.trader_id = trader_id
	broker_id = data[5]
	broker = proxy_bus.broker_proxies[broker_id]
	assert(broker)
	market_id = data[6]
	market = proxy_bus.market_proxies[market_id]
	assert(market)


func _sync_server_dirty(data: Array) -> void:
	const DIRTY_TRADER := Proxy.DirtyFlags.DIRTY_TRADER
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]

	if dirty & DIRTY_TRADER:
		market_id = int_data[1]
		market = proxy_bus.market_proxies[market_id]
		assert(market)

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated


# ***************************** THREAD-SAFE READ ******************************

## Returns this trader's [MarketProxy]. Mutable but always exists after init.
func get_market(_player_id: int) -> MarketProxy:
	return market



# ******************************** AI METHODS *********************************
# Call on proxy thread.

## Adds a spot sell order. [param unit_quantity] and [param unit_price] are with
## respect to trade unit. [expiration] is epoch day.
func _spot_ask(resource_type: int, unit_quantity: int, unit_price: int, expiration: int) -> void:
	const SPOT_ASK := ProxyServerMethods.SPOT_ASK
	_send_to_market(SPOT_ASK, [resource_type, unit_quantity, unit_price, expiration, trader_id])


## Removes a spot sell order if not processed already.
func _cancel_spot_ask(ask_id: int) -> void:
	const CANCEL_SPOT_ASK := ProxyServerMethods.CANCEL_SPOT_ASK
	_send_to_market(CANCEL_SPOT_ASK, [ask_id, trader_id])


## Adds a spot buy order. [param unit_quantity] and [param unit_price] are with
## respect to trade unit. [expiration] is epoch day.
func _spot_bid(resource_type: int, unit_quantity: int, unit_price: int, expiration: int) -> void:
	const SPOT_BID := ProxyServerMethods.SPOT_BID
	_send_to_market(SPOT_BID, [resource_type, unit_quantity, unit_price, expiration, trader_id])


## Removes a spot buy order if not processed already.
func _cancel_spot_bid(bid_id: int) -> void:
	const CANCEL_SPOT_BID := ProxyServerMethods.CANCEL_SPOT_BID
	_send_to_market(CANCEL_SPOT_BID, [bid_id, trader_id])


# *************************** INTERNAL PRIVATE ********************************
# Don't override!

func _send_to_market(method_id: int, data: Array) -> void:
	const ENTITY_MARKET := EntityType.ENTITY_MARKET
	var address := market_id << 16 | method_id << 8 | ENTITY_MARKET
	data.append(address)
	proxy_bus.proxy_markets_messages.append(data)
