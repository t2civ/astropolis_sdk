# utils.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name Utils
extends Object

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

# binary

static func get_lsb_index(flags: int) -> int:
	# returns index position of least significant bit
	# will error if flags == 0
	# for optimized C++ code see:
	# https://stackoverflow.com/questions/11376288/fast-computing-of-log2-for-64-bit-integers
	flags &= -flags # gets least significant bit (weird but true)
	return LOG2_64[flags]


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


## Returns an array containing element-wise a plus b. Expects float arrays of equal size.
static func add_float_arrays(a: Array[float], b: Array[float]) -> Array[float]:
	assert(a.size() == b.size())
	var sum: Array[float] = []
	sum.assign(a)
	var i := a.size()
	while i > 0:
		i -= 1
		sum[i] += b[i]
	return sum


## Returns an array containing element-wise a minus b. Expects float arrays of equal size.
static func subtract_float_arrays(a: Array[float], b: Array[float]) -> Array[float]:
	assert(a.size() == b.size())
	var diff: Array[float] = []
	diff.assign(a)
	var i := a.size()
	while i > 0:
		i -= 1
		diff[i] -= b[i]
	return diff


## Modifies 'base' array. Expects float arrays of equal size.
static func add_to_float_array_with_array(base: Array[float], add: Array[float]) -> void:
	var i := base.size()
	while i > 0:
		i -= 1
		base[i] += add[i]


## Modifies 'base' array. Expects float arrays of equal size.
static func subtract_from_float_array_with_array(base: Array[float], subtract: Array[float]) -> void:
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

