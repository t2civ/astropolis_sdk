# biome.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name Biome
extends NetRef

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# TODO: Make interface component w/out server dirty flags & delta accumulators
#

enum { # _dirty
	DIRTY_BIOPRODUCTIVITY = 1,
	DIRTY_BIOMASS = 1 << 1,
	DIRTY_DIVERSITY_MODEL = 1 << 2,
}


# save/load persistence for server only
const PERSIST_PROPERTIES2: Array[StringName] = [
	&"_bioproductivity",
	&"_delta_bioproductivity",
	&"_biomass",
	&"_delta_biomass",
	&"_diversity_model",
	&"_delta_diversity_model",
]

var _bioproductivity := 0.0
var _delta_bioproductivity := 0.0
var _biomass := 0.0
var _delta_biomass := 0.0
var _diversity_model: Dictionary # see static/diversity.gd
var _delta_diversity_model: Dictionary

# TODO: histories for all dev stats


func _init(is_new := false) -> void:
	if !is_new: # game load
		return
	_diversity_model = {}

# ********************************** READ *************************************
# NOT all threadsafe!

func get_bioproductivity() -> float:
	return _bioproductivity + _delta_bioproductivity


func get_biomass() -> float:
	return _biomass + _delta_biomass


func get_development_biodiversity() -> float:
	# NOT THREADSAFE !!!!
	var entropy := diversity.get_shannon_entropy_2(_diversity_model, _delta_diversity_model, false)
	if entropy == 0.0:
		return 0.0 # no species; not technically correct but intuitive
	return exp(entropy)


func get_species_richness() -> float:
	# NOT THREADSAFE !!!!
	# total number of species
	return diversity.get_species_richness_2(_diversity_model, _delta_diversity_model)
 
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
	if _dirty & DIRTY_BIOPRODUCTIVITY:
		_float_data.append(_delta_bioproductivity)
		_bioproductivity += _delta_bioproductivity
		_delta_bioproductivity = 0.0
	if _dirty & DIRTY_BIOMASS:
		_float_data.append(_delta_biomass)
		_biomass += _delta_biomass
		_delta_biomass = 0.0
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
	
	if dirty & DIRTY_BIOPRODUCTIVITY:
		_delta_bioproductivity += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_BIOMASS:
		_delta_biomass += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_DIVERSITY_MODEL:
		_add_diversity_model_delta(_delta_diversity_model)


