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

## Entity types for sync routing or other purposes.
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
	ENTITY_FACILITY_PROXY,
	ENTITY_PLAYER_PROXY,
	ENTITY_BODY_PROXY,
	ENTITY_JOIN_PROXY,
	ENTITY_MARKET_PROXY,
	ENTITY_TRADER_PROXY,
	ENTITY_BROKER_PROXY,
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

## Server methods that can originate from [Proxy].
enum ProxyServerMethods {
	SPOT_ASK,
	SPOT_BID,
	CANCEL_SPOT_ASK,
	CANCEL_SPOT_BID,
	CANCEL_ALL_SPOT_ASKS,
	CANCEL_ALL_SPOT_BIDS,
	N_PROXY_SERVER_METHODS,
}

## Trade order status update from Market to [TraderProxy].
enum TradeOrderStatus {
	BOOKED,
	FILLED,
	PARTIALLY_FILLED,
	CANCELLED,
}

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
var entity_type := -1  ## See [enum EntityType]. Set by subclass [code]_init()[/code].
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


## Initializes this proxy from a server-supplied init payload.
@abstract func set_network_init(_data: Array) -> void


## Applies a server-supplied dirty payload, updating fields whose
## [code]DIRTY_*[/code] flags are set.
@abstract func _sync_server_dirty(_data: Array) -> void


## Flushes proxy-side dirty state back to the server. ProxyServer calls this
## per tick when [member _dirty] is non-zero.
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
