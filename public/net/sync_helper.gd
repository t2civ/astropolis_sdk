# sync_helper.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name SyncHelper
extends RefCounted

## Internal helper for [code]*Net[/code] components: bit-packed dirty-flag
## sync over flat [int]/[float] payload arrays.
##
## Used by [OperationsNet], [InventoryNet], [FinancialsNet], and the other net
## components to (de)serialize dirty fields. The [code]*_63[/code] variants
## handle a single 63-bit flag chunk; the non-suffixed variants handle a
## flag-array (one int per 63 indices, with the sign bit chained to indicate
## "more chunks follow").
##
## SDK Note: This class is for internal sync only. It will be ported to C++
## along with the component classes.

var _int_data: Array[int]
var _float_data: Array[float]
var _int_offset: int
var _float_offset: int


## Marks element [param index] dirty in [param dirty_array] (a chunked bit
## flag array using bit 63 as a chunk-continues marker).
static func set_dirty(dirty_array: Array[int], index: int) -> void:
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	while index >= 63:
		dirty_array[flag_index] |= SIGN_BIT
		flag_index += 1
		index -= 63
	dirty_array[flag_index] |= 1 << index


## Initializes for receive (decode): bind buffers and offsets so [method
## set_floats_dirty], [method set_ints_dirty], [method add_floats_delta], etc.
## can read out of [param int_data] / [param float_data].
func init_for_add(int_data: Array[int], float_data: Array[float], int_offset: int,
		float_offset: int) -> void:
	_int_data = int_data
	_float_data = float_data
	_int_offset = int_offset
	_float_offset = float_offset


## Initializes for send (encode): bind output buffers so [method
## get_floats_dirty], [method get_ints_dirty], [method take_floats_delta], etc.
## can append into [param int_data] / [param float_data].
func init_for_take(int_data: Array[int], float_data: Array[float]) -> void:
	_int_data = int_data
	_float_data = float_data


# array sync

## Encodes dirty entries of [param array] into the bound output buffers, using
## chunked dirty flags from [param flags_array]. Clears the flag entries.
func get_ints_dirty(array: Array[int], flags_array: Array[int]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var sign_bit := SIGN_BIT
	while sign_bit:
		var flags := flags_array[flag_index]
		_int_data.append(flags)
		sign_bit &= flags
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			_int_data.append(array[index])
			flags &= ~lsb
		flags_array[flag_index] = 0
		flag_index += 1


## Single-chunk variant of [method get_ints_dirty] (up to 63 entries).
func get_ints_dirty_63(array: Array[int], flags: int) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		_int_data.append(array[index])
		flags &= ~lsb


## Encodes dirty entries of [param array] into the bound output buffers, using
## chunked dirty flags from [param flags_array]. Clears the flag entries.
func get_floats_dirty(array: Array[float], flags_array: Array[int]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var sign_bit := SIGN_BIT
	while sign_bit:
		var flags := flags_array[flag_index]
		_int_data.append(flags)
		sign_bit &= flags
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			_float_data.append(array[index])
			flags &= ~lsb
		flags_array[flag_index] = 0
		flag_index += 1


## Single-chunk variant of [method get_floats_dirty] (up to 63 entries).
func get_floats_dirty_63(array: Array[float], flags: int) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		_float_data.append(array[index])
		flags &= ~lsb


## Adds dirty entries of [param delta] into [param base] and emits each delta
## value into the output buffer; zeroes the consumed delta entries. Used for
## sending an accumulator's diff to the receiver.
func take_floats_delta(base: Array[float], delta: Array[float], flags_array: Array[int]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var sign_bit := SIGN_BIT
	while sign_bit:
		var flags := flags_array[flag_index]
		_int_data.append(flags)
		sign_bit &= flags
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			base[index] += delta[index]
			_float_data.append(delta[index])
			delta[index] = 0.0
			flags &= ~lsb
		flags_array[flag_index] = 0
		flag_index += 1


## Single-chunk variant of [method take_floats_delta] (up to 63 entries).
func take_floats_delta_63(base: Array[float], delta: Array[float], flags: int) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		base[index] += delta[index]
		_float_data.append(delta[index])
		delta[index] = 0.0
		flags &= ~lsb


## Reads dirty values out of the bound input buffers, writing each to its
## indexed slot in [param array]. Mirror of [method get_floats_dirty].
func set_floats_dirty(array: Array[float]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var sign_bit := SIGN_BIT
	while sign_bit:
		var flags := _int_data[_int_offset]
		_int_offset += 1
		sign_bit &= flags
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			array[index] = _float_data[_float_offset]
			_float_offset += 1
			flags &= ~lsb
		flag_index += 1


## Single-chunk variant of [method set_floats_dirty] (up to 63 entries).
func set_floats_dirty_63(array: Array[float]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	var flags := _int_data[_int_offset]
	_int_offset += 1
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		array[index] = _float_data[_float_offset]
		_float_offset += 1
		flags &= ~lsb


## Reads dirty values out of the bound input buffers, writing each to its
## indexed slot in [param array]. Mirror of [method get_ints_dirty].
func set_ints_dirty(array: Array[int]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var sign_bit := SIGN_BIT
	while sign_bit:
		var flags := _int_data[_int_offset]
		_int_offset += 1
		sign_bit &= flags
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			array[index] = _int_data[_int_offset]
			_int_offset += 1
			flags &= ~lsb
		flag_index += 1


## Single-chunk variant of [method set_ints_dirty] (up to 63 entries).
func set_ints_dirty_63(array: Array[int]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	var flags := _int_data[_int_offset]
	_int_offset += 1
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		array[index] = _int_data[_int_offset]
		_int_offset += 1
		flags &= ~lsb


## Reads dirty delta values out of the bound input buffers and adds each to
## its indexed slot in [param delta_array]. Mirror of [method take_floats_delta].
func add_floats_delta(delta_array: Array[float]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var sign_bit := SIGN_BIT
	while sign_bit:
		var flags := _int_data[_int_offset]
		_int_offset += 1
		sign_bit &= flags
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			delta_array[index] += _float_data[_float_offset]
			_float_offset += 1
			flags &= ~lsb
		flag_index += 1


## Single-chunk variant of [method add_floats_delta] (up to 63 entries).
func add_floats_delta_63(delta_array: Array[float]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	var flags := _int_data[_int_offset]
	_int_offset += 1
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		delta_array[index] += _float_data[_float_offset]
		_float_offset += 1
		flags &= ~lsb
