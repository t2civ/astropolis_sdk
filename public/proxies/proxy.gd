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
## [Proxy]. Subclasses ([FacilityProxy], [PlayerProxy], [BodyProxy],
## [JoinProxy], [TraderProxy], [MarketProxy], [BrokerProxy]) declare the
## API. Sync plumbing and concrete instantiation live on the corresponding
## server-side [code]*SvrProxy[/code] classes (nonpublic).
##
## To modify AI, see [BaseAI] and the [code]*_base_ai.gd[/code] files.
##
## WARNING: Lives on the proxy thread. Containers and many methods are not
## threadsafe; accessing non-container properties is safe.


## Indices into the [PackedFloat64Array] rows returned by
## [method get_module_data] and [method get_operation_data]. Rate fields may
## be NAN where not applicable (e.g. fuel rate for a non-generator).
enum OperationDataIndex {
	UTILIZATION,
	ELECTRICITY,
	REVENUE,
	GROSS_MARGIN,
	FUEL_RATE,
	EXTRACTION_RATE,
	MASS_CONVERSION_RATE,
	COMPUTATION,
	N_OPERATION_DATA,
}


const INTERVAL := 7.0 * IVUnits.DAY ## AI tick interval. See [constant BaseAI.INTERVAL].


static var proxy_bus: ProxyBus ## Shared [ProxyBus] for proxy-thread signals and data.

@warning_ignore_start("unused_private_class_variable")
static var _times: Array = IVGlobal.times
static var _date: Array = IVGlobal.date
static var _clock: Array = IVGlobal.clock
static var _db_tables := IVTableData.db_tables
static var _table_n_rows: Dictionary = IVTableData.table_n_rows
@warning_ignore_restore("unused_private_class_variable")


var proxy_id := -1  ## Index into [member ProxyBus.proxies].
var entity_type := -1  ## Entity type tag; set by the server-side proxy.
var name := &""  ## Unique, immutable identifier (e.g. [code]&"PLAYER_NASA"[/code]).
var gui_name := ""  ## Display name; mutable. Empty player gui_name hides from GUI.
## Quarterly clock as [code]year * 4 + (quarter - 1)[/code]. Never set for a
## [BodyProxy] without a facility.
var ordinal_qtr := -1

## AI paired with this proxy, or null on peers that don't run AI for this
## entity. Read-only; managed by [code]ProxyServer[/code].
var ai: BaseAI

## Member names persisted by save/load. Append in subclass [code]_init()[/code].
## Nested containers are ok; NO OBJECTS!
var persist: Array[StringName] = []


@warning_ignore_start("unused_private_class_variable") # used by subclasses
var _dirty := 0
var _refs_resolved := false
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


## Initializes this proxy from a server-supplied init payload. Modders: Don't touch this!
@abstract func set_network_init(data: Array) -> void


## Applies a server-supplied dirty payload. Modders: Don't touch this!
@abstract func _sync_server_dirty(data: Array) -> void


## Flushes proxy-side dirty state back to the server. Modders: Don't touch this!
@abstract func _sync_ai_changes() -> void



# ***************************** THREAD-SAFE READ ******************************

## Returns true if this proxy contributes development statistics
## (population, economy, power, manufacturing, etc.). Default false.
func has_development() -> bool:
	return false


## Returns true if this proxy participates in markets. Default false.
func has_markets() -> bool:
	return false


## Returns true if this proxy carries inventory state (resource stocks,
## contracts). Default false.
func has_inventory() -> bool:
	return false


# Development totals. Default 0.0; the developed proxies (Facility, Player,
# Body, Join) override with values combined from their components.

## Returns the development "population" total, optionally filtered to a
## specific [param population_type] (-1 for total).
func get_development_population(_population_type := -1) -> float:
	return 0.0


## Returns the development "economy" total (gross output).
func get_development_economy() -> float:
	return 0.0


## Returns the development "power" total (electrical generation).
func get_development_power() -> float:
	return 0.0


## Returns the development "manufacturing" total.
func get_development_manufacturing() -> float:
	return 0.0


## Returns the development "constructions" total (mass constructed).
func get_development_constructions() -> float:
	return 0.0


## Returns the development "computation" total.
func get_development_computation() -> float:
	return 0.0


## Returns the development "information" total.
func get_development_information() -> float:
	return 0.0


## Returns the development "bioproductivity" total.
func get_development_bioproductivity() -> float:
	return 0.0


## Returns the development "biomass" total.
func get_development_biomass() -> float:
	return 0.0


## Returns the development "biodiversity" metric (0.0–1.0).
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


## Returns the spot [MarketProxy] for [param _player_id], or null if not
## applicable.
func get_market(_player_id: int) -> MarketProxy:
	return null


# Operations data (read-only). Default empty/false; the developed proxies
# override. [method get_module_data] and [method get_operation_data] return a
# row indexed by [enum OperationDataIndex].

## True if this proxy reports per-operation financial metrics (revenue, margin).
func has_financials() -> bool:
	return false


## True if [param module_type] (and any of its operations) has nonzero
## capacity or interest at this proxy.
func is_of_interest_module(_module_type: int) -> bool:
	return false


## Returns a display row for [param module_type] indexed by
## [enum OperationDataIndex], or an empty array if this proxy has no operations.
func get_module_data(_module_type: int) -> PackedFloat64Array:
	return PackedFloat64Array()


## Returns a display row for operation [param operation_type] indexed by
## [enum OperationDataIndex], or an empty array if this proxy has no operations.
func get_operation_data(_operation_type: int) -> PackedFloat64Array:
	return PackedFloat64Array()


# Inventory data (read-only). Default 0.0; FacilityProxy overrides.

func get_resource_stock(_resource_type: int) -> float:
	return 0.0


func get_resource_contracted(_resource_type: int) -> float:
	return 0.0
