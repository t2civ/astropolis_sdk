# cyberspace_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name CyberspaceNet
extends NetComponent

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.


enum {
	DIRTY_COMPUTATIONS = 1,
	DIRTY_INFORMATION = 1 << 1,
}

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
	# apply delta & dirty flags
	_int_data = data[1]
	_float_data = data[2]
	_int_offset = int_offset
	_float_offset = float_offset
	
	var svr_qtr := _int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	var dirty := _int_data[_int_offset]
	_int_offset += 1
	
	if dirty & DIRTY_COMPUTATIONS:
		_computations += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_INFORMATION:
		# WARNGING: _int_offset is invalid from server data!
		_information += _float_data[_float_offset]
		_float_offset += 1

