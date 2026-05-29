# facility_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
@abstract
class_name FacilityProxy
extends Proxy

## [FacilityProxy] represents a [PlayerProxy]'s development at a [BodyProxy].
##
## A facility runs operations enabled by modules (see corresponding data
## tables). Server-side automations translate AI intent set here into per-tick
## operation behavior. AI writes FROM_PROXY_MASK flag bits on [member flags],
## on per-op operations flags, and on per-resource inventory flags; the server
## publishes FROM_SERVER_MASK runtime signals (margin, shortage, surplus) back
## for AI to read.
##
## To modify AI, see [BaseAI] and the [code]*_base_ai.gd[/code] files.
##
## WARNING: Lives on the proxy thread. Containers and many methods are not
## threadsafe; accessing non-container properties is safe.


## Facility-level bit flags. FROM_SERVER bits (0 - 31) are signals from the
## server; FROM_PROXY bits (32 - 63) are AI commands to the server.
enum FacilityFlags {
	## Many resources at this facility have no established market price, so
	## runtime margin estimates here are unreliable.
	PRICE_UNRELIABLE = 1 << 1,
	## Multiple critical inputs are simultaneously running below their
	## operational reserve targets.
	INPUT_CRISIS = 1 << 2,
	## Mask of all server-published signal bits.
	FROM_SERVER_MASK = (1 << 32) - 1,

	## Crisis posture: operations continue regardless of profitability and
	## storage constraints are relaxed.
	MODE_EMERGENCY = 1 << 32,
	## Laid-up state: no operations run; capacity is preserved for later restart.
	MODE_MOTHBALL = 1 << 33,
	## Winding down: only operations that net-consume inventory continue.
	MODE_DECOMMISSIONING = 1 << 34,
	## Mask of all AI-command bits.
	FROM_PROXY_MASK = ~((1 << 32) - 1),
}


## Per-resource inventory bit flags. FROM_SERVER bits (0 - 31) are signals from
## the server; FROM_PROXY bits (32 - 63) are AI commands to the server.
enum InventoryFlags {
	## Stock of this resource is below its operational reserve target.
	OPS_RESERVE_BREACHED = 1 << 1,
	## Stock of this resource is below its AI-set strategic reserve target.
	STRATEGIC_RESERVE_BREACHED = 1 << 2,
	## The storage class holding this resource is at or above the first
	## throttling threshold.
	STORAGE_SURPLUS = 1 << 3,
	## No market spot price is established for this resource at this location.
	PRICE_UNKNOWN = 1 << 4,
	## Mask of all server-published signal bits.
	FROM_SERVER_MASK = (1 << 32) - 1,

	## Operations must not draw this resource below its strategic reserve.
	PROTECT_STRATEGIC_RESERVE = 1 << 32,
	## No operation may consume this resource (e.g., embargo, phase-out).
	PROHIBIT_CONSUMPTION = 1 << 33,
	## No operation may produce this resource (e.g., divestment, phase-out).
	PROHIBIT_PRODUCTION = 1 << 34,
	## Mask of all AI-command bits.
	FROM_PROXY_MASK = ~((1 << 32) - 1),
}


## Per-operation bit flags. FROM_SERVER bits (0 - 31) are signals from the
## server; FROM_PROXY bits (32 - 63) are AI commands to the server.
enum OperationsFlags {
	## This facility is equipped to run this operation.
	CAN_HAVE = 1,
	## The operation ran at a loss over the last interval at known prices.
	MARGIN_NEGATIVE = 1 << 1,
	## The operation was throttled below its intended rate last interval
	## because an input was in short supply.
	WAS_INPUT_LIMITED = 1 << 2,
	## The operation was throttled below its intended rate last interval
	## because an output's storage was nearly full.
	WAS_STORAGE_LIMITED = 1 << 3,
	## Mask of all server-published signal bits.
	FROM_SERVER_MASK = (1 << 32) - 1,

	## Idle the operation whenever its margin is non-positive and prices are
	## reliable.
	MARGIN_GATED = 1 << 32,
	## When any of the op's outputs is below operational reserve, suspend
	## profit-gating and ease storage throttling so the op can ramp up.
	SHORTAGE_PRIORITY = 1 << 33,
	## Hold the operation at a minimum baseline rate even when other
	## automations would idle it.
	STRATEGIC_FLOOR = 1 << 34,
	## Hard-stop the operation when any of its outputs has insufficient
	## storage headroom (no soft trickle).
	CLEARANCE_LIMITED = 1 << 35,
	## Mask of all AI-command bits.
	FROM_PROXY_MASK = ~((1 << 32) - 1),
}


