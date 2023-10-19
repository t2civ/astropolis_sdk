# financials.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name Financials
extends NetRef

# Changes propagate from Facility to Player only.
#
# Income and cash flow items are cummulative for current quarter.
# Balance items are running.

enum { # _dirty
	DIRTY_REVENUE = 1,
}

const PERSIST_PROPERTIES2: Array[StringName] = [
	&"revenue",
	&"accountings",
	&"_dirty_accountings",
]

# interface sync
var revenue := 0.0 # positive values of INC_STMT_GROSS
var accountings: Array[float]

# TODO:
# var items: Dictionary # facility only?


var _dirty_accountings := 0


func _init(is_new := false) -> void:
	if !is_new: # game load
		return
	
	# debug dev
	var n_accountings := 10
	
	accountings = ivutils.init_array(n_accountings, 0.0, TYPE_FLOAT)


func take_server_delta(data: Array) -> void:
	# facility accumulator only; zero accumulators and dirty flags
	
	_int_data = data[0]
	_float_data = data[1]
	
	_int_data[6] = _int_data.size()
	_int_data[7] = _float_data.size()
	
	_int_data.append(_dirty)
	if _dirty & DIRTY_REVENUE:
		_float_data.append(revenue)
		revenue = 0.0
	_dirty = 0
	
	_append_and_zero_dirty_floats(accountings, _dirty_accountings)
	_dirty_accountings = 0


func add_server_delta(data: Array) -> void:
	# any target; reference safe
	
	_int_data = data[0]
	_float_data = data[1]
	
	_int_offset = _int_data[6]
	_float_offset = _int_data[7]
	
	var svr_qtr := _int_data[0]
	run_qtr = svr_qtr # TODO: histories
	
	var flags := _int_data[_int_offset]
	_int_offset += 1
	if flags & DIRTY_REVENUE:
		revenue += _float_data[_float_offset]
		_float_offset += 1
	
	_add_dirty_floats(accountings)

