# cyberspace_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name CyberspaceNet
extends RefCounted

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.


enum {
	DIRTY_COMPUTATIONS = 1,
	DIRTY_INFORMATION = 1 << 1,
}

var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)

var _computations := 0.0
var _information := 1.0 # min 1.0


func _init(is_new := false) -> void:
	if !is_new: # loaded game
		return
 
# ********************************** READ *************************************
# NOT all threadsafe!

func get_computations() -> float:
	return _computations


func get_information() -> float:
	return _information

# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_computations = data[1]
	_information = data[2]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# Changes and sets from the server entity.
	
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]
	
	var svr_qtr := int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	var dirty := int_data[int_offset]
	int_offset += 1
	
	if dirty & DIRTY_COMPUTATIONS:
		_computations += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_INFORMATION:
		_information += float_data[float_offset]

