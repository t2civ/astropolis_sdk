# facility_base_ai.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name FacilityBaseAI
extends FacilityProxy

## Default AI for facilities the local player owns. Subclass to write custom
## facility AI; the base [FacilityProxy] is used for all non-owner peers.
##
## Strategies are declarative. Each [code]select_*_strategy()[/code] returns
## a [StringName] cached in a [code]current_*_strategy[/code] field; children
## read parent declarations during their own selection. Member data lives in
## the static registries as inner [Dictionary]s (empty for now); parameter
## knobs and an optional [code]"method"[/code] key for per-strategy logic
## overrides may grow into them. Execution (operation throttling, etc.) is
## centralized in [method process_ai_interval] — currently a placeholder
## pending base [FacilityProxy] facilities.
##
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [FacilityProxy]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [FacilityProxy]. See
## [PlayerCustomAI] for the extension template — the registry / select /
## refresh pattern is the same for all three [code]BaseAI[/code] classes.
##
## [b]Facility strategies[/b][br]
## • NEUTRAL - Starting / no-op stance; no special posture.[br]
## • GROWTH - Pursue expansion of capacity and footprint; accept thinner margins. Analog: scale-up startup, frontier development.[br]
## • PROFITABILITY - Optimize ROI on existing capacity; defer expansion. Analog: mature industrial site tuning throughput.[br]
## • DIVERSIFICATION - Spread operations across resources and process groups to reduce concentration risk. Analog: integrated conglomerate.[br]
## • SPECIALIZATION - Focus capacity on the most profitable or strategic operations; let others wither. Analog: hyper-focused supplier (e.g., a single-product foundry).[br]
## • STRATEGIC_OUTPOST - Maintain presence and capability regardless of economics. Analog: forward military base, polar research station.[br]
## • DEVELOPMENT - Early-stage facility; prioritize learning, training, and capability over current profit. Analog: pilot plant, new colony.[br]
## • STEADY_STATE - Mature operations; replace capacity as it depreciates; resist large swings. Analog: established refinery or mill.[br]
## • DECOMMISSIONING - Orderly wind-down of all operations; preserve safety; do not reinvest. Analog: planned plant closure.[br]
## • EMERGENCY - Crisis mode; activate all available capacity; suspend normal economic constraints. Analog: wartime production, disaster response.
##
## [b]Operation strategies[/b][br]
## • AUTO - Delegate to server-side automation hints ([code]OpFlags[/code]); minimal AI intervention.[br]
## • PROFIT_MAXIMIZE - Run when gross margin is positive; ramp up in favorable periods; idle when unprofitable. Analog: merchant power plant on the spot market.[br]
## • VOLUME_MAXIMIZE - Run at full capacity regardless of margin. Analog: wartime production quota, strategic stockpile build.[br]
## • BASELOAD - Run continuously at a steady rate; do not chase short-term price signals. Analog: nuclear plants, blast furnaces — expensive to cycle.[br]
## • PEAKER - Idle most of the time; activate only during price spikes or shortages. Analog: gas-peaking power plants.[br]
## • MOTHBALL - Idle but preserve restart capability without decommissioning. Analog: laid-up steel mills, cocooned aircraft.[br]
## • DECOMMISSION - Wind down toward permanent retirement; do not invest in maintenance. Analog: end-of-life mine, deprecated fab.[br]
## • DEMAND_FOLLOWING - Throttle to match observed local offtake. Analog: load-following power plant.[br]
## • SHORTAGE_RELIEF - Ramp up in response to local shortages even at margin loss. Analog: emergency-supply duty, public-utility obligation.[br]
## • LEARNING - Run regardless of margin to drive down unit costs and accumulate experience. Analog: early-stage industries (early solar, EVs) on the learning curve.[br]
## • HARVEST - Extract maximum output while resource quality is high; defer maintenance and reinvestment. Analog: late-stage mining, declining oilfield.[br]
## • STRATEGIC_HOLD - Maintain a minimum viable run rate for strategic reasons even at a loss. Analog: keeping a domestic semiconductor fab alive for national security.


