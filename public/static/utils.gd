# utils.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name Utils

const ivutils := preload("res://addons/ivoyager_core/static/utils.gd")


const LOG2_64 := { # indexed by power-of-2s from 2^0 to 2^63
	1 << 0 : 0, 1 << 1 : 1, 1 << 2 : 2, 1 << 3 : 3, 1 << 4 : 4,
	1 << 5 : 5, 1 << 6 : 6, 1 << 7 : 7, 1 << 8 : 8, 1 << 9 : 9,
	1 << 10 : 10, 1 << 11 : 11, 1 << 12 : 12, 1 << 13 : 13, 1 << 14 : 14,
	1 << 15 : 15, 1 << 16 : 16, 1 << 17 : 17, 1 << 18 : 18, 1 << 19 : 19,
	1 << 20 : 20, 1 << 21 : 21, 1 << 22 : 22, 1 << 23 : 23, 1 << 24 : 24,
	1 << 25 : 25, 1 << 26 : 26, 1 << 27 : 27, 1 << 28 : 28, 1 << 29 : 29, 
	1 << 30 : 30, 1 << 31 : 31, 1 << 32 : 32, 1 << 33 : 33, 1 << 34 : 34,
	1 << 35 : 35, 1 << 36 : 36, 1 << 37 : 37, 1 << 38 : 38, 1 << 39 : 39,
	1 << 40 : 40, 1 << 41 : 41, 1 << 42 : 42, 1 << 43 : 43, 1 << 44 : 44,
	1 << 45 : 45, 1 << 46 : 46, 1 << 47 : 47, 1 << 48 : 48, 1 << 49 : 49,
	1 << 50 : 50, 1 << 51 : 51, 1 << 52 : 52, 1 << 53 : 53, 1 << 54 : 54,
	1 << 55 : 55, 1 << 56 : 56, 1 << 57 : 57, 1 << 58 : 58, 1 << 59 : 59,
	1 << 60 : 60, 1 << 61 : 61, 1 << 62 : 62, 1 << 63 : 63,
}
const RECIPROCAL_LN2 := 1.0 / log(2.0) # log() is natural logarithm

# binary

static func get_lsb_index(flags: int) -> int:
	# returns index position of least significant bit
	# will error if flags == 0
	# for optimized C++ code see:
	# https://stackoverflow.com/questions/11376288/fast-computing-of-log2-for-64-bit-integers
	flags &= -flags # gets least significant bit (weird but true)
	return LOG2_64[flags]


static func binary_str(flags: int) -> String:
	# returns 64 bit string
	var result := ""
	var index := 0
	while index < 64:
		if index % 8 == 0 and index != 0:
			result = "_" + result
		result = "1" + result if flags & 1 else "0" + result
		flags >>= 1
		index += 1
	return result


static func get_n_bits(n: int) -> int:
	# max 64
	if n < 64:
		return (1 << n) - 1 # err if n < 0
	if n == 64:
		return ((1 << 63)) - 1 | (1 << 63)
	assert(false, "n must be in range 0 to 64")
	return 0




# array & dict utils

static func invert_many_to_one_indexing(base: Array[int], size: int) -> Array[Array]:
	# e.g., ([0, 1, 1, 1, 3, 3], 5)
	# -> [[0], [1, 2, 3], [], [4, 5], []]
	var result: Array[Array] = []
	for result_index in size:
		var indexes: Array[int] = []
		for index in base.size():
			if base[index] == result_index:
				indexes.append(index)
		result.append(indexes)
	return result


static func invert_subset_indexing(base: Array[int], size: int) -> Array[int]:
	# inverts subset indexes of a larger set
	# e.g., ([3, 4, 5, 7, 8, 9], 11)
	# -> [-1, -1, -1, 0, 1, 2, -1, 3, 4, 5, -1]
	# same result as find each index in the subset, but faster
	var result: Array[int] = []
	result.resize(size)
	result.fill(-1)
	var base_size := base.size()
	var i := 0
	while i < base_size:
		var base_index: int = base[i]
		result[base_index] = i
		i += 1
	return result


static func replace_array_contents(base: Array, with: Array) -> void:
	base.clear()
	for item in with:
		base.append(item)


static func replace_dict_contents(base: Dictionary, with: Dictionary) -> void:
	base.clear()
	for key in with:
		base[key] = with[key]


