# ai_global.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends Node

# Singleton "AIGlobal".
#
# Signals are on the AI thread.
#
# To call Main thread from AI thread, use call_deferred().

# emit on ai thread only!
signal interface_added(interface: Interface)
signal interface_changed(entity_type: int, entity_id: int, data: Array)

signal player_owner_changed(fixme: Variant) # FIXME - added for NetworkLobby; not hooked up anywhere else


var verbose := false
var verbose2 := false
var is_autoplay := false

var is_multiplayer_server := false
var is_multiplayer_client := false

var local_player_name := &"PLAYER_NASA"



