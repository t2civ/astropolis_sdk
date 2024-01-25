# metaverse.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name Metaverse
extends NetRef

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# TODO: Make interface component w/out server dirty flags & delta accumulators


enum { # _dirty
	DIRTY_COMPUTATIONS = 1,
	DIRTY_DIVERSITY_MODEL = 1 << 1,
}

# save/load persistence for server only
const PERSIST_PROPERTIES2: Array[StringName] = [
	&"_computations",
	&"_delta_computations",
	&"_diversity_model",
	&"_delta_diversity_model",
]

var _computations := 0.0
var _delta_computations := 0.0
var _diversity_model: Dictionary # see static/diversity.gd
var _delta_diversity_model: Dictionary

# TODO: histories including information using get_development_information()



func _init(is_new := false) -> void:
	if !is_new: # loaded game
		return
	_diversity_model = {}
 
# ********************************** READ *************************************
# NOT all threadsafe!

func get_computations() -> float:
	return _computations + _delta_computations


func get_development_information() -> float:
	# NOT THREADSAFE !!!!
	return diversity.get_shannon_entropy_2(_diversity_model, _delta_diversity_model) # in 'bits'



# ****************************** SERVER MODIFY ********************************

func change_diversity_model(key: int, change: float) -> void:
	diversity.change_model(_delta_diversity_model, key, change)
	assert(_debug_assert_diversity_model_change(_diversity_model, _delta_diversity_model, key))
	_dirty |= DIRTY_DIVERSITY_MODEL


# ********************************** SYNC *************************************


func take_dirty(data: Array) -> void:
	# save delta in data, apply & zero delta, reset dirty flags
	
	_int_data = data[1]
	_float_data = data[2]
	
	_int_data.append(_dirty)
	if _dirty & DIRTY_COMPUTATIONS:
		_float_data.append(_delta_computations)
		_computations += _delta_computations
		_delta_computations = 0.0
	if _dirty & DIRTY_DIVERSITY_MODEL:
		_take_diversity_model_delta(_diversity_model, _delta_diversity_model)
	
	_dirty = 0


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
	_dirty |= dirty
	
	if dirty & DIRTY_COMPUTATIONS:
		_delta_computations += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_DIVERSITY_MODEL:
		_add_diversity_model_delta(_delta_diversity_model)


