# cyberspace_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name CyberspaceNet
extends RefCounted

## Net-synced cyberspace component held by [FacilityInterface],
## [PlayerInterface], [BodyInterface], or [JoinInterface].
##
## Holds computation rate and information. The underlying entropy model is
## server-only; only the scalar [member _information] value flows here.
## Architecturally parallel to [BiomeNet].
##
## Server-side Cyberspace pushes changes to [CyberspaceNet] via sync.
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## Warning! Like [Interface], this object is touched on the AI thread.
## Containers and many methods are not threadsafe; accessing non-container
## properties is safe.


## Bit flags marking which scalar fields of this component are dirty for sync.
enum {
	DIRTY_COMPUTATION_RATE = 1,
	DIRTY_INFORMATION = 1 << 1,
}

## Quarterly clock at last sync, as [code]year * 4 + (quarter - 1)[/code].
var run_qtr := -1

var _computation_rate := 0.0
var _information := 1.0 # min 1.0


func _init(is_new := false) -> void:
	if !is_new: # loaded game
		return

# ********************************** READ *************************************
# NOT all threadsafe!

## Returns current computation rate.
func get_computation_rate() -> float:
	return _computation_rate


## Returns current information. Minimum is 1.0.
func get_information() -> float:
	return _information

# ********************************** SYNC *************************************

## Initializes this component from the server-supplied init payload.
func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_computation_rate = data[1]
	_information = data[2]


## Applies a server-supplied dirty payload, updating fields whose dirty flags
## are set.
func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]
	
	var svr_qtr := int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	var dirty := int_data[int_offset]
	int_offset += 1
	
	if dirty & DIRTY_COMPUTATION_RATE:
		_computation_rate += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_INFORMATION:
		_information += float_data[float_offset]
