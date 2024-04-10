# interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name Interface
extends RefCounted

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# To modify AI, see comments in '_base_ai.gd' files.
#
# Warning! This object lives and dies on the AI thread! Containers and many
# methods are not threadsafe. Accessing non-container properties is safe.


signal interface_changed(entity_type: int, entity_id: int, data: Array) # on ai thread only!

# don't emit these directly; use API below
signal persist_data_changed(network_id: int, data: Array)


enum DirtyFlags {
	DIRTY_QUARTER = 1,
	DIRTY_BASE = 1 << 1,
	DIRTY_OPERATIONS = 1 << 2,
	DIRTY_INVENTORY = 1 << 3,
	DIRTY_FINANCIALS = 1 << 4,
	DIRTY_POPULATION = 1 << 5,
	DIRTY_BIOME = 1 << 6,
	DIRTY_METAVERSE = 1 << 7,
	DIRTY_COMPOSITIONS = 1 << 8,
}

const DIRTY_QUARTER := DirtyFlags.DIRTY_QUARTER
const DIRTY_BASE := DirtyFlags.DIRTY_BASE
const DIRTY_OPERATIONS := DirtyFlags.DIRTY_OPERATIONS
const DIRTY_INVENTORY := DirtyFlags.DIRTY_INVENTORY
const DIRTY_FINANCIALS := DirtyFlags.DIRTY_FINANCIALS
const DIRTY_POPULATION := DirtyFlags.DIRTY_POPULATION
const DIRTY_BIOME := DirtyFlags.DIRTY_BIOME
const DIRTY_METAVERSE := DirtyFlags.DIRTY_METAVERSE
const DIRTY_COMPOSITIONS := DirtyFlags.DIRTY_COMPOSITIONS

enum EntityType {
	ENTITY_FACILITY,
	ENTITY_PLAYER,
	ENTITY_BODY,
	ENTITY_JOIN,
	ENTITY_EXCHANGE,
	ENTITY_MARKET,
	ENTITY_TRADER,
	ENTITY_SERVER,
	ENTITY_INTERFACE,
	N_ENTITY_TYPES,
}

const ENTITY_FACILITY := EntityType.ENTITY_FACILITY
const ENTITY_PLAYER := EntityType.ENTITY_PLAYER
const ENTITY_BODY := EntityType.ENTITY_BODY
const ENTITY_JOIN := EntityType.ENTITY_JOIN
const ENTITY_EXCHANGE := EntityType.ENTITY_EXCHANGE
const ENTITY_MARKET := EntityType.ENTITY_MARKET
const ENTITY_TRADER := EntityType.ENTITY_TRADER
const N_ENTITY_TYPES := EntityType.N_ENTITY_TYPES
const ENTITY_SERVER := EntityType.ENTITY_SERVER
const ENTITY_INTERFACE := EntityType.ENTITY_INTERFACE

enum ComponentType {
	COMPONENT_OPERATIONS,
	COMPONENT_INVENTORY,
	COMPONENT_FINANCIALS,
	COMPONENT_POPULATION,
	COMPONENT_BIOME,
	COMPONENT_METAVERSE,
	COMPONENT_COMPOSITION,
	N_COMPONENT_TYPES,
}

const COMPONENT_OPERATIONS := ComponentType.COMPONENT_OPERATIONS
const COMPONENT_INVENTORY := ComponentType.COMPONENT_INVENTORY
const COMPONENT_FINANCIALS := ComponentType.COMPONENT_FINANCIALS
const COMPONENT_POPULATION := ComponentType.COMPONENT_POPULATION
const COMPONENT_BIOME := ComponentType.COMPONENT_BIOME
const COMPONENT_METAVERSE := ComponentType.COMPONENT_METAVERSE
const COMPONENT_COMPOSITION := ComponentType.COMPONENT_COMPOSITION
const N_COMPONENT_TYPES := ComponentType.N_COMPONENT_TYPES

const LOG2_64 := Utils.LOG2_64

