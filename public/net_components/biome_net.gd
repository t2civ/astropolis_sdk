# biome_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name BiomeNet
extends RefCounted

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.


enum {
	DIRTY_BIOPRODUCTIVITY = 1,
	DIRTY_BIOMASS = 1 << 1,
	DIRTY_BIODIVERSITY = 1 << 2,
}


var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)
var _bioproductivity := 0.0
var _biomass := 0.0
var _biodiversity := 1.0 # min 1.0



func _init(is_new := false) -> void:
	if !is_new: # game load
		return

# ********************************** READ *************************************
# threadsafe

func get_bioproductivity() -> float:
	return _bioproductivity


func get_biomass() -> float:
	return _biomass


func get_biodiversity() -> float:
	# Minimum here is 1.0. You'll have to do a population test if you want 0.0.
	return _biodiversity


# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_bioproductivity = data[1]
	_biomass = data[2]
	_biodiversity = data[3]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# Changes and sets from the server entity.
	
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
		# WARNGING: int_offset is invalid from server data!
		_biodiversity += float_data[float_offset]

