# financials_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name FinancialsNet
extends NetComponent

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# Changes propagate from Facility to Player only.
#
# Income and cash flow items are cummulative for current quarter.
# Balance items are running.
#
# TODO: Make interface component w/out server dirty flags & delta accumulators

enum { # _dirty
	DIRTY_REVENUE = 1,
}

const PERSIST_PROPERTIES2: Array[StringName] = [
	&"_revenue",
	&"_delta_revenue",
	&"_accountings",
	&"_delta_accountings",
	
	&"_dirty_accountings",
]

# interface sync
var _revenue := 0.0 # positive values of INC_STMT_GROSS
var _delta_revenue := 0.0
var _accountings: Array[float]
var _delta_accountings: Array[float]

# TODO:
# var items: Dictionary # facility only?

var _dirty_accountings := 0 # max 64


func _init(is_new := false) -> void:
	if !is_new: # game load
		return
	
	# debug dev
	var n_accountings := 10
	_accountings = ivutils.init_array(n_accountings, 0.0, TYPE_FLOAT)
	_delta_accountings = _accountings.duplicate()


func take_dirty(data: Array) -> void:
	# save delta in data, apply & zero delta, reset dirty flags
	
	_int_data = data[1]
	_float_data = data[2]
	
	_int_data.append(_dirty)
	if _dirty & DIRTY_REVENUE:
		_float_data.append(_delta_revenue)
		_revenue += _delta_revenue
		_delta_revenue = 0.0
	
	_take_floats_delta(_accountings, _delta_accountings, _dirty_accountings)
	
	_dirty = 0
	_dirty_accountings = 0


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# apply delta & dirty flags
	_int_data = data[1]
	_float_data = data[2]
	_int_offset = int_offset
	_float_offset = float_offset
	
	var svr_qtr := _int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	var dirty := _int_data[_int_offset]
	_int_offset += 1
	_dirty |= dirty
	if dirty & DIRTY_REVENUE:
		_delta_revenue += _float_data[_float_offset]
		_float_offset += 1
	
	_dirty_accountings |= _add_floats_delta(_accountings)

