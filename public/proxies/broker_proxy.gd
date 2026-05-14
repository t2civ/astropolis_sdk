# broker_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name BrokerProxy
extends Proxy

## Provides order API for [TraderProxy] and routes orders to an appropriate
## [ExchangeProxy].
##
## A [BrokerProxy] exists at each [BodyProxy] that hosts at least one
## [FacilityProxy]. [member spot_exchange] is the [ExchangeProxy] at
## this Broker's body, or null if the body has only one facility.[br][br]
##
## Server-side Broker pushes changes to [BrokerProxy]. Data flows
## server -> proxy only.[br][br]
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.[br][br]
##
## Warning! This object lives and dies on the AI thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.


## All [BrokerProxy] instances, indexed by [member broker_id].
static var broker_proxies: Array[BrokerProxy] = []


var broker_id := -1  ## Index into [member broker_proxies].
## Hosting [BodyProxy]. Immutable post-init; resolved in
## [method process_ai_init] (deferred because [code]MktsAI[/code] drains
## before [code]OpsAI[/code] does).
var body: BodyProxy
var body_name: StringName  ## Name of the hosting body.
## Spot exchange at this body, or null. Resolved in [method process_ai_init]
## (deferred because broker init messages drain from [code]MktsAI[/code]
## before exchange init messages).
var spot_exchange: ExchangeProxy
var _spot_exchange_name: StringName



func _init() -> void:
	const ENTITY_BROKER := Proxy.EntityType.ENTITY_BROKER
	super()
	entity_type = ENTITY_BROKER


func _clear_circular_references() -> void:
	body = null
	spot_exchange = null


# *****************************************************************************
# proxy API


## Returns the spot [ExchangeProxy] at this Broker's body, or null if the
## body has only one facility.
func get_spot_exchange() -> ExchangeProxy:
	return spot_exchange


# *****************************************************************************
# sync - DON'T MODIFY!

func set_network_init(data: Array) -> void:
	broker_id = data[2]
	name = data[3]
	gui_name = data[4]
	body_name = data[5]
	# body and spot_exchange are resolved in process_ai_init — their
	# proxies may not yet be in proxies_by_name because MktsAI is drained
	# before OpsAI, and broker init messages drain before exchange ones.
	_spot_exchange_name = data[6]


func process_ai_init() -> void:
	if !body:
		body = proxies_by_name[body_name]
	if !spot_exchange and _spot_exchange_name:
		spot_exchange = proxies_by_name[_spot_exchange_name]


func sync_server_dirty(data: Array) -> void:
	const DIRTY_BROKER := Proxy.DirtyFlags.DIRTY_BROKER
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]

	if dirty & DIRTY_BROKER:
		var string_data: PackedStringArray = data[3]
		var spot_exchange_name: String = string_data[0]
		spot_exchange = proxies_by_name[spot_exchange_name] if spot_exchange_name else null

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter()
