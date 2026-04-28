# ai_bus.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name AIBus
extends RefCounted

## Cross-thread signal bus for AI-thread interface events. Shared singleton
## referenced by [member Interface.ai_bus].
##
## Listeners receive these signals on the AI thread. To call main-thread code
## from a handler, use [code]call_deferred()[/code].


## Emitted on the AI thread when a new [Interface] joins the registry.
signal interface_added(interface: Interface)

## Emitted on the AI thread when an [Interface] reports a state change. The
## payload is consumed by sync routines on the receiver side.
signal interface_changed(entity_type: int, entity_id: int, data: Array)

## Emitted when player ownership changes. FIXME — added for NetworkLobby;
## not hooked up anywhere else yet.
signal player_owner_changed(fixme: Variant)



static var verbose := false  ## Enable verbose AI logging.
static var verbose2 := false  ## Enable extra-verbose AI logging.
static var is_autoplay := false  ## True while the local player has handed control to AI.

static var is_multiplayer_server := false  ## True if this peer is the multiplayer server.
static var is_multiplayer_client := false  ## True if this peer is a multiplayer client.
