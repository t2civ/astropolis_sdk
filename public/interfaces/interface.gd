# interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name Interface
extends RefCounted

## Base class for entity proxies between AI/GUI clients and the game server.
##
## All GUI and in-game AI interaction with game internals goes through an
## [Interface]. Subclasses include [FacilityInterface], [PlayerInterface],
## [BodyInterface], [JoinInterface], [TraderInterface], and
## [ExchangeInterface]. Each is paired with a server-side entity that pushes
## changes via sync methods. A few "player control" properties have reverse
## interface -> server data flow.
##
## Components attached to an [Interface] are net-sync objects: [OperationsNet],
## [InventoryNet], [FinancialsNet], [PopulationNet], [BiomeNet],
## [CyberspaceNet], and [StratumNet].
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## To modify AI, see comments in '_base_ai.gd' files.
##
## Warning! This object lives and dies on the AI thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.


## Emitted on the AI thread when this interface's mirrored state changes;
## payload is consumed by the sync layer on the receiver side. AI thread only!
signal interface_changed(entity_type: int, entity_id: int, data: Array)

## Emitted when persistent (saveable) data changes. Don't emit this directly;
## mark the relevant dirty flag and let the sync layer emit.
signal persist_data_changed(network_id: int, data: Array)


## Bit flags marking which parts of an [Interface] (and its components) are
## dirty for sync. Use the [code]DIRTY_*[/code] constant aliases below.
enum DirtyFlags {
	DIRTY_QUARTER = 1,
	DIRTY_BASE = 1 << 1,
	DIRTY_OPERATIONS = 1 << 2,
	DIRTY_INVENTORY = 1 << 3,
	DIRTY_FINANCIALS = 1 << 4,
	DIRTY_POPULATION = 1 << 5,
	DIRTY_BIOME = 1 << 6,
	DIRTY_CYBERSPACE = 1 << 7,
	DIRTY_EXCHANGE = 1 << 8,
	DIRTY_STRATA = 1 << 9,
}

## Bit flag: [member run_qtr] advanced; quarterly histories may need rollover.
const DIRTY_QUARTER := DirtyFlags.DIRTY_QUARTER
## Bit flag: base entity properties have changed (e.g. [member gui_name]).
const DIRTY_BASE := DirtyFlags.DIRTY_BASE
## Bit flag: [OperationsNet] has dirty data to sync.
const DIRTY_OPERATIONS := DirtyFlags.DIRTY_OPERATIONS
## Bit flag: [InventoryNet] has dirty data to sync.
const DIRTY_INVENTORY := DirtyFlags.DIRTY_INVENTORY
## Bit flag: [FinancialsNet] has dirty data to sync.
const DIRTY_FINANCIALS := DirtyFlags.DIRTY_FINANCIALS
## Bit flag: [PopulationNet] has dirty data to sync.
const DIRTY_POPULATION := DirtyFlags.DIRTY_POPULATION
## Bit flag: [BiomeNet] has dirty data to sync.
const DIRTY_BIOME := DirtyFlags.DIRTY_BIOME
## Bit flag: [CyberspaceNet] has dirty data to sync.
const DIRTY_CYBERSPACE := DirtyFlags.DIRTY_CYBERSPACE
## Bit flag: [ExchangeInterface] state has dirty data to sync.
const DIRTY_EXCHANGE := DirtyFlags.DIRTY_EXCHANGE
## Bit flag: strata data has changed.
const DIRTY_STRATA := DirtyFlags.DIRTY_STRATA

## Identifies the kind of server entity an [Interface] proxies. Use the
## [code]ENTITY_*[/code] constant aliases below. [code]N_ENTITY_TYPES[/code]
## is the count of real types; [code]ENTITY_SERVER[/code] and
## [code]ENTITY_INTERFACE[/code] are extra sync-routing markers.
enum EntityType {
	ENTITY_FACILITY,
	ENTITY_PLAYER,
	ENTITY_BODY,
	ENTITY_JOIN,
	ENTITY_EXCHANGE,
	ENTITY_TRADER,
	ENTITY_SERVER,
	ENTITY_INTERFACE,
	N_ENTITY_TYPES,
}

