# trader_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name TraderInterface
extends Interface

## [TraderInterface] is a proxy for a Trader that buys and sells resources at
## an [ExchangeInterface] for a specific [FacilityInterface].
##
## A trader is owned by a facility and trades on its behalf at the hosting
## exchange. The trader may be "local" (exchange at the same body as
## facility) or "remote". Server-side Trader pushes changes to [TraderInterface].
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## To modify AI, see comments in '_base_ai.gd' files.
##
## Warning! This object lives and dies on the AI thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.


## All [TraderInterface] instances, indexed by [member trader_id].
static var trader_interfaces: Array[TraderInterface] = []

static var _is_class_instanced := false
static var _n_resources: int

# immutable post-init
var trader_id := -1  ## Index into [member trader_interfaces].
var facility_id := -1  ## [member FacilityInterface.facility_id] this trader belongs to.
var local: bool ## Is trader facility at this exchange body? Otherwise, "remote".
var facility: FacilityInterface  ## Owning [FacilityInterface].
var exchange: ExchangeInterface  ## Hosting [ExchangeInterface].

var has_remote_stores := false ## Remote trader has resources at a facility (awaiting transport).


static func _on_class_instanced() -> void:
	_n_resources = IVTableData.table_n_rows[&"resources"]


func _init() -> void:
	const ENTITY_TRADER := Interface.EntityType.ENTITY_TRADER
	if !_is_class_instanced:
		_is_class_instanced = true
		_on_class_instanced()
	super()
	entity_type = ENTITY_TRADER


# *****************************************************************************
# sync from server

func set_network_init(data: Array) -> void:
	trader_id = data[2]
	name = data[3]
	facility_id = data[4]
	var exchange_name: StringName = data[5]
	local = data[6]
	has_remote_stores = data[7]
	facility = FacilityInterface.facility_interfaces[facility_id]
	assert(facility)
	exchange = interfaces_by_name[exchange_name]
	assert(exchange)


func sync_server_dirty(data: Array) -> void:
	const DIRTY_TRADER := Interface.DirtyFlags.DIRTY_TRADER
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]
	var k := 1

	if dirty & DIRTY_TRADER:
		has_remote_stores = int_data[offsets[k]] != 0
		k += 2

	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated
