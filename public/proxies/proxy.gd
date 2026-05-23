# proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
@abstract
class_name Proxy
extends RefCounted

## Base class for entity proxies between AI/GUI clients and the game server.
##
## All GUI and in-game AI interaction with game internals goes through a
## [Proxy]. Subclasses include [FacilityProxy], [PlayerProxy],
## [BodyProxy], [JoinProxy], [TraderProxy], and
## [MarketProxy]. Each is paired with a server-side entity that pushes
## changes via sync methods. A few "player control" properties have reverse
## proxy -> server data flow.
##
## Components attached to a [Proxy] are net-sync objects: [OperationsNet],
## [InventoryNet], [FinancialsNet], [PopulationNet], [BiomeNet],
## [CyberspaceNet], and [StratumNet].
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## To modify AI, see comments in '_base_ai.gd' files.
##
## Warning! This object lives and dies on the proxy thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.
##
## TODO: @abstract methods.


## Emitted on the proxy thread when this proxy's mirrored state changes;
## payload is consumed by the sync layer on the receiver side. proxy thread only!
signal proxy_changed(entity_type: int, entity_id: int, data: Array)

## Emitted when persistent (saveable) data changes. Don't emit this directly;
## mark the relevant dirty flag and let the sync layer emit.
signal persist_data_changed(network_id: int, data: Array)


## Bit flags marking which parts of a [Proxy] (and its components) are
## dirty for sync.
enum DirtyFlags {
	DIRTY_QUARTER = 1,
	DIRTY_FACILITY = 1 << 1,
	DIRTY_PLAYER = 1 << 2,
	DIRTY_BODY = 1 << 3,
	DIRTY_JOIN = 1 << 4,
	DIRTY_MARKET = 1 << 5,
	DIRTY_TRADER = 1 << 6,
	DIRTY_OPERATIONS = 1 << 7,
	DIRTY_INVENTORY = 1 << 8,
	DIRTY_FINANCIALS = 1 << 9,
	DIRTY_POPULATION = 1 << 10,
	DIRTY_BIOME = 1 << 11,
	DIRTY_CYBERSPACE = 1 << 12,
	DIRTY_STRATA = 1 << 13,
	DIRTY_BROKER = 1 << 14,
}

## Identifies the kind of server entity a [Proxy] proxies.
## [code]N_ENTITY_TYPES[/code] is the count of real types;
## [code]ENTITY_SERVER[/code] and [code]ENTITY_PROXY[/code] are extra
## sync-routing markers.
enum EntityType {
	ENTITY_FACILITY,
	ENTITY_PLAYER,
	ENTITY_BODY,
	ENTITY_JOIN,
	ENTITY_MARKET,
	ENTITY_TRADER,
	ENTITY_BROKER,
	ENTITY_SERVER,
	ENTITY_PROXY,
	N_ENTITY_TYPES,
}

## Identifies which net-sync component on a [Proxy] a sync payload targets.
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

## Server methods that can originate from Proxy.
enum ProxyServerMethods {
	SPOT_ASK,
	SPOT_BID,
	CANCEL_SPOT_ASK,
	CANCEL_SPOT_BID,
	CANCEL_ALL_SPOT_ASKS,
	CANCEL_ALL_SPOT_BIDS,
	N_PROXY_SERVER_METHODS,
}


const INTERVAL := 7.0 * IVUnits.DAY ## Time between [method process_ai_interval] calls.


static var proxy_bus: ProxyBus ## Shared [ProxyBus] for proxy-thread signals and data.

@warning_ignore_start("unused_private_class_variable")
static var _times: Array = IVGlobal.times
static var _date: Array = IVGlobal.date
static var _clock: Array = IVGlobal.clock
static var _db_tables := IVTableData.db_tables
static var _table_n_rows: Dictionary = IVTableData.table_n_rows
@warning_ignore_restore("unused_private_class_variable")


var proxy_id := -1  ## Index into [member ProxyBus.proxies].
var entity_type := -1  ## See [enum EntityType]. Set by subclass [code]_init()[/code].
var name := &""  ## Unique, immutable identifier (e.g. [code]&"PLAYER_NASA"[/code]).
var gui_name := ""  ## Display name; mutable. Empty player gui_name hides from GUI.
## Quarterly clock as [code]year * 4 + (quarter - 1)[/code]. Never set for a
## [BodyProxy] without a facility.
var ordinal_qtr := -1
var last_interval := -INF  ## Time of last [method process_ai_interval] call.
var next_interval := -INF  ## Time of next [method process_ai_interval] call.

## Member names persisted by save/load. Append in subclass [code]_init()[/code].
## Nested containers are ok; NO OBJECTS!
var persist := [
	&"ordinal_qtr",
	&"last_interval",
	&"next_interval",
]

## True if this proxy should run AI logic this frame. Read-only; managed
## by the AI/server-control machinery.
var use_this_ai := false


var _dirty := 0
@warning_ignore("unused_private_class_variable") # read by ProxyServer.
var _refs_resolved := false
@warning_ignore_start("unused_private_class_variable")
var _is_local_player := false # gives GUI access
var _is_server_ai := false
var _is_local_use_ai := false # local player sets/unsets
@warning_ignore_restore("unused_private_class_variable")


