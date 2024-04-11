# biome_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name BiomeNet
extends NetComponent

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.


enum {
	DIRTY_BIOPRODUCTIVITY = 1,
	DIRTY_BIOMASS = 1 << 1,
	DIRTY_DIVERSITY_MODEL = 1 << 2,
}


var _bioproductivity := 0.0
var _biomass := 0.0
var _diversity_model: Dictionary # see static/diversity.gd


# TODO: histories for all dev stats


func _init(is_new := false) -> void:
	if !is_new: # game load
		return
	_diversity_model = {}

# ********************************** READ *************************************
# NOT all threadsafe!

func get_bioproductivity() -> float:
	return _bioproductivity


func get_biomass() -> float:
	return _biomass


func get_development_biodiversity() -> float:
	# NOT THREADSAFE !!!!
	var entropy := diversity.get_shannon_entropy(_diversity_model, false)
	if entropy == 0.0:
		return 0.0 # no species; not technically correct but intuitive
	return exp(entropy)


func get_species_richness() -> float:
	# NOT THREADSAFE !!!!
	# total number of species
	return diversity.get_species_richness(_diversity_model)
 

# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_bioproductivity = data[1]
	_biomass = data[2]
	_diversity_model = data[3]


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
	
	if dirty & DIRTY_BIOPRODUCTIVITY:
		_bioproductivity += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_BIOMASS:
		_biomass += _float_data[_float_offset]
		_float_offset += 1
	if dirty & DIRTY_DIVERSITY_MODEL:
		_add_diversity_model_delta(_diversity_model)