const ENTITY_FACILITY := EntityType.ENTITY_FACILITY  ## See [enum EntityType].
const ENTITY_PLAYER := EntityType.ENTITY_PLAYER  ## See [enum EntityType].
const ENTITY_BODY := EntityType.ENTITY_BODY  ## See [enum EntityType].
const ENTITY_JOIN := EntityType.ENTITY_JOIN  ## See [enum EntityType].
const ENTITY_EXCHANGE := EntityType.ENTITY_EXCHANGE  ## See [enum EntityType].
const ENTITY_TRADER := EntityType.ENTITY_TRADER  ## See [enum EntityType].
const N_ENTITY_TYPES := EntityType.N_ENTITY_TYPES  ## See [enum EntityType].
const ENTITY_SERVER := EntityType.ENTITY_SERVER  ## See [enum EntityType].
const ENTITY_INTERFACE := EntityType.ENTITY_INTERFACE  ## See [enum EntityType].

## Identifies which net-sync component on an [Interface] a sync payload
## targets. Use the [code]COMPONENT_*[/code] constant aliases below.
enum ComponentType {
	COMPONENT_OPERATIONS,
	COMPONENT_INVENTORY,
	COMPONENT_FINANCIALS,
	COMPONENT_POPULATION,
	COMPONENT_BIOME,
	COMPONENT_CYBERSPACE,
	COMPONENT_STRATUM,
	N_COMPONENT_TYPES,
}

const COMPONENT_OPERATIONS := ComponentType.COMPONENT_OPERATIONS  ## See [enum ComponentType].
const COMPONENT_INVENTORY := ComponentType.COMPONENT_INVENTORY  ## See [enum ComponentType].
const COMPONENT_FINANCIALS := ComponentType.COMPONENT_FINANCIALS  ## See [enum ComponentType].
const COMPONENT_POPULATION := ComponentType.COMPONENT_POPULATION  ## See [enum ComponentType].
const COMPONENT_BIOME := ComponentType.COMPONENT_BIOME  ## See [enum ComponentType].
const COMPONENT_CYBERSPACE := ComponentType.COMPONENT_CYBERSPACE  ## See [enum ComponentType].
const COMPONENT_STRATUM := ComponentType.COMPONENT_STRATUM  ## See [enum ComponentType].
const N_COMPONENT_TYPES := ComponentType.N_COMPONENT_TYPES  ## See [enum ComponentType].


## Wall-clock time between [method process_ai_interval] calls (one game week).
const INTERVAL := 7.0 * IVUnits.DAY


## All [Interface] instances, indexed by [member interface_id]. AI thread only.
static var interfaces: Array[Interface] = []
## All [Interface] instances keyed by [member name] (e.g. [code]&"PLAYER_NASA"[/code],
## [code]&"JOIN_OFFWORLD"[/code]). AI thread only.
static var interfaces_by_name: Dictionary[StringName, Interface] = {}

## Shared bus for AI-thread signals between interfaces and the AI layer.
static var ai_bus := AIBus.new()


var interface_id := -1  ## Index into [member interfaces].
var entity_type := -1  ## See [enum EntityType]. Set by subclass [code]_init()[/code].
var name := &""  ## Unique, immutable identifier (e.g. [code]&"PLAYER_NASA"[/code]).
var gui_name := ""  ## Display name; mutable. Empty player gui_name hides from GUI.
## Quarterly clock as [code]year * 4 + (quarter - 1)[/code]. Never set for a
## [BodyInterface] without a facility.
var run_qtr := -1
var last_interval := -INF  ## Time of last [method process_ai_interval] call.
var next_interval := -INF  ## Time of next [method process_ai_interval] call.

## Member names persisted by save/load. Append in subclass [code]_init()[/code].
## Nested containers are ok; NO OBJECTS!
var persist := [
	&"run_qtr",
	&"last_interval",
	&"next_interval",
]

## True if this interface should run AI logic this frame. Read-only; managed
## by the AI/server-control machinery.
var use_this_ai := false

@warning_ignore("unused_private_class_variable")
static var _times: Array = IVGlobal.times
@warning_ignore("unused_private_class_variable")
static var _date: Array = IVGlobal.date
@warning_ignore("unused_private_class_variable")
static var _clock: Array = IVGlobal.clock
@warning_ignore("unused_private_class_variable")
static var _db_tables := IVTableData.db_tables
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
	IVStateManager.about_to_free_procedural_nodes.connect.call_deferred(_clear_circular_references)


## Tears down references on this interface so it can be freed cleanly.
## Subclasses override to also detach from related interfaces (body, player,
## etc.) before chaining to [code]super()[/code].
func remove() -> void:
	_clear_circular_references()


## Returns the [Interface] with the given [param interface_name], or null if
## no such interface exists. AI thread only.
static func get_interface_by_name(interface_name: StringName) -> Interface:
	return interfaces_by_name.get(interface_name)


# override below if applicable

