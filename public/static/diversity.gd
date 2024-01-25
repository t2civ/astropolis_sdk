# diversity.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name Diversity
extends Object

# Static class for methods related to diversity models.
#
# We use 'diversity_model' dictionaries to model species populations (or
# unique information):
#
# In a perfect simulation, we would have a dictionary key for every species
# with dict[key] equal to number of individuals in that species. But that's
# a lot of keys! We approximate this using integer keys that represent
# individual species or groups of species. The last two digits of the key
# (ie, key mod 100) tells us the number of species that the key represents:
#
#   00, -> key represents 1 unique species (value is number of individuals)
#   01, -> key represents 10 unique species (value is number of individuals in each)
#   02, -> key represents 100 unique species
#   ...
#   99, -> key represents 1e99 unique species
#   (Probably all keys will end 0x but just maybe we'll see 1x.)
#
# All diversity_model values are integral floats >= 1.0.
	
const RECIPROCAL_LN2 := 1.0 / log(2.0) # log() is natural logarithm


static func get_diversity_index(model: Dictionary, q := 1.0) -> float:
	# Returns Hill number of order q.
	# https://en.wikipedia.org/wiki/Diversity_index
	#
	# If all species are equally represented, then index = number of species.
	# The purpose of the index is to discount low abundance species (larger
	# values of q give greater discount). The unit of measure is 'species'.
	# 
	# For q = 1, diversity index equals the exponential of the Shannon Entropy
	# calculated in 'natural units' (base e). See get_shannon_entropy() below.
	if model.is_empty():
		return 0.0 # not exactly correct but intuitive
	if q == 1.0:
		return exp(get_shannon_entropy(model, false)) # limit as q -> 1
	var n_individuals := 0.0
	for key: int in model:
		assert(model[key] > 0.0, "'model' has <= 0.0 value")
		var mod100: int = key % 100 # 0, 1, ..., 99
		n_individuals += model[key] * pow(10.0, mod100) # x 1, 10, ..., 1e99 sp
	assert(n_individuals == floor(n_individuals))
	assert(n_individuals > 0.0)
	var summation := 0.0
	for key: int in model:
		var mod100: int = key % 100 # 0, 1, ..., 99
		var p: float = model[key] / n_individuals
		summation += pow(p, q) * pow(10.0, mod100)
	return pow(summation, 1.0 / (1.0 - q))


static func get_shannon_entropy(model: Dictionary, in_bits := true) -> float:
	# The unit of measure is 'bits' (base 2) by default, or 'natural units'
	# (base e) if in_bits == false.
	if model.is_empty():
		return 0.0 # not exactly correct but intuitive
	var n_individuals := 0.0
	for key: int in model:
		assert(model[key] > 0.0, "'model' has <= 0.0 value")
		var mod100: int = key % 100 # 0, 1, ..., 99
		n_individuals += model[key] * pow(10.0, mod100) # x 1, 10, ..., 1e99 sp
	var summation := 0.0 # will be negative
	for key: int in model:
		var mod100: int = key % 100 # 0, 1, ..., 99
		var p: float = model[key] / n_individuals
		summation += p * log(p) * pow(10.0, mod100) # log() is natural logarithm
	if in_bits:
		return -summation * RECIPROCAL_LN2
	return -summation


static func get_shannon_entropy_2(model: Dictionary, delta_model: Dictionary, in_bits := true) -> float:
	# Optimized function for components w/ delta
	# FIXME: delta handling, must modify model before adds
	if model.is_empty() and delta_model.is_empty():
		return 0.0 # not exactly correct but intuitive
	var n_individuals := 0.0
	for key: int in model:
		assert(model[key] > 0.0, "'model' has <= 0.0 value")
		var mod100: int = key % 100 # 0, 1, ..., 99
		n_individuals += model[key] * pow(10.0, mod100) # x 1, 10, ..., 1e99 sp
	for key: int in delta_model:
		assert(delta_model[key] > 0.0 or ((model.has(key) and delta_model[key] >= -model[key])))
		var mod100: int = key % 100 # 0, 1, ..., 99
		n_individuals += delta_model[key] * pow(10.0, mod100) # x 1, 10, ..., 1e99 sp
	assert(n_individuals >= 0.0)
	if n_individuals == 0.0:
		return 0.0 # not exactly correct but intuitive
	var summation := 0.0 # will be negative
	for key: int in model:
		var number: float = model[key]
		if delta_model.has(key):
			number += delta_model[key]
			if number <= 0.0:
				assert(number == 0.0)
				continue
		var mod100: int = key % 100 # 0, 1, ..., 99
		var p: float = number / n_individuals
		summation += p * log(p) * pow(10.0, mod100) # log() is natural logarithm
	for key: int in delta_model:
		if model.has(key):
			continue
		assert(delta_model[key] > 0.0, "'delta_model' has <= 0.0 value for key not in 'model'")
		var mod100: int = key % 100 # 0, 1, ..., 99
		var p: float = delta_model[key] / n_individuals
		summation += p * log(p) * pow(10.0, mod100) # log() is natural logarithm
	if in_bits:
		return -summation * RECIPROCAL_LN2
	return -summation


static func get_species_richness(model: Dictionary) -> float:
	# total number of species
	var species := 0.0
	for key: int in model:
		assert(model[key] > 0.0, "'model' has <= 0.0 value")
		var mod100: int = key % 100 # 0, 1, ..., 99
		species += pow(10.0, mod100) # 1, 10, ..., 1e99 sp
	return species


static func get_species_richness_2(model: Dictionary, delta_model: Dictionary) -> float:
	# Optimized function for components w/ delta
	var species := 0.0
	for key: int in model:
		assert(model[key] > 0.0, "'model' has <= 0.0 value")
		if delta_model.has(key):
			if delta_model[key] <= -model[key]:
				assert(delta_model[key] == -model[key])
				continue
		var mod100: int = key % 100 # 0, 1, ..., 99
		species += pow(10.0, mod100) # 1, 10, ..., 1e99 sp
	for key: int in delta_model:
		if model.has(key):
			continue
		assert(delta_model[key] > 0.0, "'delta_model' has <= 0.0 value for key not in 'model'")
		var mod100: int = key % 100 # 0, 1, ..., 99
		species += pow(10.0, mod100) # 1, 10, ..., 1e99 sp
	return species


static func change_model(model: Dictionary, key: int, change: float) -> void:
	assert(change != 0.0)
	assert(change == floor(change), "Expected integral value!")
	if model.has(key):
		model[key] += change
		if model[key] == 0.0:
			model.erase(key)
	else:
		model[key] = change


static func add_to_model(model: Dictionary, add: Dictionary) -> void:
	# modifies 'model'; adds could be negative changes
	for key: int in add:
		assert(add[key] > 0.0, "'add' model has <= 0.0 value")
		if model.has(key):
			model[key] += add[key]
			if model[key] == 0.0:
				model.erase(key)
		else:
			model[key] = add[key]


