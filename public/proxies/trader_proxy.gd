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
## Warning! This object lives and dies on the AI thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.


## All [TraderProxy] instances, indexed by [member trader_id].
static var trader_proxies: Array[TraderProxy] = []


var trader_id := -1  ## Index in [member trader_proxies].
var facility: FacilityProxy  ## Owning [FacilityProxy]. Immutable after init.
var facility_id := -1  ## [member FacilityProxy.facility_id] of [member facility].
var broker: BrokerProxy  ## Immutable after init. Lives on markets thread!
var broker_id := -1  ## [member BrokerProxy.broker_id] of [member broker].
var market: MarketProxy  ## May change at runtime. Lives on markets thread!
var market_id := -1  ## [member MarketProxy.market_id] of [member market].



func _init() -> void:
	const ENTITY_TRADER := Proxy.EntityType.ENTITY_TRADER
	super()
	entity_type = ENTITY_TRADER


func _clear_circular_references() -> void:
	# Breaks the FacilityProxy.trader ↔ TraderProxy.facility 2-cycle.
	facility = null
	broker = null
	market = null


# *****************************************************************************
# proxy API

## Returns this trader's spot [MarketProxy], or null if not yet set.
## [param _player_id] is unused for direct-routed traders.
func get_market(_player_id: int) -> MarketProxy:
	return market


# *****************************************************************************
# sync from server

func set_network_init(data: Array) -> void:
	trader_id = data[2]
	name = data[3]
	facility_id = data[4]
	facility = FacilityProxy.facility_proxies[facility_id]
	assert(facility)
	facility.trader = self
	facility.trader_id = trader_id
	broker_id = data[5]
	broker = BrokerProxy.broker_proxies[broker_id]
	assert(broker)
	market_id = data[6]
	market = MarketProxy.market_proxies[market_id]
	assert(market)


func sync_server_dirty(data: Array) -> void:
	const DIRTY_TRADER := Proxy.DirtyFlags.DIRTY_TRADER
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]

	if dirty & DIRTY_TRADER:
		market_id = int_data[1]
		market = MarketProxy.market_proxies[market_id]
		assert(market)

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated
