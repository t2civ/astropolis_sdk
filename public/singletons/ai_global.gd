# ai_global.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
extends Node

# Singleton "AIGlobal".
#
# Signals are on the AI thread.
#
# To call Main thread from AI thread, use call_deferred().

# emit on ai thread only!
signal interface_added(interface)
signal interface_changed(entity_type, entity_id, data)

signal player_owner_changed(fixme) # FIXME - added for NetworkLobby; not hooked up anywhere else


var verbose := false
var verbose2 := false
var is_autoplay := false

var is_multiplayer_server := false
var is_multiplayer_client := false

var local_player_name := &"PLAYER_NASA"