static func fill_array(base: Array, fill: Array) -> void:
	var i := base.size()
	while i > 0:
		i -= 1
		base[i] = fill[i]


static func get_weighted_averages(data1: Array[float], weights1: Array[float],
		data2: Array[float], weights2: Array[float]) -> Array[float]:
	# assumes float arrays of equal sizes
	var i := data1.size()
	var result: Array[float] = []
	result.resize(i)
	while i > 0:
		i -= 1
		result[i] = (data1[i] * weights1[i] + data2[i] * weights2[i]) / (weights1[i] + weights2[i])
	return result


static func get_weighted_averages_diff(data: Array[float], data_weights: Array[float],
		subtract: Array[float], subtract_weights: Array[float]) -> Array[float]:
	# expects float arrays of equal sizes; reverses above function
	var i := data.size()
	var result: Array[float] = []
	result.resize(i)
	while i > 0:
		i -= 1
		result[i] = ((data[i] * data_weights[i] - subtract[i] * subtract_weights[i])
				/ (data_weights[i] - subtract_weights[i]))
	return result


static func combine_weighted_floats(base: Array[float], base_weights: Array[float],
		add: Array[float], add_weights: Array[float]) -> void:
	# modifies 'base'; expects float arrays of equal sizes
	var i := base.size()
	while i > 0:
		i -= 1
		var divisor: float = base_weights[i] + add_weights[i]
		if divisor > 0.0:
			base[i] = (base[i] * base_weights[i] + add[i] * add_weights[i]) / divisor


static func combine_weighted_float_arrays(base: Array[Array], base_weights: Array[float],
		add: Array[Array], add_weights: Array[float]) -> void:
	# as above, but expects base and add to be arrays of arrays of floats
	var i := base.size()
	while i > 0:
		i -= 1
		if !base[i] or !add[i]:
			continue
		var divisor: float = base_weights[i] + add_weights[i]
		if divisor > 0.0:
			var j: int = base[i].size()
			while j > 0:
				j -= 1
				base[i][j] = (base[i][j] * base_weights[i] + add[i][j] * add_weights[i]) / divisor


static func deduct_weighted_floats(base: Array[float], base_weights: Array[float],
		deduct: Array[float], deduct_weights: Array[float]) -> void:
	# modifies 'base'; expects float arrays of equal sizes
	var i := base.size()
	while i > 0:
		i -= 1
		var divisor: float = base_weights[i] - deduct_weights[i]
		if divisor > 0.0:
			base[i] = (base[i] * base_weights[i] - deduct[i] * deduct_weights[i]) / divisor


static func deduct_weighted_float_arrays(base: Array[Array], base_weights: Array[float],
		deduct: Array[Array], deduct_weights: Array[float]) -> void:
	# as above, but expects base and add to be arrays of arrays of floats
	var i := base.size()
	while i > 0:
		i -= 1
		if !base[i] or !deduct[i]:
			continue
		var divisor: float = base_weights[i] - deduct_weights[i]
		if divisor > 0.0:
			var j: int = base[i].size()
			while j > 0:
				j -= 1
				base[i][j] = (base[i][j] * base_weights[i] - deduct[i][j] * deduct_weights[i]) / divisor


static func normalize_float_array(array: Array[float], normalized_sum: float) -> void:
	# if array sums to 0.0, returns an array of INF values
	var sum := 0.0
	var size := array.size()
	var i := 0
	while i < size:
		sum += array[i]
		i += 1
	if sum == 0.0:
		array.fill(INF) # test array[0] == INF for failure
		return
	var multiplier := normalized_sum / sum
	i = 0
	while i < size:
		array[i] *= multiplier
		i += 1


static func get_float_array_sum(array: Array[float]) -> float:
	var sum := 0.0
	var i := array.size()
	while i > 0:
		i -= 1
		sum += array[i]
	return sum


static func multiply_float_array_by_float(array: Array[float], multiplier: float) -> void:
	var i := array.size()
	while i > 0:
		i -= 1
		array[i] *= multiplier


static func multiply_float_array_by_array(base: Array[float], multiply: Array[float]) -> void:
	# modifies 'base'; expects float arrays of equal sizes
	var i := base.size()
	while i > 0:
		i -= 1
		base[i] *= multiply[i]


static func add_to_float_array_with_array(base: Array[float], add: Array[float]) -> void:
	# modifies 'base'; expects float arrays of equal sizes
	var i := base.size()
	while i > 0:
		i -= 1
		base[i] += add[i]


