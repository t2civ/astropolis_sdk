# sync_helper.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name SyncHelper
extends RefCounted

# SDK Note: This class is for internal sync only. It will be ported to C++ with
# the component classes.

var _int_data: Array[int]
var _float_data: Array[float]
var _int_offset: int
var _float_offset: int


static func set_dirty(dirty_array: Array[int], index: int) -> void:
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	while index >= 63:
		dirty_array[flag_index] |= SIGN_BIT
		flag_index += 1
		index -= 63
	dirty_array[flag_index] |= 1 << index


func init_for_add(int_data: Array[int], float_data: Array[float], int_offset: int,
		float_offset: int) -> void:
	_int_data = int_data
	_float_data = float_data
	_int_offset = int_offset
	_float_offset = float_offset


func init_for_take(int_data: Array[int], float_data: Array[float]) -> void:
	_int_data = int_data
	_float_data = float_data


# array sync

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


func get_ints_dirty_63(array: Array[int], flags: int) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		_int_data.append(array[index])
		flags &= ~lsb


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


func get_floats_dirty_63(array: Array[float], flags: int) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var index := BIT_INDEXES[lsb]
		_float_data.append(array[index])
		flags &= ~lsb


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
