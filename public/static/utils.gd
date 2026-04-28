# utils.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name Utils
extends Object

## Astropolis-wide static utilities for bit manipulation, packed-array
## conversion, weighted-average computation, and float-array math.
##
## See [IVArrays] (in [code]ivoyager_core[/code]) for general-purpose array
## utilities; this class adds Astropolis-specific helpers.


## Maps a power-of-two ([code]1 << n[/code]) to its index [code]n[/code], for
## [code]n[/code] in 0..62. Used by sync helpers to recover the bit index of
## the least significant set bit. Index 63 isn't available because the sign
## bit ([code]1 << 63[/code]) can't be left-shifted further.
const BIT_INDEXES: Dictionary[int, int] = { # indexed by power-of-2s from 2^0 to 2^62
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
	1 << 60 : 60, 1 << 61 : 61, 1 << 62 : 62
}

# binary

## Returns the bit index (0..62) of the least significant set bit of
## [param flags]. Errors if [param flags] is 0 or only the sign bit is set.
## For an optimized C++ equivalent see [url=https://stackoverflow.com/questions/11376288/fast-computing-of-log2-for-64-bit-integers]Fast computing of log2[/url].
static func get_lsb_index(flags: int) -> int:
	flags &= -flags # gets least significant bit (weird but true)
	return BIT_INDEXES[flags]


## Returns an int with the lowest [param n] bits set. [param n] must be in
## the range 0..64.
static func get_n_bits(n: int) -> int:
	if n < 64:
		return (1 << n) - 1 # err if n < 0
	if n == 64:
		return ((1 << 63)) - 1 | (1 << 63)
	assert(false, "n must be in range 0 to 64")
	return 0


# array & dict utils


## Returns the intersection of two packed int arrays — values present in
## both [param a] and [param b], in [param a]'s order.
static func get_packed_index_intersection(a: PackedInt32Array, b: PackedInt32Array
		) -> PackedInt32Array:
	var result := PackedInt32Array()
	for i in a.size():
		var index := a[i]
		if b.has(index):
			result.append(index)
	return result


