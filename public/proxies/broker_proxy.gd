# broker_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name BrokerProxy
extends Proxy

## Provides appropriate spot [MarketProxy] on request, lists futures contracts,
## and routes futures orders to an appropriate [MarketProxy].
##
## A [BrokerProxy] is created at a [BodyProxy] when it gains its first
## [FacilityProxy].[br][br]
##
## Server-side Broker pushes changes to [BrokerProxy]. Data flows
## server -> proxy only.[br][br]
##
## Warning! This object lives and dies on the proxy thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.

const MAX_MARKETS_PER_BODY := 5 ## Must match Broker.MAX_MARKETS_PER_BODY.

var broker_id := -1  ## Index into [member ProxyBus.broker_proxies].
var body: BodyProxy  ## Hosting [BodyProxy]. Immutable post-init.
var body_name: StringName  ## Name of the hosting body.
## Spot [MarketProxy]s at this Broker's body, indexed by routing slot;
## slot 0 is the default.
var markets: Array[MarketProxy]

# inited identitifiers resolved later
var _market_names: PackedStringArray



func _init() -> void:
	const ENTITY_BROKER := Proxy.EntityType.ENTITY_BROKER
	super()
	entity_type = ENTITY_BROKER
	markets.resize(MAX_MARKETS_PER_BODY)


func _clear_for_destruction() -> void:
	body = null
	for i in MAX_MARKETS_PER_BODY:
		markets[i] = null


# *****************************************************************************
# proxy API


## Returns the spot [MarketProxy] for [param _player_id]. Thread-safe.
func get_market(_player_id: int) -> MarketProxy:
	return markets[0]


# *****************************************************************************
# sync - DON'T MODIFY!

func set_network_init(data: Array) -> void:
	broker_id = data[2]
	name = data[3]
	gui_name = data[4]
	body_name = data[5]
	_market_names = data[6]


func process_ai_init() -> void:
	if !body:
		body = proxy_bus.proxies_by_name[body_name]
	for i in MAX_MARKETS_PER_BODY:
		var market_name := _market_names[i]
		if !markets[i] and market_name:
			markets[i] = proxy_bus.proxies_by_name[StringName(market_name)]


func _sync_server_dirty(data: Array) -> void:
	const DIRTY_BROKER := Proxy.DirtyFlags.DIRTY_BROKER
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]

	if dirty & DIRTY_BROKER:
		var string_data: PackedStringArray = data[3]
		for i in MAX_MARKETS_PER_BODY:
			var market_name := string_data[i]
			markets[i] = proxy_bus.proxies_by_name[StringName(market_name)] if market_name else null

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter()
