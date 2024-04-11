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

enum { # _dirty
	DIRTY_REVENUE = 1,
}


# interface sync
var _revenue := 0.0 # positive values of INC_STMT_GROSS
var _accountings: Array[float]

# TODO:
# var items: Dictionary # facility only?


func _init(is_new := false) -> void:
	if !is_new: # game load
		return
	
	# debug dev
	var n_accountings := 10
	_accountings = ivutils.init_array(n_accountings, 0.0, TYPE_FLOAT)

# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_revenue = data[1]
	_accountings = data[2]


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
	
	if dirty & DIRTY_REVENUE:
		_revenue += _float_data[_float_offset]
		_float_offset += 1
	
	_add_floats_delta(_accountings)