## Inverts subset indexing into a larger set of [param size]. E.g.,
## [code]([3, 4, 5, 7, 8, 9], 11)[/code] returns
## [code][-1, -1, -1, 0, 1, 2, -1, 3, 4, 5, -1][/code]. Equivalent to
## finding each index in the subset, but faster.
static func invert_packed_subset_indexing(base: PackedInt32Array, size: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(size)
	result.fill(-1)
	var base_size := base.size()
	var i := 0
	while i < base_size:
		result[base[i]] = i
		i += 1
	return result


## As [method invert_packed_subset_indexing], but accepts a typed
## [code]Array[int][/code] input.
static func invert_subset_indexing_packed(base: Array[int], size: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(size)
	result.fill(-1)
	var base_size := base.size()
	var i := 0
	while i < base_size:
		result[base[i]] = i
		i += 1
	return result


## Inverts a many-to-one indexing into per-target lists of source indexes.
## E.g., [code]([0, 1, 1, 1, 3, 3], 5)[/code] returns
## [code][[0], [1, 2, 3], [], [4, 5], []][/code].
static func invert_packed_many_to_one_indexing(base: PackedInt32Array, size: int
		) -> Array[PackedInt32Array]:
	var result: Array[PackedInt32Array] = []
	for result_index in size:
		var indexes := PackedInt32Array()
		for index in base.size():
			if base[index] == result_index:
				indexes.append(index)
		result.append(indexes)
	return result


## As [method invert_packed_many_to_one_indexing], but accepts a typed
## [code]Array[int][/code] input.
static func invert_many_to_one_indexing_to_packed(base: Array[int], size: int
		) -> Array[PackedInt32Array]:
	var result: Array[PackedInt32Array] = []
	for result_index in size:
		var indexes := PackedInt32Array()
		for index in base.size():
			if base[index] == result_index:
				indexes.append(index)
		result.append(indexes)
	return result


## Convert Array of items evaluated as true or false to PackedByteArray of
## 1's and 0's.
static func bool_array_to_packed_bytes(array: Array) -> PackedByteArray:
	var size := array.size()
	var result := PackedByteArray()
	result.resize(size)
	var i := 0
	while i < size:
		result[i] = 1 if array[i] else 0
		i += 1
	return result


## Convert [code]Array[Array][/code] of float arrays to [code]Array[PackedFloat32Array][/code].
static func to_array_of_packed_float32(array: Array[Array]) -> Array[PackedFloat32Array]:
	var size := array.size()
	var result: Array[PackedFloat32Array] = []
	result.resize(size)
	var i := size
	while i > 0:
		i -= 1
		result[i] = PackedFloat32Array(array[i])
	return result


## Convert [code]Array[Array][/code] of int arrays to [code]Array[PackedInt32Array][/code].
static func to_array_of_packed_int32(array: Array[Array]) -> Array[PackedInt32Array]:
	var size := array.size()
	var result: Array[PackedInt32Array] = []
	result.resize(size)
	var i := size
	while i > 0:
		i -= 1
		result[i] = PackedInt32Array(array[i])
	return result


## Returns element-wise weighted averages of two equal-length float arrays.
## Each result element is
## [code](data1 * weights1 + data2 * weights2) / (weights1 + weights2)[/code].
static func get_weighted_averages(data1: Array[float], weights1: Array[float],
		data2: Array[float], weights2: Array[float]) -> Array[float]:
	var i := data1.size()
	var result: Array[float] = []
	result.resize(i)
	while i > 0:
		i -= 1
		result[i] = (data1[i] * weights1[i] + data2[i] * weights2[i]) / (weights1[i] + weights2[i])
	return result


## Inverse of [method get_weighted_averages] — returns the weighted average
## "remaining" after [param subtract]/[param subtract_weights] is removed
## from [param data]/[param data_weights].
static func get_weighted_averages_diff(data: Array[float], data_weights: Array[float],
		subtract: Array[float], subtract_weights: Array[float]) -> Array[float]:
	var i := data.size()
	var result: Array[float] = []
	result.resize(i)
	while i > 0:
		i -= 1
		result[i] = ((data[i] * data_weights[i] - subtract[i] * subtract_weights[i])
				/ (data_weights[i] - subtract_weights[i]))
	return result


## In-place merges weighted [param add] into weighted [param base]
## element-wise, leaving [param base] as the combined weighted average.
## Skips elements where total weight is non-positive.
static func combine_weighted_floats(base: Array[float], base_weights: Array[float],
		add: Array[float], add_weights: Array[float]) -> void:
	var i := base.size()
	while i > 0:
		i -= 1
		var divisor: float = base_weights[i] + add_weights[i]
		if divisor > 0.0:
			base[i] = (base[i] * base_weights[i] + add[i] * add_weights[i]) / divisor


## As [method combine_weighted_floats], but accepts arrays of float arrays
## (with shared per-array weights). Skips empty entries.
static func combine_weighted_float_arrays(base: Array[Array], base_weights: Array[float],
		add: Array[Array], add_weights: Array[float]) -> void:
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


## In-place deducts weighted [param deduct] from weighted [param base]
## element-wise, leaving [param base] as the remaining weighted average.
## Skips elements where the remaining weight is non-positive.
static func deduct_weighted_floats(base: Array[float], base_weights: Array[float],
		deduct: Array[float], deduct_weights: Array[float]) -> void:
	var i := base.size()
	while i > 0:
		i -= 1
		var divisor: float = base_weights[i] - deduct_weights[i]
		if divisor > 0.0:
			base[i] = (base[i] * base_weights[i] - deduct[i] * deduct_weights[i]) / divisor


## As [method deduct_weighted_floats], but accepts arrays of float arrays
## (with shared per-array weights). Skips empty entries.
static func deduct_weighted_float_arrays(base: Array[Array], base_weights: Array[float],
		deduct: Array[Array], deduct_weights: Array[float]) -> void:
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


## If [param error_inf] is set, zero-sum condition is indicated by INF at index
## 0 (only). Default behavior is to return a zero-sum array unchanged.
static func normalize_float_array(array: Array[float], normalized_sum := 1.0,
		error_inf := false) -> void:
	# if array sums to 0.0, returns an array of INF values
	var sum := 0.0
	var size := array.size()
	var i := 0
	while i < size:
		sum += array[i]
		i += 1
	if sum == 0.0:
		if error_inf:
			array[0] = INF # test array[0] == INF for zero sum condition
		return
	var multiplier := normalized_sum / sum
	i = 0
	while i < size:
		array[i] *= multiplier
		i += 1


## Returns the sum of all elements in [param array].
static func get_float_array_sum(array: Array[float]) -> float:
	var sum := 0.0
	var i := array.size()
	while i > 0:
		i -= 1
		sum += array[i]
	return sum


## In-place multiplies every element of [param array] by [param multiplier].
static func multiply_float_array_by_float(array: Array[float], multiplier: float) -> void:
	var i := array.size()
	while i > 0:
		i -= 1
		array[i] *= multiplier


## In-place element-wise multiplication of [param base] by [param multiply].
## Expects equal-length arrays.
static func multiply_float_array_by_array(base: Array[float], multiply: Array[float]) -> void:
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


## Sets every element of [param array] to 0.0.
static func zero_float_array(array: Array[float]) -> void:
	var i := array.size()
	while i > 0:
		i -= 1
		array[i] = 0.0


## Sets every element of every inner array in [param array] to 0.0. Skips
## empty inner arrays.
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
