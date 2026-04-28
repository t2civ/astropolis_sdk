# threadsafe_global.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends Node

## Threadsafe autoload (registered as [code]ThreadsafeGlobal[/code]) for
## settings, game-start data, and [method is_main_thread_access].
##
## Use [method is_main_thread_access] in asserts or code that needs to know
## whether it is safe to bypass thread machinery (server channels, mutex
## locks, etc.) — e.g., during game start.


# settings
var total_biodiversity_pool := 25336.0 * IVUnits.SPP  ## Global biodiversity pool (species count units).
var total_information_pool := 6.4e22 * IVUnits.BIT  ## Global information pool (bit units).
## Body whose prices seed startup pricing. TODO: replace with
## [code]bodies_resources_prices.tsv[/code].
var start_prices_body := &"PLANET_EARTH"

# game
var local_player_name := &"PLAYER_NASA"  ## Name of the local player at game start.
var home_facility_name := &"FACILITY_PLANET_EARTH_PLAYER_NASA"  ## Name of the local player's home facility.

# private
var _main_thread_access := true


# *****************************************************************************

func _ready() -> void:
	IVStateManager.simulator_started.connect(_on_simulator_started)
	IVStateManager.procedural_nodes_freed.connect(_on_procedural_nodes_freed)


## Returns true when worker threads are idle and shared state is freely
## mutable from the main thread (during game start and after simulator stop).
func is_main_thread_access() -> bool:
	return _main_thread_access


func _on_simulator_started() -> void:
	_main_thread_access = false


func _on_procedural_nodes_freed() -> void:
	_main_thread_access = true