# ***************************** CREATE & STATIC *******************************

## Returns a [Proxy] by [param proxy_name], or null if doesn't exist. Call on
## proxy thread only!
static func get_proxy_by_name(proxy_name: StringName) -> Proxy:
	return proxy_bus.proxies_by_name.get(proxy_name)



# ************************* VIRTUAL & IMPLEMENTATION **************************

func _init() -> void:
	IVStateManager.about_to_free_procedural_nodes.connect.call_deferred(_clear_for_destruction)


## Runtime mid-game removal entry point. Subclass overrides MUST chain to
## [code]super.remove()[/code] so cycles are broken outside of quit.
func remove() -> void:
	_clear_for_destruction()


## Override to null every outgoing Proxy/Resource ref. Both sides of a
## 2-cycle should clear — redundant on success, robust under refactoring.
func _clear_for_destruction() -> void:
	pass


## Initializes this proxy from a server-supplied init payload. Subclasses
## override to unpack their fields.
func set_network_init(_data: Array) -> void:
	pass


## Applies a server-supplied dirty payload, updating fields whose
## [code]DIRTY_*[/code] flags are set. Subclasses override to unpack.
func _sync_server_dirty(_data: Array) -> void:
	pass


func _sync_ai_changes() -> void:
	_dirty = 0


## Propagates a server-supplied delta payload (e.g. an aggregate change)
## down through this proxy's components. Subclasses override as needed.
func propagate_server_delta(_data: Array) -> void:
	pass


## Called every one to several frames during AI processing (unless excessive
## AI processing). You probably shouldn't override this; consider
## [method process_ai_interval] instead.
func process_ai(time: float) -> void:
	if time > next_interval:
		if next_interval == -INF: # init
			last_interval = time
			next_interval = time + randf_range(0.0, INTERVAL) # stagger AI processing
		else:
			var delta := time - last_interval
			last_interval = time
			while next_interval < time:
				next_interval += INTERVAL
			process_ai_interval(delta)
	if _dirty:
		_sync_ai_changes()


## Called once per process lifetime after this proxy is registered and after
## current-frame batched-init channels have drained. Override to resolve
## cross-proxy refs (via [member ProxyBus.proxies_by_name] or the typed
## arrays on [ProxyBus]) and to perform one-time AI setup. Runs again on the
## fresh post-load instance after a game load. Idempotent overrides required.
func process_ai_init() -> void:
	pass


## Called once per [constant INTERVAL] during AI processing (unless excessive
## AI processing). Most component changes happen every [constant INTERVAL],
## so this is the recommended place for AI logic.
func process_ai_interval(_delta: float) -> void:
	pass


## Called after component histories have updated for the new quarter
## ([member ordinal_qtr] advanced). Never called for a [BodyProxy] without a
## facility.
func process_ai_new_quarter() -> void:
	pass



# ***************************** THREAD-SAFE READ ******************************

## Returns true if this proxy contributes development statistics
## (population, economy, power, manufacturing, etc.). Default false.
func has_development() -> bool:
	return false


## Returns true if this proxy participates in markets. Default false.
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


## Returns the [member name] of this proxy's [BodyProxy], or
## [code]&""[/code] if not applicable.
func get_body_name() -> StringName:
	return &""


## Returns body flags for this proxy's [BodyProxy] (see ivoyager
## [code]IVBody.BodyFlags[/code]), or 0 if not applicable.
func get_body_flags() -> int:
	return 0


## Returns the [member name] of this proxy's [PlayerProxy], or
## [code]&""[/code] if not applicable.
func get_player_name() -> StringName:
	return &""


## Returns the player class index for this proxy's [PlayerProxy], or
## -1 if not applicable.
func get_player_class() -> int:
	return -1


## Returns the polity name for this proxy, or [code]&""[/code] if not
## applicable.
func get_polity_name() -> StringName:
	return &""


## Returns this proxy's facilities. proxy thread only! Default empty.
func get_facilities() -> Array[Proxy]:
	return []


# Components

## Returns the [OperationsNet] component, or null if this proxy has none.
func get_operations() -> OperationsNet:
	return null


## Returns the [InventoryNet] component, or null if this proxy has none.
func get_inventory() -> InventoryNet:
	return null


## Returns the [FinancialsNet] component, or null if this proxy has none.
func get_financials() -> FinancialsNet:
	return null


## Returns the [PopulationNet] component, or null if this proxy has none.
func get_population() -> PopulationNet:
	return null


## Returns the [BiomeNet] component, or null if this proxy has none.
func get_biome() -> BiomeNet:
	return null


## Returns the [CyberspaceNet] component, or null if this proxy has none.
func get_cyberspace() -> CyberspaceNet:
	return null


## Returns the spot [MarketProxy] for [param _player_id], or null if not
## applicable.
func get_market(_player_id: int) -> MarketProxy:
	return null


# TODO: Local player AI toggle (main thread).
#func player_use_ai(use_ai: bool) -> void:
#	if !_is_local_player:
#		return
#	_is_local_use_ai = use_ai
#	_reset_ai()
