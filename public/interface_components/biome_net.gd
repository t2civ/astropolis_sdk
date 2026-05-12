# biome_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name BiomeNet
extends RefCounted

## Net-synced biome component held by [FacilityInterface], [PlayerInterface],
## [BodyInterface], or [JoinInterface].
##
## Holds bioproductivity, biomass, and biodiversity. The underlying
## species-presence entropy model is server-only; only the scalar
## [member _biodiversity] value flows here.
##
## Server-side Biome pushes changes to [BiomeNet] via sync.
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
	DIRTY_BIOPRODUCTIVITY = 1,
	DIRTY_BIOMASS = 1 << 1,
	DIRTY_BIODIVERSITY = 1 << 2,
}


## Quarterly clock at last sync, as [code]year * 4 + (quarter - 1)[/code].
var run_qtr := -1
var _bioproductivity := 0.0
var _biomass := 0.0
var _biodiversity := 1.0 # min 1.0



func _init(is_new := false) -> void:
	if !is_new: # game load
		return

# ********************************** READ *************************************
# threadsafe

## Returns current bioproductivity.
func get_bioproductivity() -> float:
	return _bioproductivity


## Returns current biomass.
func get_biomass() -> float:
	return _biomass


## Returns current biodiversity. Minimum is 1.0; check population separately
## if you want 0.0.
func get_biodiversity() -> float:
	return _biodiversity


# ********************************** SYNC *************************************

## Initializes this component from the server-supplied init payload.
func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_bioproductivity = data[1]
	_biomass = data[2]
	_biodiversity = data[3]


## Applies a server-supplied dirty payload, updating fields whose dirty flags
## are set.
func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]
	
	var svr_qtr := int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	var dirty := int_data[int_offset]
	int_offset += 1
	
	if dirty & DIRTY_BIOPRODUCTIVITY:
		_bioproductivity += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_BIOMASS:
		_biomass += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_BIODIVERSITY:
		_biodiversity += float_data[float_offset]
