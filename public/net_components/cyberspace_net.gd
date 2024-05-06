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
	DIRTY_ENTROPY_MODEL = 1 << 1,
}


var _computations := 0.0
var _entropy_model: Dictionary # see static/diversity.gd

# TODO: histories including information using get_development_information()


func _init(is_new := false) -> void:
	if !is_new: # loaded game
		return
	_entropy_model = {}
 
# ********************************** READ *************************************
# NOT all threadsafe!

func get_computations() -> float:
	return _computations


func get_development_information() -> float:
	# NOT THREADSAFE !!!!
	return diversity.get_shannon_entropy(_entropy_model) # in 'bits'

# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_computations = data[1]
	_entropy_model = data[2]


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
	if dirty & DIRTY_ENTROPY_MODEL:
		_add_diversity_model_delta(_entropy_model)