const INTERVAL := 7.0 * IVUnits.DAY


static var interfaces: Array[Interface] = [] # indexed by interface_id
static var interfaces_by_name := {} # PLANET_EARTH, PLAYER_NASA, JOIN_OFFWORLD, etc.


var interface_id := -1
var entity_type := -1 # server entity
var name := &"" # unique & immutable
var gui_name := "" # mutable for display ("" for player means hide from GUI)
var run_qtr := -1 # year * 4 + (quarter - 1); never set for BodyInterface w/out a facility
var last_interval := -INF
var next_interval := -INF

# Append member names for save/load persistence; nested containers ok; NO OBJECTS!
# Must be set at _init()!
var persist := [
	&"run_qtr",
	&"last_interval",
	&"next_interval",
]

var use_this_ai := false # read-only

# localized globals
static var tables_aux: Dictionary = ThreadsafeGlobal.tables_aux

@warning_ignore("unused_private_class_variable")
static var _times: Array = IVGlobal.times # [time (s, J2000), engine_time (s), solar_day (d)] (floats)
@warning_ignore("unused_private_class_variable")
static var _date: Array = IVGlobal.date # Gregorian [year, month, day] (ints)
@warning_ignore("unused_private_class_variable")
static var _clock: Array = IVGlobal.clock # UT [hour, minute, second] (ints)
@warning_ignore("unused_private_class_variable")
static var _tables: Dictionary = IVTableData.tables
@warning_ignore("unused_private_class_variable")
static var _table_n_rows: Dictionary = IVTableData.table_n_rows

# private
var _dirty := 0
@warning_ignore("unused_private_class_variable")
var _is_local_player := false # gives GUI access
@warning_ignore("unused_private_class_variable")
var _is_server_ai := false
@warning_ignore("unused_private_class_variable")
var _is_local_use_ai := false # local player sets/unsets


func _init() -> void:
	IVGlobal.about_to_free_procedural_nodes.connect(_clear_circular_references)


func remove() -> void:
	_clear_circular_references()


static func get_interface_by_name(interface_name: StringName) -> Interface:
	# Returns null if doesn't exist.
	return interfaces_by_name.get(interface_name)


# override below if applicable

func has_development() -> bool:
	return false


func has_markets() -> bool:
	return false


func get_development_population(_population_type := -1) -> float:
	return 0.0


func get_development_economy() -> float:
	return 0.0


func get_development_energy() -> float:
	return 0.0


func get_development_manufacturing() -> float:
	return 0.0


func get_development_constructions() -> float:
	return 0.0


func get_development_computations() -> float:
	return 0.0


func get_development_information() -> float:
	return 0.0


func get_development_bioproductivity() -> float:
	return 0.0


func get_development_biomass() -> float:
	return 0.0


func get_development_biodiversity() -> float:
	return 0.0


func get_body_name() -> StringName:
	return &""


func get_body_flags() -> int:
	return 0


func get_player_name() -> StringName:
	return &""


func get_player_class() -> int:
	return -1


func get_polity_name() -> StringName:
	return &""


func get_facilities() -> Array[Interface]:
	# AI thread only!
	return []

# Operations

func get_operation_utilization(operation_type: int) -> float:
	var operations: OperationsNet = get(&"operations")
	if !operations:
		return 0.0
	return operations.get_utilization(operation_type)


func get_operation_electricity(operation_type: int) -> float:
	var operations: OperationsNet = get(&"operations")
	if !operations:
		return 0.0
	return operations.get_electricity(operation_type)


func get_operation_gui_flow(operation_type: int) -> float:
	var operations: OperationsNet = get(&"operations")
	if !operations:
		return 0.0
	return operations.get_gui_flow(operation_type)


func get_operation_est_revenue(operation_type: int) -> float:
	var operations: OperationsNet = get(&"operations")
	if !operations:
		return NAN
	return operations.get_est_revenue(operation_type)


