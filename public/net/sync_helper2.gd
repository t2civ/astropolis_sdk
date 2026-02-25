# sync_helper2.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name SyncHelper2
extends RefCounted

# SDK Note: This class is for internal sync only. It will be ported to C++ with
# the component classes.



var _int_data: Array[int]
var _float_data: Array[float]
var _int_offset: int
var _float_offset: int


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
	var more_dirty := 1
	while more_dirty:
		var flags := flags_array[flag_index]
		_int_data.append(flags)
		more_dirty = flags & SIGN_BIT
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			_int_data.append(array[index])
			flags &= ~lsb
		flags_array[flag_index] = 0
		flag_index += 1
	
	#_int_data.append(flags)
	#while flags:
		#var lsb := flags & -flags
		#var i: int = BIT_INDEXES[lsb] + bits_offset
		#_int_data.append(array[i])
		#flags &= ~lsb


func get_floats_dirty(array: Array[float], flags_array: Array[int]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var more_dirty := 1
	while more_dirty:
		var flags := flags_array[flag_index]
		_int_data.append(flags)
		more_dirty = flags & SIGN_BIT
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			_float_data.append(array[index])
			flags &= ~lsb
		flags_array[flag_index] = 0
		flag_index += 1
	
	#_int_data.append(flags)
	#while flags:
		#var lsb := flags & -flags
		#var i: int = BIT_INDEXES[lsb] + bits_offset
		#_float_data.append(array[i])
		#flags &= ~lsb


func take_floats_delta(base: Array[float], delta: Array[float], flags_array: Array[int]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var more_dirty := 1
	while more_dirty:
		var flags := flags_array[flag_index]
		_int_data.append(flags)
		more_dirty = flags & SIGN_BIT
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
	
	#_int_data.append(flags)
	#while flags:
		#var lsb := flags & -flags
		#var i: int = BIT_INDEXES[lsb] + bits_offset
		#base[i] += delta[i]
		#_float_data.append(delta[i])
		#delta[i] = 0.0
		#flags &= ~lsb


func set_floats_dirty(array: Array[float]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var more_dirty := 1
	while more_dirty:
		var flags := _int_data[_int_offset]
		_int_offset += 1
		more_dirty = flags & SIGN_BIT
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			array[index] = _float_data[_float_offset]
			_float_offset += 1
			flags &= ~lsb
		flag_index += 1
	
	#var flags := _int_data[_int_offset]
	#_int_offset += 1
	#while flags:
		#var lsb := flags & -flags
		#var i: int = BIT_INDEXES[lsb] + bits_offset
		#array[i] = _float_data[_float_offset]
		#_float_offset += 1
		#flags &= ~lsb


func set_ints_dirty(array: Array[int]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var more_dirty := 1
	while more_dirty:
		var flags := _int_data[_int_offset]
		_int_offset += 1
		more_dirty = flags & SIGN_BIT
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			array[index] = _int_data[_int_offset]
			_int_offset += 1
			flags &= ~lsb
		flag_index += 1
	
	#var flags := _int_data[_int_offset]
	#_int_offset += 1
	#while flags:
		#var lsb := flags & -flags
		#var i: int = BIT_INDEXES[lsb] + bits_offset
		#array[i] = _int_data[_int_offset]
		#_int_offset += 1
		#flags &= ~lsb


func add_floats_delta(delta_array: Array[float]) -> void:
	const BIT_INDEXES := Utils.BIT_INDEXES
	const SIGN_BIT := 1 << 63
	var flag_index := 0
	var more_dirty := 1
	while more_dirty:
		var flags := _int_data[_int_offset]
		_int_offset += 1
		more_dirty = flags & SIGN_BIT
		flags &= ~SIGN_BIT
		while flags:
			var lsb := flags & -flags
			var index := BIT_INDEXES[lsb] + flag_index * 63
			delta_array[index] += _float_data[_float_offset]
			_float_offset += 1
			flags &= ~lsb
		flag_index += 1
	
	#var flags: int = _int_data[_int_offset]
	#_int_offset += 1
	#while flags:
		#var lsb := flags & -flags
		#var i: int = BIT_INDEXES[lsb] + bits_offset
		#delta_array[i] += _float_data[_float_offset]
		#_float_offset += 1
		#flags &= ~lsb
