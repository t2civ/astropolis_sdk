# trader_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name TraderInterface
extends Interface

# A Trader buys and sells resources at a Body for a specific Facility.
#
# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# To modify AI, see comments in '_base_ai.gd' files.
#
# Warning! This object lives and dies on the AI thread! Containers and many
# methods are not threadsafe. Accessing non-container properties is safe.

static var trader_interfaces: Array[TraderInterface] = [] # indexed by trader_id

# immutable post-init
var trader_id := -1
var facility_id := -1
var body_id := -1
var local := false
var facility: FacilityInterface
var body: BodyInterface

# sync from server (DIRTY_BASE)
var temp_placeholder := 0.0


func _init() -> void:
	super()
	entity_type = ENTITY_TRADER


# *****************************************************************************
# sync from server

func set_network_init(data: Array) -> void:
	trader_id = data[2]
	name = data[3]
	facility_id = data[4]
	body_id = data[5]
	local = data[6]
	temp_placeholder = data[7]
	facility = FacilityInterface.facility_interfaces[facility_id]
	assert(facility)
	body = BodyInterface.body_interfaces[body_id]
	assert(body)


func sync_server_dirty(data: Array) -> void:
	var offsets: Array[int] = data[0]
	var int_data: Array[int] = data[1]
	var dirty: int = offsets[0]
	if dirty & DIRTY_BASE:
		var float_data: Array[float] = data[2]
		temp_placeholder = float_data[0]
	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated
