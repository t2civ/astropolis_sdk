# proxy_bus.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ProxyBus
extends RefCounted

## Signal and data bus for the proxy thread.
##
## Signals emit and data containers change on the proxy thread, or possibly
## main thread if [method IVStateManager.is_threads_stopped].


## Emitted on the proxy thread when a new [Proxy] joins the registry.
signal proxy_added(proxy: Proxy)

## Emitted on the proxy thread when a [Proxy] reports a state change. The
## payload is consumed by sync routines on the receiver side.
signal proxy_changed(entity_type: int, entity_id: int, data: Array)

## Emitted when player ownership changes. FIXME — added for NetworkLobby;
## not hooked up anywhere else yet.
signal player_owner_changed(fixme: Variant)


# Class-level config (set by preinitializer; no bus instance required).
static var verbose := false ## Enable verbose proxy logging.
static var verbose2 := false ## Enable extra-verbose proxy logging.


# ProxyServer maintains (cleared at procedural teardown).
var proxies: Array[Proxy] ## All [Proxy] instances indexed by proxy_id; nulls possible.
var proxies_by_name: Dictionary[StringName, Proxy] ## All proxies keyed by name.
var facility_proxies: Array[FacilityProxy] ## [FacilityProxy]s indexed by facility_id; nulls possible.
var body_proxies: Array[BodyProxy] ## [BodyProxy]s indexed by body_id; nulls possible.
var player_proxies: Array[PlayerProxy] ## [PlayerProxy]s indexed by player_id; no nulls.
var join_proxies: Array[JoinProxy] ## [JoinProxy]s indexed by join_id; nulls possible.
var trader_proxies: Array[TraderProxy] ## [TraderProxy]s indexed by trader_id; nulls possible.
var market_proxies: Array[MarketProxy] ## [MarketProxy]s indexed by market_id; nulls possible.
var broker_proxies: Array[BrokerProxy] ## [BrokerProxy]s indexed by broker_id; nulls possible.

var proxy_markets_messages: Array[Array] = [] ## Outgoing proxy->markets queue.