func get_operation_est_gross_margin(operation_type: int) -> float:
	var operations: OperationsNet = get(&"operations")
	if !operations:
		return NAN
	return operations.get_est_gross_margin(operation_type)


func get_op_group_utilization(op_group: int) -> float:
	var operations: OperationsNet = get(&"operations")
	if !operations:
		return 0.0
	return operations.get_group_utilization(op_group)


func get_op_group_electricity(op_group: int) -> float:
	var operations: OperationsNet = get(&"operations")
	if !operations:
		return 0.0
	return operations.get_group_electricity(op_group)


func get_op_group_est_revenue(op_group: int) -> float:
	var operations: OperationsNet = get(&"operations")
	if !operations:
		return 0.0
	return operations.get_group_est_revenue(op_group)


func get_op_group_est_gross_margin(op_group: int) -> float:
	var operations: OperationsNet = get(&"operations")
	if !operations:
		return 0.0
	return operations.get_group_est_gross_margin(op_group)

# Inventory

func get_resource_price(resource_type: int) -> float:
	var inventory: InventoryNet = get(&"inventory")
	if !inventory:
		return NAN
	return inventory.get_price(resource_type)


func get_resource_bid(resource_type: int) -> float:
	var inventory: InventoryNet = get(&"inventory")
	if !inventory:
		return NAN
	return inventory.get_bid(resource_type)


func get_resource_ask(resource_type: int) -> float:
	var inventory: InventoryNet = get(&"inventory")
	if !inventory:
		return NAN
	return inventory.get_ask(resource_type)


func get_resource_contracted(resource_type: int) -> float:
	var inventory: InventoryNet = get(&"inventory")
	if !inventory:
		return NAN
	return inventory.get_contracted(resource_type)


func get_resource_in_stock(resource_type: int) -> float:
	var inventory: InventoryNet = get(&"inventory")
	if !inventory:
		return NAN
	return inventory.get_in_stock(resource_type)

# Financials

func has_financials() -> bool:
	return get(&"financials") != null


# *****************************************************************************
# Main thread public

#func player_use_ai(use_ai: bool) -> void:
#	if !_is_local_player:
#		return
#	_is_local_use_ai = use_ai
#	_reset_ai()


# *****************************************************************************
# AI thread


# subclass overrides

func process_ai(time: float) -> void:
	# Called every one to several frames (unless excessive AI processing). You
	# probably shouldn't override this. Consider process_ai_interval() instead.
	if time > next_interval:
		if next_interval == -INF: # init
			last_interval = time
			next_interval = time + randf_range(0.0, INTERVAL) # stagger AI processing
			process_ai_init()
		else:
			var delta := time - last_interval
			last_interval = time
			while next_interval < time:
				next_interval += INTERVAL
			process_ai_interval(delta)
	if _dirty:
		_sync_ai_changes()


func process_ai_init() -> void:
	# Called once before first process_ai_interval().
	pass


func process_ai_interval(_delta: float) -> void:
	# Called once per INTERVAL (unless excessive AI processing). Most component
	# changes happen every INTERVAL time, so this is a good place for most AI
	# processing.
	pass


func process_ai_new_quarter() -> void:
	# Called after component histories have updated for the new quarter.
	# Never called for BodyInterface w/out a facility.
	pass


# *****************************************************************************
# sync

func set_server_init(_data: Array) -> void:
	pass


func sync_server_dirty(_data: Array) -> void:
	pass


func _sync_ai_changes() -> void:
	_dirty = 0


func propagate_server_delta(_data: Array) -> void:
	pass


# *****************************************************************************
# Private

func _clear_circular_references() -> void:
	# down hierarchy only
	pass

# *****************************************************************************
# Internal main thread

#func set_player(is_local_player: bool, is_server_ai: bool) -> void:
#	_is_local_player = is_local_player
#	_is_server_ai = is_server_ai
#	_reset_ai()
#
#
#func _reset_ai() -> void:
#	use_this_ai = _is_server_ai or (_is_local_player and (_is_local_use_ai or AIGlobal.is_autoplay))
