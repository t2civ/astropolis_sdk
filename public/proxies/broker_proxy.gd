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
## [FacilityProxy]. [member spot_exchanges] holds the spot [ExchangeProxy]s
## at this Broker's body; use [method get_spot_exchange] to pick.[br][br]
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


const N_MAX_EXCHANGES := 5 ## Must match Broker.N_MAX_EXCHANGES.


## All [BrokerProxy] instances, indexed by [member broker_id].
static var broker_proxies: Array[BrokerProxy] = []


var broker_id := -1  ## Index into [member broker_proxies].
## Hosting [BodyProxy]. Immutable post-init; resolved in
## [method process_ai_init] (deferred because [code]MktsAI[/code] drains
## before [code]OpsAI[/code] does).
var body: BodyProxy
var body_name: StringName  ## Name of the hosting body.
## Spot [ExchangeProxy]s at this Broker's body, indexed by routing slot;
## slot 0 is the default. Resolved in [method process_ai_init] (deferred
## because broker init drains from [code]MktsAI[/code] before exchange init).
var spot_exchanges: Array[ExchangeProxy]
var _spot_exchange_names: PackedStringArray



func _init() -> void:
	const ENTITY_BROKER := Proxy.EntityType.ENTITY_BROKER
	super()
	entity_type = ENTITY_BROKER
	spot_exchanges.resize(N_MAX_EXCHANGES)


func _clear_circular_references() -> void:
	body = null
	for i in N_MAX_EXCHANGES:
		spot_exchanges[i] = null


# *****************************************************************************
# proxy API


## Returns the spot [ExchangeProxy] for [param _player_id]. Thread-safe.
@warning_ignore("unused_parameter")
func get_spot_exchange(_player_id: int) -> ExchangeProxy:
	return spot_exchanges[0]


# *****************************************************************************
# sync - DON'T MODIFY!

func set_network_init(data: Array) -> void:
	broker_id = data[2]
	name = data[3]
	gui_name = data[4]
	body_name = data[5]
	# body and spot_exchanges are resolved in process_ai_init — their
	# proxies may not yet be in proxies_by_name because MktsAI is drained
	# before OpsAI, and broker init messages drain before exchange ones.
	_spot_exchange_names = data[6]


func process_ai_init() -> void:
	if !body:
		body = proxies_by_name[body_name]
	for i in N_MAX_EXCHANGES:
		var exchange_name := _spot_exchange_names[i]
		if !spot_exchanges[i] and exchange_name:
			spot_exchanges[i] = proxies_by_name[StringName(exchange_name)]


func sync_server_dirty(data: Array) -> void:
	const DIRTY_BROKER := Proxy.DirtyFlags.DIRTY_BROKER
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]

	if dirty & DIRTY_BROKER:
		var string_data: PackedStringArray = data[3]
		for i in N_MAX_EXCHANGES:
			var exchange_name := string_data[i]
			spot_exchanges[i] = proxies_by_name[StringName(exchange_name)] if exchange_name else null

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter()
