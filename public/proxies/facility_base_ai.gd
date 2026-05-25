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
## an [int] enum id (see [enum FacilityStrategies], [enum OperationStrategies])
## cached in a [code]<name>_strategy[/code] field; children read parent
## declarations during their own selection. Per-strategy data lives in the
## static [code]*_strategy_defs[/code] arrays as inner [Dictionary]s (empty
## for now); parameter knobs and an optional [code]"method"[/code] key for
## per-strategy logic overrides may grow into them. Cached selections are
## persisted via [member Proxy.persist] so player intent survives save/load,
## and are re-derived on each quarter tick on top of the loaded value.
## Execution (operation throttling, etc.) is centralized in
## [method process_ai_interval] — currently a placeholder pending base
## [FacilityProxy] facilities.
##
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [FacilityProxy]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [FacilityProxy]. See
## [PlayerCustomAI] for the extension template — the registry / select /
## refresh pattern is the same for all three [code]BaseAI[/code] classes.


## Facility-posture strategies. By convention id 0 is the no-op default
## (NEUTRAL, AUTO, or similar) used as the starting state. Add-on strategies
## begin at [code]N_BASE_FACILITY_STRATEGIES[/code].
enum FacilityStrategies {
	## Starting / no-op stance; no special posture.
	NEUTRAL,
	## Pursue expansion of capacity and footprint; accept thinner margins.
	## Analog: scale-up startup, frontier development.
	GROWTH,
	## Optimize ROI on existing capacity; defer expansion. Analog: mature
	## industrial site tuning throughput.
	PROFITABILITY,
	## Spread operations across resources and process groups to reduce
	## concentration risk. Analog: integrated conglomerate.
	DIVERSIFICATION,
	## Focus capacity on the most profitable or strategic operations; let
	## others wither. Analog: hyper-focused supplier (e.g., a single-product
	## foundry).
	SPECIALIZATION,
	## Maintain presence and capability regardless of economics. Analog:
	## forward military base, polar research station.
	STRATEGIC_OUTPOST,
	## Early-stage facility; prioritize learning, training, and capability
	## over current profit. Analog: pilot plant, new colony.
	DEVELOPMENT,
	## Mature operations; replace capacity as it depreciates; resist large
	## swings. Analog: established refinery or mill.
	STEADY_STATE,
	## Orderly wind-down of all operations; preserve safety; do not reinvest.
	## Analog: planned plant closure.
	DECOMMISSIONING,
	## Crisis mode; activate all available capacity; suspend normal economic
	## constraints. Analog: wartime production, disaster response.
	EMERGENCY,
	N_BASE_FACILITY_STRATEGIES,
}

## Per-operation strategies. By convention id 0 is the no-op default (here
## AUTO — delegate to server-side automation hints). Add-on strategies begin
## at [code]N_BASE_OPERATION_STRATEGIES[/code].
enum OperationStrategies {
	## Delegate to server-side automation hints ([code]OpFlags[/code]); minimal
	## AI intervention.
	AUTO,
	## Run when gross margin is positive; ramp up in favorable periods; idle
	## when unprofitable. Analog: merchant power plant on the spot market.
	PROFIT_MAXIMIZE,
	## Run at full capacity regardless of margin. Analog: wartime production
	## quota, strategic stockpile build.
	VOLUME_MAXIMIZE,
	## Run continuously at a steady rate; do not chase short-term price
	## signals. Analog: nuclear plants, blast furnaces — expensive to cycle.
	BASELOAD,
	## Idle most of the time; activate only during price spikes or shortages.
	## Analog: gas-peaking power plants.
	PEAKER,
	## Idle but preserve restart capability without decommissioning. Analog:
	## laid-up steel mills, cocooned aircraft.
	MOTHBALL,
	## Wind down toward permanent retirement; do not invest in maintenance.
	## Analog: end-of-life mine, deprecated fab.
	DECOMMISSION,
	## Throttle to match observed local offtake. Analog: load-following power
	## plant.
	DEMAND_FOLLOWING,
	## Ramp up in response to local shortages even at margin loss. Analog:
	## emergency-supply duty, public-utility obligation.
	SHORTAGE_RELIEF,
	## Run regardless of margin to drive down unit costs and accumulate
	## experience. Analog: early-stage industries (early solar, EVs) on the
	## learning curve.
	LEARNING,
	## Extract maximum output while resource quality is high; defer maintenance
	## and reinvestment. Analog: late-stage mining, declining oilfield.
	HARVEST,
	## Maintain a minimum viable run rate for strategic reasons even at a loss.
	## Analog: keeping a domestic semiconductor fab alive for national
	## security.
	STRATEGIC_HOLD,
	N_BASE_OPERATION_STRATEGIES,
}


