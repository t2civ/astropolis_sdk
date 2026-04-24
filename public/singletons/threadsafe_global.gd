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
# This global provides access to threadsafe data. Note that most items here are
# localized to base classes (Interface, NetRef, etc.) for quicker access.


static var tables_aux: Dictionary[StringName, Variant] = {} # see public_preinitializer.gd

# Startup phase — readable from any thread. Names the two regimes of the
# game's lifecycle so cross-thread shared-state mutations can assert the
# regime they assume.
#
# Phase is written only from the main thread (from the IVStateManager
# signal handlers below); it is read from any thread — a scalar int
# read/write is safe without a lock per Godot's thread-safety rules.
#
# Assertion pattern for shared-state structural mutations that are only
# safe when worker threads are idle:
#
#   @warning_ignore_start("unsafe_property_access")  # Godot 4.6 autoload
#   assert(ThreadsafeGlobal.startup_phase == ThreadsafeGlobal.PHASE_SETUP,
#       "<what> requires SETUP phase")
#   @warning_ignore_restore("unsafe_property_access")
#
# The warning-ignore pair is required because Godot 4.6's LSP does not
# resolve consts / vars accessed through this autoload name from function
# bodies, even though the access is valid at runtime.

const PHASE_SETUP := 0    # Main-thread-only; shared state freely mutable.
const PHASE_RUNNING := 1  # Worker threads active; shared mutation needs
						  # a channel, snapshot-and-swap, or a mutex.

signal startup_phase_changed(new_phase: int)

var startup_phase := PHASE_SETUP

# settings
var total_biodiversity_pool := 25336.0 * IVUnits.SPP
var total_information_pool := 6.4e22 * IVUnits.BIT
var start_prices_body := &"PLANET_EARTH" # TODO: bodies_resources_prices.tsv


# game
var local_player_name := &"PLAYER_NASA"
var home_facility_name := &"FACILITY_PLANET_EARTH_PLAYER_NASA"


# *****************************************************************************

func _ready() -> void:
	IVStateManager.simulator_started.connect(_on_simulator_started)
	IVStateManager.about_to_free_procedural_nodes.connect(_on_about_to_free_procedural_nodes)


func _on_simulator_started() -> void:
	_set_phase(PHASE_RUNNING)


func _on_about_to_free_procedural_nodes() -> void:
	# No post-teardown signal exists (next signals are game-load / exit /
	# quit), so flip back to SETUP here. ThreadsafeGlobal's autoload order
	# puts this handler ahead of MainThreadGlobal._clear and downstream
	# server _clear_procedural handlers, so any setup-phase assertions made
	# during those clears see SETUP.
	_set_phase(PHASE_SETUP)


func _set_phase(new_phase: int) -> void:
	startup_phase = new_phase
	startup_phase_changed.emit(new_phase)
