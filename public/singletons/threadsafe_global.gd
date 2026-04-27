# threadsafe_global.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends Node

# Singleton "ThreadsafeGlobal".
#
# This global provides access to threadsafe data and API.
# 
# Use [method is_main_thread_access] in asserts or code that needs to know
# whether it is safe to bypass thread machinery (server channels, mutex locks,
# etc.), e.g., during game start.

# settings
var total_biodiversity_pool := 25336.0 * IVUnits.SPP
var total_information_pool := 6.4e22 * IVUnits.BIT
var start_prices_body := &"PLANET_EARTH" # TODO: bodies_resources_prices.tsv

# game
var local_player_name := &"PLAYER_NASA"
var home_facility_name := &"FACILITY_PLANET_EARTH_PLAYER_NASA"

# private
var _main_thread_access := true


# *****************************************************************************

func _ready() -> void:
	IVStateManager.simulator_started.connect(_on_simulator_started)
	IVStateManager.procedural_nodes_freed.connect(_on_procedural_nodes_freed)


func is_main_thread_access() -> bool:
	# True when worker threads are idle and shared state is freely mutable from
	# the main thread.
	return _main_thread_access


func _on_simulator_started() -> void:
	_main_thread_access = false


func _on_procedural_nodes_freed() -> void:
	_main_thread_access = true
