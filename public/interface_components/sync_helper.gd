# sync_helper.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name SyncHelper
extends RefCounted

## Helper component for interface-side sync: bit-packed dirty-flag
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

var int_offset: int
var float_offset: int

var _int_data: PackedInt64Array
var _float_data: PackedFloat64Array


## Marks element [param index] dirty in [param dirty_array] (a chunked bit
## flag array using bit 63 as a chunk-continues marker).
static func set_dirty(dirty_array: PackedInt64Array, index: int) -> void:
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
func init_for_add(int_data: PackedInt64Array, float_data: PackedFloat64Array, int_offset_: int,
		float_offset_: int) -> void:
	_int_data = int_data
	_float_data = float_data
	int_offset = int_offset_
	float_offset = float_offset_


## Initializes for send (encode): bind output buffers so [method
## get_floats_dirty], [method get_ints_dirty], [method take_floats_delta], etc.
## can append into [param int_data] / [param float_data].
func init_for_take(int_data: PackedInt64Array, float_data: PackedFloat64Array) -> void:
	_int_data = int_data
	_float_data = float_data


# array sync

## Encodes dirty entries of [param array] into the bound output buffers, using
## chunked dirty flags from [param flags_array]. Clears the flag entries.
func get_ints_dirty(array: PackedInt64Array, flags_array: PackedInt64Array) -> void:
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
func get_ints_dirty_63(array: PackedInt64Array, flags: int) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		_int_data.append(array[index])
		flags &= ~lsb


## Encodes dirty entries of [param array] into the bound output buffers, using
## chunked dirty flags from [param flags_array]. Clears the flag entries.
func get_floats_dirty(array: PackedFloat64Array, flags_array: PackedInt64Array) -> void:
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
func get_floats_dirty_63(array: PackedFloat64Array, flags: int) -> void:
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
func take_floats_delta(base: PackedFloat64Array, delta: PackedFloat64Array, flags_array: PackedInt64Array) -> void:
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
func take_floats_delta_63(base: PackedFloat64Array, delta: PackedFloat64Array, flags: int) -> void:
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
func set_floats_dirty(array: PackedFloat64Array) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var sign_bit := SIGN_BIT
	while sign_bit:
		var flags := _int_data[int_offset]
		int_offset += 1
		sign_bit &= flags
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			array[index] = _float_data[float_offset]
			float_offset += 1
			flags &= ~lsb
		flag_index += 1


## Single-chunk variant of [method set_floats_dirty] (up to 63 entries).
func set_floats_dirty_63(array: PackedFloat64Array) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	var flags := _int_data[int_offset]
	int_offset += 1
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		array[index] = _float_data[float_offset]
		float_offset += 1
		flags &= ~lsb


## Reads dirty values out of the bound input buffers, writing each to its
## indexed slot in [param array]. Mirror of [method get_ints_dirty].
func set_ints_dirty(array: PackedInt64Array) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var sign_bit := SIGN_BIT
	while sign_bit:
		var flags := _int_data[int_offset]
		int_offset += 1
		sign_bit &= flags
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			array[index] = _int_data[int_offset]
			int_offset += 1
			flags &= ~lsb
		flag_index += 1


## Single-chunk variant of [method set_ints_dirty] (up to 63 entries).
func set_ints_dirty_63(array: PackedInt64Array) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	var flags := _int_data[int_offset]
	int_offset += 1
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		array[index] = _int_data[int_offset]
		int_offset += 1
		flags &= ~lsb


## Reads dirty delta values out of the bound input buffers and adds each to
## its indexed slot in [param delta_array]. Mirror of [method take_floats_delta].
func add_floats_delta(delta_array: PackedFloat64Array) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var sign_bit := SIGN_BIT
	while sign_bit:
		var flags := _int_data[int_offset]
		int_offset += 1
		sign_bit &= flags
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			delta_array[index] += _float_data[float_offset]
			float_offset += 1
			flags &= ~lsb
		flag_index += 1


## Single-chunk variant of [method add_floats_delta] (up to 63 entries).
func add_floats_delta_63(delta_array: PackedFloat64Array) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	var flags := _int_data[int_offset]
	int_offset += 1
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		delta_array[index] += _float_data[float_offset]
		float_offset += 1
		flags &= ~lsb


## Reads sparse changes from the bound int/float input buffers and applies them
## to [param base] (additive): for each upsert, looks up the keyed
## PackedFloat64Array (allocating a new one of size [param n_indexes] when the
## key is new), then adds each delta value into its indexed slot. Erases keys
## listed in the removes section. Mirror of
## [SvrSyncHelper.take_sparse_floats_dict_delta].
func add_sparse_floats_dict_delta(base: Dictionary[int, PackedFloat64Array],
		n_indexes: int) -> void:
	var upserts_count := _int_data[int_offset]
	int_offset += 1
	var i := 0
	while i < upserts_count:
		var key := _int_data[int_offset]
		int_offset += 1
		var n_changes := _int_data[int_offset]
		int_offset += 1
		var arr: PackedFloat64Array
		if base.has(key):
			arr = base[key]
		else:
			arr = PackedFloat64Array()
			arr.resize(n_indexes)
			base[key] = arr
		var j := 0
		while j < n_changes:
			var index := _int_data[int_offset]
			int_offset += 1
			arr[index] += _float_data[float_offset]
			float_offset += 1
			j += 1
		i += 1

	var removes_count := _int_data[int_offset]
	int_offset += 1
	i = 0
	while i < removes_count:
		var key := _int_data[int_offset]
		int_offset += 1
		base.erase(key)
		i += 1
