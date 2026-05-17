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


# immutable post-init
var trader_id := -1  ## Index into [member trader_proxies].
var facility_id := -1  ## [member FacilityProxy.facility_id] this trader belongs to.
var facility: FacilityProxy  ## Owning [FacilityProxy].
var broker: BrokerProxy  ## Set after init. Lives on markets thread!
var market: MarketProxy  ## Set after init. Lives on markets thread!



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
	var broker_name: StringName = data[5]
	if broker_name:
		broker = proxies_by_name[broker_name]
	var market_name: StringName = data[6]
	if market_name:
		market = proxies_by_name[market_name]


func sync_server_dirty(data: Array) -> void:
	const DIRTY_TRADER := Proxy.DirtyFlags.DIRTY_TRADER
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]

	if dirty & DIRTY_TRADER:
		var string_data: PackedStringArray = data[3]
		var broker_name := string_data[0]
		broker = proxies_by_name[StringName(broker_name)] if broker_name else null
		var market_name := string_data[1]
		market = proxies_by_name[StringName(market_name)] if market_name else null

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated
