# broker_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
@abstract
class_name BrokerProxy
extends Proxy

## Provides appropriate spot [MarketProxy] on request, lists futures
## contracts, and routes futures orders to an appropriate [MarketProxy].
##
## A [BrokerProxy] is created at a [BodyProxy] when it gains its first
## [FacilityProxy]. Server-side Broker pushes changes; data flow is
## server -> proxy only.
##
## WARNING: Lives on the proxy thread. Containers and many methods are not
## threadsafe; accessing non-container properties is safe.

const MAX_MARKETS_PER_BODY := 5

var broker_id := -1  ## Index into [member ProxyBus.broker_proxies].
var body: BodyProxy  ## Hosting [BodyProxy]. Immutable post-init.
## Spot [MarketProxy]s at this Broker's body, indexed by routing slot;
## slot 0 is the default.
var markets: Array[MarketProxy]


# ************************* VIRTUAL & IMPLEMENTATION **************************

func _init() -> void:
	super()
	markets.resize(MAX_MARKETS_PER_BODY)


func _clear_for_destruction() -> void:
	body = null
	for i in MAX_MARKETS_PER_BODY:
		markets[i] = null


# ********************************* PROXY API *********************************

## Returns the spot [MarketProxy] for [param _player_id]. Thread-safe.
@abstract func get_market(player_id: int) -> MarketProxy
