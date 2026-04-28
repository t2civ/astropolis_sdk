# financials_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name FinancialsNet
extends RefCounted

## Net-synced financials component held by [FacilityInterface],
## [PlayerInterface], or player-specific [JoinInterface]s.
##
## Holds revenue, gross output, cost of goods sold, additional accountings,
## and per-item history (last N quarters). Income and cash-flow items are
## cumulative within the current quarter; balance items are running. "lfq"
## means last four quarters (or fewer if < 1 yr history). Changes propagate
## from facility to player or to facility/player joins only.
##
## Server-side Financials pushes changes to [FinancialsNet] via sync.
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## Warning! Like [Interface], this object is touched on the AI thread.
## Containers and many methods are not threadsafe; accessing non-container
## properties is safe.


## Bit flags marking which scalar fields of this component are dirty for sync.
enum {
	DIRTY_REVENUE = 1,
	DIRTY_GROSS_OUTPUT = 1 << 1,
	DIRTY_COST_OF_GOODS_SOLD = 1 << 2,
}


# interface sync
## Quarterly clock at last sync, as [code]year * 4 + (quarter - 1)[/code].
var run_qtr := -1
var _revenue := 0.0 # positive
var _gross_output := 0.0 # = all producer revenue (exludes resellers, tax revenue, etc.)
var _cost_of_goods_sold := 0.0 # positive
var _accountings: Array[float] # TODO: e.g., MINING_REVENUE, MINING_COGS, etc.

# history
var _revenue_history: Array[float] = []
var _gross_output_history: Array[float] = []
var _cost_of_goods_sold_history: Array[float] = []
var _accountings_history: Array[Array] = []

var _sync := SyncHelper.new()

var _n_accountings := 10 # WIP



func _init(is_new := false) -> void:
	const arrays := preload("uid://bv7xrcpcm24nc")
	if !is_new: # game load
		return
	
	# debug dev
	_accountings = arrays.init_array(_n_accountings, 0.0, TYPE_FLOAT)


# ********************************** READ *************************************
# NOT ALL THREADSAFE !!!!

## Returns revenue summed over the last four quarters (or all available if
## history is shorter).
func get_revenue_lfq() -> float:
	var sum := 0.0
	var n_qtrs := mini(_revenue_history.size(), 4)
	for i in n_qtrs:
		sum += _revenue_history[-i]
	return sum


## Returns gross output summed over the last four quarters (or all available
## if history is shorter).
func get_gross_output_lfq() -> float:
	var sum := 0.0
	var n_qtrs := mini(_gross_output_history.size(), 4)
	for i in n_qtrs:
		sum += _gross_output_history[-i]
	return sum




# ********************************** SYNC *************************************

## Initializes this component from the server-supplied init payload.
func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_revenue = data[1]
	_gross_output = data[2]
	_cost_of_goods_sold = data[3]
	_accountings = data[4]
	_revenue_history = data[5]
	_gross_output_history = data[6]
	_cost_of_goods_sold_history = data[7]
	_accountings_history = data[8]


## Applies a server-supplied dirty payload, updating fields whose dirty flags
## are set and rolling quarter history if the server quarter advanced.
func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]

	var dirty := int_data[int_offset]
	int_offset += 1
	
	if dirty & DIRTY_REVENUE:
		_revenue += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_GROSS_OUTPUT:
		_gross_output += float_data[float_offset]
		float_offset += 1
	if dirty & DIRTY_COST_OF_GOODS_SOLD:
		_cost_of_goods_sold += float_data[float_offset]
		float_offset += 1
	
	_sync.init_for_add(int_data, float_data, int_offset, float_offset)
	_sync.add_floats_delta(_accountings)
	
	# finished quarter?
	var svr_qtr := int_data[0]
	assert(svr_qtr >= run_qtr)
	if svr_qtr > run_qtr:
		_update_quarter(svr_qtr)


func _update_quarter(svr_qtr: int) -> void:
	# Server & interface do this in parallel, so no history sync needed.
	if run_qtr == -1: # no history to save yet
		run_qtr = svr_qtr
		return
	
	while run_qtr < svr_qtr: # loop for edge-case missed quarter
		
		_revenue_history.append(_revenue)
		_gross_output_history.append(_gross_output)
		_cost_of_goods_sold_history.append(_cost_of_goods_sold)
		_accountings_history.append(_accountings.duplicate())
		
		run_qtr += 1
	
	# zero income & cash flow items
	_revenue = 0.0
	_gross_output = 0.0
	_cost_of_goods_sold = 0.0
	# TODO: zero _accountings for income & cf items only