static func subtract_from_float_array_with_array(base: Array[float], subtract: Array[float]) -> void:
	# modifies 'base'; expects float arrays of equal sizes
	var i := base.size()
	while i > 0:
		i -= 1
		base[i] -= subtract[i]


static func zero_float_array(array: Array[float]) -> void:
	var i := array.size()
	while i > 0:
		i -= 1
		array[i] = 0.0


static func zero_array_of_float_arrays(array: Array[Array]) -> void:
	var i := array.size()
	while i > 0:
		i -= 1
		if !array[i]: # skip []
			continue
		var j: int = array[i].size()
		while j > 0:
			j -= 1
			array[i][j] = 0.0


# diversity / information functions

static func get_diversity_index(diversity_model: Dictionary, q := 1.0) -> float:
	# Returns Hill number of order q.
	# https://en.wikipedia.org/wiki/Diversity_index
	#
	# If all species are equally represented, then index = number of species.
	# The purpose of the index is to discount low abundance species (larger
	# values of q give greater discount). The unit of measure is 'species'.
	# 
	# For q = 1, diversity index equals the exponential of the Shannon Entropy
	# calculated in 'natural units' (base e). See get_shannon_entropy() below.
	#
	# How 'diversity_model' works:
	#
	# In a perfect simulation, we would have a dictionary key for every species
	# with dict[key] equal to number of individuals in that species. But that's
	# a lot of keys! We approximate this using integer keys that represent
	# individual species or groups of species. The last two digits of the key
	# (ie, key mod 100) tells us the number of species that the key represents:
	#
	#   00, -> key represents 1 unique species (value is number of individuals)
	#   01, -> key represents 10 unique species (value is number of individuals in each)
	#   02, -> key represents 100 unique species (value is number of individuals in each)
	#   ...
	#   99, -> key represents 1e99 unique species (value is number of individuals in each)
	#   (Probably all keys will end 0x but just maybe we'll see 1x.)
	#
	# All diversity_model values are integral floats >= 1.0.
	# (Interesting programming note: base Homo sapiens has key = 0.)
	
	if diversity_model.is_empty():
		return 0.0 # not exactly correct but intuitive
	if q == 1.0:
		return exp(get_shannon_entropy(diversity_model, false)) # limit as q -> 1
	var n_individuals := 0.0
	for key in diversity_model:
		var mod100: int = key % 100 # 0, 1, ..., 99
		n_individuals += diversity_model[key] * pow(10.0, mod100) # x 1, 10, ..., 1e99 sp
	var summation := 0.0
	for key in diversity_model:
		var mod100: int = key % 100 # 0, 1, ..., 99
		var p: float = diversity_model[key] / n_individuals
		summation += pow(p, q) * pow(10.0, mod100)
	return pow(summation, 1.0 / (1.0 - q))


static func get_shannon_entropy(diversity_model: Dictionary, in_bits := true) -> float:
	# see comments above
	# The unit of measure is 'bits' by default (base 2). If in_bits == false,
	# then the unit of measure is 'natural units' (base e).
	if diversity_model.is_empty():
		return 0.0 # not exactly correct but intuitive
	var n_individuals := 0.0
	for key in diversity_model:
		var mod100: int = key % 100 # 0, 1, ..., 99
		n_individuals += diversity_model[key] * pow(10.0, mod100) # x 1, 10, ..., 1e99 sp
	var summation := 0.0
	for key in diversity_model:
		var mod100: int = key % 100 # 0, 1, ..., 99
		var p: float = diversity_model[key] / n_individuals
		summation += p * log(p) * pow(10.0, mod100) # log() is natural logarithm
	if in_bits:
		summation *= RECIPROCAL_LN2
	return -summation


static func get_species_richness(diversity_model: Dictionary) -> float:
	# total number of species
	var species := 0.0
	for key in diversity_model: # model keys always removed when value == 0.0
		var mod100: int = key % 100 # 0, 1, ..., 99
		species += pow(10.0, mod100) # 1, 10, ..., 1e99 sp
	return species


static func add_to_diversity_model(base: Dictionary, add: Dictionary) -> void:
	# modifies 'base' diversity model; adds could be negative changes
	for key in add:
		if base.has(key):
			base[key] += add[key]
			if base[key] == 0.0:
				base.erase(key)
		else:
			base[key] = add[key]

