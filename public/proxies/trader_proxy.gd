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

# Cached in set_network_init.
var _broker: BrokerProxy
var _player_id := -1



func _init() -> void:
	const ENTITY_TRADER := Proxy.EntityType.ENTITY_TRADER
	super()
	entity_type = ENTITY_TRADER


func _clear_circular_references() -> void:
	# Breaks the FacilityProxy.trader ↔ TraderProxy.facility 2-cycle.
	facility = null
	_broker = null


# *****************************************************************************
# proxy API

## Returns the [BrokerProxy] at this trader's body.
func get_broker() -> BrokerProxy:
	return _broker


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
	_broker = facility._broker
	_player_id = facility._player_id


func sync_server_dirty(data: Array) -> void:
	var int_data: PackedInt64Array = data[1]

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated
