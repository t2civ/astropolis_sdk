# net_ref.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name NetRef
extends RefCounted

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# Abstract base class for data classes that are optimized for network sync.
# Only changes are synched. Most NetRef changes are synched at Facility level
# and propagated to Body, Player and Proxies. Exception: Compositions are
# synched at Body level without propagation.

const ivutils := preload("res://addons/ivoyager_core/static/utils.gd")
const utils := preload("res://public/static/utils.gd")
const LOG2_64 := Utils.LOG2_64

const PERSIST_MODE := IVEnums.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = [
	&"run_qtr",
	&"_dirty",
]

# persisted
var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)
@warning_ignore("unused_private_class_variable")
var _dirty := 0

# processing
var _float_data: Array[float]
var _int_data: Array[int]
var _float_offset: int
var _int_offset: int

# indexing & localized
static var tables_aux: Dictionary = ThreadsafeGlobal.tables_aux

@warning_ignore("unused_private_class_variable")
static var _tables: Dictionary = IVTableData.tables
@warning_ignore("unused_private_class_variable")
static var _table_n_rows: Dictionary = IVTableData.table_n_rows



func get_server_init() -> Array:
	return IVSaveUtils.get_persist_properties(self)


func set_server_init(data: Array) -> void:
	IVSaveUtils.set_persist_properties(self, data)


func take_server_delta(_data: Array) -> void:
	# facility accumulator only; zero accumulators and dirty flags
	pass


func add_server_delta(_data: Array) -> void:
	# any target
	pass


func get_interface_dirty() -> Array:
	return []


func sync_interface_dirty(_data: Array) -> void:
	pass


# container sync

func _append_dirty_ints(array: Array[int], flags: int, bits_offset := 0) -> void:
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		_int_data.append(array[i])
		flags &= ~lsb


func _append_dirty_floats(array: Array[float], flags: int, bits_offset := 0) -> void:
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		_float_data.append(array[i])
		flags &= ~lsb


func _append_and_zero_dirty_floats(array: Array[float], flags: int, bits_offset := 0) -> void:
	_int_data.append(flags)
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		_float_data.append(array[i])
		array[i] = 0.0
		flags &= ~lsb


func _set_dirty_ints(array: Array[int], bits_offset := 0) -> void:
	var flags := _int_data[_int_offset]
	_int_offset += 1
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		array[i] = _int_data[_int_offset]
		_int_offset += 1
		flags &= ~lsb


func _set_dirty_floats(array: Array[float], bits_offset := 0) -> void:
	var flags := _int_data[_int_offset]
	_int_offset += 1
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		array[i] = _float_data[_float_offset]
		_float_offset += 1
		flags &= ~lsb


func _add_dirty_floats(array: Array[float], bits_offset := 0) -> void:
	var flags: int = _int_data[_int_offset]
	_int_offset += 1
	while flags:
		var lsb := flags & -flags
		var i: int = LOG2_64[lsb] + bits_offset
		array[i] += _float_data[_float_offset]
		_float_offset += 1
		flags &= ~lsb

