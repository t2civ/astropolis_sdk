# proxy_bus.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ProxyBus
extends RefCounted

## Public registry bus for the proxy thread. Holds the proxy lookup arrays
## and the registry signal.
##
## Sync signals and outgoing queues are on [code]SvrProxyBus[/code]
## (nonpublic).


## Emitted on the proxy thread when a new [Proxy] joins the registry.
signal proxy_added(proxy: Proxy)

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