# **************************** STRATEGY REGISTRIES ****************************

## Overall facility-posture strategies; key -> per-member data dict (empty
## placeholder for now; may grow parameter knobs or an optional
## [code]"method"[/code] key for per-strategy logic overrides). Extend via
## [method register_facility_strategy].
static var facility_strategies: Dictionary[StringName, Dictionary] = {
	&"NEUTRAL": {},
	&"GROWTH": {},
	&"PROFITABILITY": {},
	&"DIVERSIFICATION": {},
	&"SPECIALIZATION": {},
	&"STRATEGIC_OUTPOST": {},
	&"DEVELOPMENT": {},
	&"STEADY_STATE": {},
	&"DECOMMISSIONING": {},
	&"EMERGENCY": {},
}

## Per-operation strategies; key -> per-member data dict. Extend via
## [method register_operation_strategy].
static var operation_strategies: Dictionary[StringName, Dictionary] = {
	&"AUTO": {},
	&"PROFIT_MAXIMIZE": {},
	&"VOLUME_MAXIMIZE": {},
	&"BASELOAD": {},
	&"PEAKER": {},
	&"MOTHBALL": {},
	&"DECOMMISSION": {},
	&"DEMAND_FOLLOWING": {},
	&"SHORTAGE_RELIEF": {},
	&"LEARNING": {},
	&"HARVEST": {},
	&"STRATEGIC_HOLD": {},
}


## Registers [param strategy] in [member facility_strategies]. Asserts on
## duplicate to surface accidental collisions between mod registrations.
static func register_facility_strategy(strategy: StringName, data: Dictionary) -> void:
	assert(!facility_strategies.has(strategy), "Facility strategy already registered: %s" % strategy)
	facility_strategies[strategy] = data


## Registers [param strategy] in [member operation_strategies]. Asserts on
## duplicate.
static func register_operation_strategy(strategy: StringName, data: Dictionary) -> void:
	assert(!operation_strategies.has(strategy), "Operation strategy already registered: %s" % strategy)
	operation_strategies[strategy] = data


# ********************************** AI API ***********************************

## Currently selected facility-posture strategy. Updated by
## [method _refresh_selections] on each quarter tick. Not persisted across
## save/load; re-derived on next quarter tick.
## (If GUI/server ever needs to mirror this, use [code]Proxy.DirtyFlags[/code]
## per the established pattern.)
var current_facility_strategy: StringName = &"NEUTRAL"

## Currently selected per-operation strategies, keyed by operation_type (int).
## Lazy-populated. Not persisted.
var current_operation_strategies: Dictionary = {}


## Selects this facility's overall posture strategy. May later consult
## [code]player.current_facility_strategies[my_facility_class][/code] once
## facility-type keying lands (see PlayerBaseAI TODO).
func select_facility_strategy() -> StringName:
	return &"NEUTRAL"


## Selects the operation strategy for [param operation_type].
func select_operation_strategy(_operation_type: int) -> StringName:
	return &"AUTO"


## Updates [member current_facility_strategy] from [method select_facility_strategy].
## Per-operation refresh is a TODO pending an operation-list enumeration
## source on [FacilityProxy].
func _refresh_selections() -> void:
	current_facility_strategy = select_facility_strategy()
	assert(facility_strategies.has(current_facility_strategy),
			"select_facility_strategy returned unregistered key: %s" % current_facility_strategy)
	# TODO: iterate operations and refresh current_operation_strategies
	# once FacilityProxy exposes its operation list.


## Placeholder. Future executor will read [member current_facility_strategy]
## and [member current_operation_strategies] and throttle individual operations
## through base [FacilityProxy] facilities (not yet exposed).
func process_ai_interval(_delta: float) -> void:
	pass


func process_ai_new_quarter() -> void:
	_refresh_selections()