## Returns true if this interface contributes development statistics
## (population, economy, power, manufacturing, etc.). Default false.
func has_development() -> bool:
	return false


## Returns true if this interface participates in markets. Default false.
func has_markets() -> bool:
	return false


## Returns the development "population" total, optionally filtered to a
## specific [param population_type] (-1 for total). Default 0.0.
func get_development_population(_population_type := -1) -> float:
	return 0.0


## Returns the development "economy" total (gross output). Default 0.0.
func get_development_economy() -> float:
	return 0.0


## Returns the development "power" total (electrical generation). Default 0.0.
func get_development_power() -> float:
	return 0.0


## Returns the development "manufacturing" total. Default 0.0.
func get_development_manufacturing() -> float:
	return 0.0


## Returns the development "constructions" total (mass constructed). Default 0.0.
func get_development_constructions() -> float:
	return 0.0


## Returns the development "computation" total. Default 0.0.
func get_development_computation() -> float:
	return 0.0


## Returns the development "information" total. Default 0.0.
func get_development_information() -> float:
	return 0.0


## Returns the development "bioproductivity" total. Default 0.0.
func get_development_bioproductivity() -> float:
	return 0.0


## Returns the development "biomass" total. Default 0.0.
func get_development_biomass() -> float:
	return 0.0


## Returns the development "biodiversity" metric (0.0–1.0). Default 0.0.
func get_development_biodiversity() -> float:
	return 0.0


## Returns the [member name] of this interface's [BodyInterface], or
## [code]&""[/code] if not applicable.
func get_body_name() -> StringName:
	return &""


## Returns body flags for this interface's [BodyInterface] (see ivoyager
## [code]IVBody.BodyFlags[/code]), or 0 if not applicable.
func get_body_flags() -> int:
	return 0


## Returns the [member name] of this interface's [PlayerInterface], or
## [code]&""[/code] if not applicable.
func get_player_name() -> StringName:
	return &""


## Returns the player class index for this interface's [PlayerInterface], or
## -1 if not applicable.
func get_player_class() -> int:
	return -1


## Returns the polity name for this interface, or [code]&""[/code] if not
## applicable.
func get_polity_name() -> StringName:
	return &""


## Returns this interface's facilities. AI thread only! Default empty.
func get_facilities() -> Array[Interface]:
	return []


# Components

## Returns the [OperationsNet] component, or null if this interface has none.
func get_operations() -> OperationsNet:
	return null


## Returns the [InventoryNet] component, or null if this interface has none.
func get_inventory() -> InventoryNet:
	return null


## Returns the [FinancialsNet] component, or null if this interface has none.
func get_financials() -> FinancialsNet:
	return null


## Returns the [PopulationNet] component, or null if this interface has none.
func get_population() -> PopulationNet:
	return null


## Returns the [BiomeNet] component, or null if this interface has none.
func get_biome() -> BiomeNet:
	return null


## Returns the [CyberspaceNet] component, or null if this interface has none.
func get_cyberspace() -> CyberspaceNet:
	return null


## Returns the [ExchangeInterface] this interface participates in, or null if
## not applicable.
func get_exchange() -> ExchangeInterface:
	return null



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

## Called every one to several frames during AI processing (unless excessive
## AI processing). You probably shouldn't override this; consider
## [method process_ai_interval] instead.
func process_ai(time: float) -> void:
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


## Called once before the first [method process_ai_interval]. Override to
## perform one-time AI setup.
func process_ai_init() -> void:
	pass


## Called once per [constant INTERVAL] during AI processing (unless excessive
## AI processing). Most component changes happen every [constant INTERVAL],
## so this is the recommended place for AI logic.
func process_ai_interval(_delta: float) -> void:
	pass


## Called after component histories have updated for the new quarter
## ([member run_qtr] advanced). Never called for a [BodyInterface] without a
## facility.
func process_ai_new_quarter() -> void:
	pass


# *****************************************************************************
# sync

## Initializes this interface from a server-supplied init payload. Subclasses
## override to unpack their fields.
func set_network_init(_data: Array) -> void:
	pass


## Applies a server-supplied dirty payload, updating fields whose
## [code]DIRTY_*[/code] flags are set. Subclasses override to unpack.
func sync_server_dirty(_data: Array) -> void:
	pass


func _sync_ai_changes() -> void:
	_dirty = 0


## Propagates a server-supplied delta payload (e.g. an aggregate change)
## down through this interface's components. Subclasses override as needed.
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
#	use_this_ai = _is_server_ai or (_is_local_player and (_is_local_use_ai or _ai_bus.is_autoplay))
