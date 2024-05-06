# net_component.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name NetComponent
extends RefCounted

## Abstract base class for data components that are optimized for network sync.
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.


const ivutils := preload("res://addons/ivoyager_core/static/utils.gd")
const utils := preload("res://public/static/utils.gd")
const LOG2_64 := Utils.LOG2_64


# persisted
var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)
@warning_ignore("unused_private_class_variable")
var _dirty := 0

# processing
var _int_data: Array[int]
var _float_data: Array[float]
var _int_offset: int
var _float_offset: int

# indexing & localized
static var tables_aux: Dictionary = ThreadsafeGlobal.tables_aux

@warning_ignore("unused_private_class_variable")
static var _tables: Dictionary = IVTableData.tables
@warning_ignore("unused_private_class_variable")
static var _table_n_rows: Dictionary = IVTableData.table_n_rows



func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# apply delta & dirty flags
	_int_data = data[1]
	_float_data = data[2]
	_int_offset = int_offset
	_float_offset = float_offset


func get_interface_dirty() -> Array:
	return []


# container sync

func _get_ints_dirty(array: Array[int], flags: int, bits_offset := 0) -> void:
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		_int_data.append(array[i])
		flags &= ~lsb


func _get_floats_dirty(array: Array[float], flags: int, bits_offset := 0) -> void:
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		_float_data.append(array[i])
		flags &= ~lsb


func _take_floats_delta(base: Array[float], delta: Array[float], flags: int, bits_offset := 0
		) -> void:
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		base[i] += delta[i]
		_float_data.append(delta[i])
		delta[i] = 0.0
		flags &= ~lsb


func _set_floats_dirty(array: Array[float], bits_offset := 0) -> int:
	var flags := _int_data[_int_offset]
	_int_offset += 1
	var return_flags := flags
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		array[i] = _float_data[_float_offset]
		_float_offset += 1
		flags &= ~lsb
	return return_flags


func _set_ints_dirty(array: Array[int], bits_offset := 0) -> int:
	var flags := _int_data[_int_offset]
	_int_offset += 1
	var return_flags := flags
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		array[i] = _int_data[_int_offset]
		_int_offset += 1
		flags &= ~lsb
	return return_flags


func _add_floats_delta(delta_array: Array[float], bits_offset := 0) -> int:
	var flags: int = _int_data[_int_offset]
	_int_offset += 1
	var return_flags := flags
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		delta_array[i] += _float_data[_float_offset]
		_float_offset += 1
		flags &= ~lsb
	return return_flags