var facility_id := -1  ## Index into [member ProxyBus.facility_proxies].
var facility_class := -1  ## Facility class index. Not implemented yet.
var trader_id := -1  ## [member TraderProxy.trader_id] of this facility's paired trader.
## Public-sector share of this facility, often 0.0 or 1.0, sometimes mixed.
var public_sector: float
## True if this is a small focused activity (affects stats and tax treatment).
var is_unitary: bool
## True if all resource streams flow from/to inventory (no atmosphere/surface
## market).
var closed_cycle_ops: bool
## Fraction of solar irradiance occluded at this site (0.0–1.0).
var solar_occlusion: float
## Time horizon used by AI and automations (inventory reserves, resupply, etc.).
var time_horizon: float
## Bidirectional bit flags (see [enum FacilityFlags]). FROM_SERVER bits are
## server-authoritative; FROM_PROXY bits are proxy-authoritative. Use
## [method set_flags] to modify the proxy half.
var flags := 0

var player: PlayerProxy  ## Owning [PlayerProxy].
var polity: PlayerProxy  ## The polity of [member player].
var body: BodyProxy  ## Hosting [BodyProxy].
var trader: TraderProxy  ## Paired [TraderProxy]; set when TraderProxy registers.
var joins: Array[JoinProxy] = []  ## [JoinProxy] aggregates this facility belongs to.
var market: MarketProxy  ## Set after init. Lives on markets thread!

## Body texture cached for [code]IVSelectionManager[/code] (currently the
## hosting body's [code]IVBody.texture_2d[/code]).
var texture_2d: Texture2D


# ************************* VIRTUAL & IMPLEMENTATION **************************

func _clear_for_destruction() -> void:
	body = null
	player = null
	polity = null
	trader = null
	joins.clear()
	market = null
	texture_2d = null
	ai = null


# ********************************* PROXY API *********************************

## Detaches this facility from its body and player, then breaks its outgoing
## refs via [method super.remove]. Called by the server side at runtime when a
## facility is removed mid-game.
func remove() -> void:
	body.remove_facility(self)
	player.remove_facility(self)
	super.remove()


## Sets [member gui_name] and marks the proxy dirty. Reverse-flow:
## proxy -> server.
@abstract func set_gui_name(new_gui_name: String) -> void


func has_development() -> bool:
	return true


func has_markets() -> bool:
	return true


func has_inventory() -> bool:
	return true


func get_body_name() -> StringName:
	return body.name


func get_body_flags() -> int:
	return body.body_flags


func get_player_name() -> StringName:
	return player.name


func get_player_class() -> int:
	return player.player_class


func get_polity_name() -> StringName:
	return polity.name


# Facility flags

## Returns the full bidirectional flag value (see [enum FacilityFlags]).
func get_flags() -> int:
	return flags


## Sets the [code]FROM_PROXY_MASK[/code] bits of [member flags] to
## [param value], preserving the server-authoritative
## [code]FROM_SERVER_MASK[/code] bits. Proxy-authoritative: this change
## flows proxy -> server.
@abstract func set_flags(value: int) -> void


# Operations (proxy-authoritative; reverse data flow proxy -> server).
# Implemented on the server-side facility proxy against its operations component.

## Returns the full bidirectional flag value for operation [param operation_type].
@abstract func get_operations_flags(operation_type: int) -> int


## Sets the [code]FROM_PROXY_MASK[/code] bits of operations flags for
## [param operation_type] to [param value]. Proxy-authoritative: this
## change flows proxy -> server.
@abstract func set_operations_flags(operation_type: int, value: int) -> void


## Sets the target utilization for [param type]. Proxy-authoritative:
## this change flows proxy -> server.
@abstract func set_operations_target_utilization(type: int, value: float) -> void


# Inventory (proxy-authoritative; reverse data flow proxy -> server).
# Implemented on the server-side facility proxy against its inventory component.

## Returns the full bidirectional flag value for resource [param resource_type].
@abstract func get_inventory_flags(resource_type: int) -> int


## Sets the [code]FROM_PROXY_MASK[/code] bits of inventory flags for
## [param resource_type] to [param value]. Proxy-authoritative: this
## change flows proxy -> server.
@abstract func set_inventory_flags(resource_type: int, value: int) -> void


## Sets the strategic reserve for [param type]. Proxy-authoritative:
## this change flows proxy -> server.
@abstract func set_inventory_strategic_reserve(type: int, value: float) -> void


## Returns this facility's spot [MarketProxy], or null if not yet set.
## [param _player_id] is unused for direct-routed facilities; the per-player
## sanctions routing happens at the Broker layer.
func get_market(_player_id: int) -> MarketProxy:
	return market
