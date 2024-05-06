# population_net.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name PopulationNet
extends RefCounted

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# Arrays indexed by population_type unless noted otherwise.

const ivutils := preload("res://addons/ivoyager_core/static/utils.gd")
const utils := preload("res://public/static/utils.gd")

# All data flows server -> interface.
var run_qtr := -1 # last sync, = year * 4 + (quarter - 1)
var _numbers: Array[float]
var _intrinsic_growths: Array[float] # Facility only
var _carrying_capacities: Array[float] # Facility only; indexed by carrying_capacity_group
var _migration_pressures: Array[float] # Facility only; +/- emigration/immigration

var _history_numbers: Array[Array] # Array for ea pop type; [..., qrt_before_last, last_qrt]

var _is_facility := false

var _sync := SyncHelper.new()

static var _tables: Dictionary = IVTableData.tables
static var _table_n_rows: Dictionary = IVTableData.table_n_rows
static var _n_populations: int
static var _table_populations: Dictionary
static var _carrying_capacity_groups: Array[int]
static var _carrying_capacity_group2s: Array[int]
static var _is_class_instanced := false


func _init(is_new := false, is_facility_ := false) -> void:
	if !_is_class_instanced:
		_is_class_instanced = true
		_n_populations = _table_n_rows[&"populations"]
		_table_populations = _tables[&"populations"]
		_carrying_capacity_groups = _table_populations[&"carrying_capacity_group"]
		_carrying_capacity_group2s = _table_populations[&"carrying_capacity_group2"]
	if !is_new: # game load
		return
	_numbers = ivutils.init_array(_n_populations, 0.0, TYPE_FLOAT)
	_history_numbers = ivutils.init_array(_n_populations, [] as Array[float], TYPE_ARRAY)
	if !is_facility_:
		return
	_is_facility = true
	_intrinsic_growths = _numbers.duplicate()
	var n_carrying_capacity_groups: int = _table_n_rows.carrying_capacity_groups
	_carrying_capacities = ivutils.init_array(n_carrying_capacity_groups, 0.0, TYPE_FLOAT)
	_migration_pressures = _numbers.duplicate()


# ********************************* READ **************************************


func get_number(type := -1) -> float:
	if type == -1:
		return utils.get_float_array_sum(_numbers)
	return _numbers[type]


func get_intrinsic_growth(type: int) -> float:
	assert(_is_facility)
	return _intrinsic_growths[type]


func get_carrying_capacity(carrying_capacity_group: int) -> float:
	assert(_is_facility)
	return _carrying_capacities[carrying_capacity_group]


func get_carrying_capacity_for_population(type: int) -> float:
	# sums the _carrying_capacities that this population can occupy
	assert(_is_facility)
	var group: int = _carrying_capacity_groups[type]
	var group2: int = _carrying_capacity_group2s[type]
	var carrying_capacity: float = _carrying_capacities[group]
	if group2 != -1:
		carrying_capacity += _carrying_capacities[group2]
	return carrying_capacity


func get_number_for_carrying_capacity_group(carrying_capacity_group: int) -> float:
	# sums all populations that share this carrying_capacity_group
	assert(_is_facility)
	var number := 0.0
	var i := 0
	while i < _n_populations:
		if (_carrying_capacity_groups[i] == carrying_capacity_group
				or _carrying_capacity_group2s[i] == carrying_capacity_group):
			number += _numbers[i]
		i += 1
	return number


# ********************************* SYNC **************************************

func set_network_init(data: Array) -> void:
	run_qtr = data[0]
	_numbers = data[1]
	_intrinsic_growths = data[2]
	_carrying_capacities = data[3]
	_migration_pressures = data[4]
	_history_numbers = data[5]
	_is_facility = data[6]


func add_dirty(data: Array, int_offset: int, float_offset: int) -> void:
	# Changes and sets from the server entity.
	
	var int_data: Array[int] = data[1]
	var float_data: Array[float] = data[2]
	
	var svr_qtr: int = int_data[0]
	if run_qtr < svr_qtr:
		_update_history(svr_qtr) # before new quarter changes
	
	_sync.init(int_data, float_data, int_offset, float_offset)
	_sync.add_floats_delta(_numbers)
	
	if !_is_facility:
		return
	
	_sync.set_floats_dirty(_intrinsic_growths)
	_sync.set_floats_dirty(_carrying_capacities)
	_sync.set_floats_dirty(_migration_pressures)


func _update_history(svr_qtr: int) -> void:
	if run_qtr == -1: # new - no history to save yet
		run_qtr = svr_qtr
		return
	while run_qtr < svr_qtr: # loop in case we missed a quarter
		var i := 0
		while i < _n_populations:
			_history_numbers[i].append(_numbers[i])
			i += 1
		run_qtr += 1