# **************************** STRATEGY REGISTRIES ****************************

## Facility-posture strategy definitions; index = [enum FacilityStrategies]
## value. Each inner [Dictionary] is per-strategy data (empty placeholder for
## now; may grow parameter knobs and an optional [code]"method"[/code] key
## for per-strategy logic overrides). Add-on strategies append via
## [method register_facility_strategy].
static var facility_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # GROWTH
	{}, # PROFITABILITY
	{}, # DIVERSIFICATION
	{}, # SPECIALIZATION
	{}, # STRATEGIC_OUTPOST
	{}, # DEVELOPMENT
	{}, # STEADY_STATE
	{}, # DECOMMISSIONING
	{}, # EMERGENCY
]

## Per-operation strategy definitions; index = [enum OperationStrategies]
## value. Add-on strategies append via [method register_operation_strategy].
static var operation_strategy_defs: Array[Dictionary] = [
	{}, # AUTO
	{}, # PROFIT_MAXIMIZE
	{}, # VOLUME_MAXIMIZE
	{}, # BASELOAD
	{}, # PEAKER
	{}, # MOTHBALL
	{}, # DECOMMISSION
	{}, # DEMAND_FOLLOWING
	{}, # SHORTAGE_RELIEF
	{}, # LEARNING
	{}, # HARVEST
	{}, # STRATEGIC_HOLD
]


## Appends [param data] for [param strategy_id] in
## [member facility_strategy_defs]. [param strategy_id] must equal the current
## array size (contiguous append) — surfaces colliding mod registrations as
## a debug assert rather than silent last-write-wins.
static func register_facility_strategy(strategy_id: int, data: Dictionary) -> void:
	assert(strategy_id == facility_strategy_defs.size(),
			"Non-contiguous facility strategy id %d; expected %d"
			% [strategy_id, facility_strategy_defs.size()])
	facility_strategy_defs.append(data)


## Appends [param data] for [param strategy_id] in
## [member operation_strategy_defs]. See [method register_facility_strategy]
## for the contiguous-append contract.
static func register_operation_strategy(strategy_id: int, data: Dictionary) -> void:
	assert(strategy_id == operation_strategy_defs.size(),
			"Non-contiguous operation strategy id %d; expected %d"
			% [strategy_id, operation_strategy_defs.size()])
	operation_strategy_defs.append(data)


# ********************************** AI API ***********************************

## Currently selected facility-posture strategy id; see
## [enum FacilityStrategies]. By convention 0 is the NEUTRAL (no-op default)
## value. Persisted via [member Proxy.persist] so player intent survives
## save/load; updated each quarter by [method _refresh_selections].
var facility_strategy := 0

## Currently selected per-operation strategy ids, indexed by
## [code]operation_type[/code] (operations-table row). Sized in [method _init]
## to the operations-table row count; entries default to 0 (AUTO). Persisted
## via [member Proxy.persist].
var operation_strategies: PackedInt32Array


func _init() -> void:
	super()
	persist.append(&"facility_strategy")
	persist.append(&"operation_strategies")
	var n_operations: int = _table_n_rows[&"operations"]
	operation_strategies.resize(n_operations)


## Selects this facility's overall posture strategy. May later consult
## [code]player.facility_strategies[my_facility_class][/code] once
## facility-type keying lands (see PlayerBaseAI TODO).
func select_facility_strategy() -> int:
	return 0 # NEUTRAL


## Selects the operation strategy for [param operation_type].
func select_operation_strategy(_operation_type: int) -> int:
	return 0 # AUTO


## Updates [member facility_strategy] from [method select_facility_strategy].
## Per-operation refresh is a TODO pending an operation-list enumeration
## source on [FacilityProxy].
func _refresh_selections() -> void:
	facility_strategy = select_facility_strategy()
	assert(facility_strategy >= 0 and facility_strategy < facility_strategy_defs.size(),
			"select_facility_strategy returned invalid id: %d" % facility_strategy)
	# TODO: iterate operations and refresh operation_strategies
	# once FacilityProxy exposes its operation list.


## Placeholder. Future executor will read [member facility_strategy] and
## [member operation_strategies] and throttle individual operations through
## base [FacilityProxy] facilities (not yet exposed).
func process_ai_interval(_delta: float) -> void:
	pass


func process_ai_new_quarter() -> void:
	_refresh_selections()
