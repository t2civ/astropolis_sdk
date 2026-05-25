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
## an [int] enum id (see [enum FacilityStrategies],
## [enum FacilityResourceStrategies], [enum OperationStrategies]) cached in a
## [code]<name>_strategy[/code] field; children read parent declarations
## during their own selection. Per-strategy data lives in the
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


## Emitted when [member facility_strategy] changes.
signal facility_strategy_changed(strategy_id: int)
## Emitted when an entry in [member facility_resource_strategies] changes.
signal facility_resource_strategy_changed(resource_type: int, strategy_id: int)
## Emitted when an entry in [member operation_strategies] changes.
signal operation_strategy_changed(operation_type: int, strategy_id: int)


## Facility-posture strategies.
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

## Per-resource facility strategies — how this facility views a particular
## resource given its own operations, inventory state, and player strategies.
enum FacilityResourceStrategies {
	## No special facility-level stance; trader applies its own per-resource
	## strategy independently.
	NEUTRAL,
	## Primary saleable output the facility exists to produce; the operations
	## that produce it carry the facility's revenue thesis. Analog: a copper
	## smelter's cathode copper.
	PRIMARY_PRODUCT,
	## Additional saleable output run only when margins justify; capacity is
	## discretionary. Analog: a refinery's specialty chemicals or asphalt.
	SECONDARY_PRODUCT,
	## Output produced in fixed ratio with another (usually primary) output;
	## cannot be throttled independently — must be sold, stored, or its
	## producing op must idle. Analog: a refinery's LPG alongside gasoline,
	## sulfur from sour-crude refining.
	COPRODUCT,
	## Low-value output of a producing operation; not a profit center, but
	## must move off-site to keep the line running. Analog: scrap metal,
	## slag, spent caustic.
	BYPRODUCT,
	## Non-commodity output that must be disposed of (vented, dumped, stored
	## as overburden); operations are constrained by available disposal
	## capacity. Analog: flare gas, mine tailings, CO2 emissions.
	WASTE,
	## Input without which primary operations halt; supply continuity matters
	## more than per-unit price. Analog: a fab's ultra-pure water and
	## photoresist; a smelter's contracted electricity.
	CRITICAL_INPUT,
	## Operating input with adequate market liquidity and substitutability;
	## buy lean at prevailing prices. Analog: a factory's commodity natural
	## gas or merchant-grade steel.
	ROUTINE_INPUT,
	## Small-quantity consumables, reagents, MRO supplies; cost of doing
	## business with no strategic weight. Analog: lubricants, catalyst
	## makeup, filter media.
	CONSUMABLE,
	## Produced and consumed within the facility's own process loop; external
	## trade is unwanted or impractical. Analog: a chemical complex's hydrogen
	## produced and consumed inside the integrated fenceline; reflux streams.
	CLOSED_LOOP_INTERMEDIATE,
	## Accumulate inventory well beyond operating need; pull supply from the
	## market or run producing ops at strategic-hold rates. Analog: a mill
	## stockpiling a sanction-vulnerable ore.
	STRATEGIC_RESERVE,
	## Inventory is being held or worked as a directional trading position
	## rather than for operational continuity. Analog: a refiner taking a
	## crude position outside normal hedging.
	SPECULATIVE_POSITION,
	## The facility is exiting this resource long-term; wind down ops that
	## produce or consume it and run inventory down. Analog: a multi-product
	## plant exiting a product line; a utility's coal phase-down.
	PHASE_OUT,
	N_BASE_FACILITY_RESOURCE_STRATEGIES,
}

## Per-operation strategies.
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
	## Throttle run rate to match downstream clearance — disposal capacity
	## for waste, storage or offtake for byproducts and coproducts, atmospheric
	## or surface caps. The op is constrained by the slowest output we can
	## move, not by input availability or output margin. Analog: a refinery
	## limited by sulfur-handling capacity; a mine limited by tailings-pond
	## headroom.
	CLEARANCE_LIMITED,
	N_BASE_OPERATION_STRATEGIES,
}


## Facility-posture strategy definitions; index = [enum FacilityStrategies]
## value.
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

## Per-resource facility-level strategy definitions; index =
## [enum FacilityResourceStrategies] value.
static var facility_resource_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # PRIMARY_PRODUCT
	{}, # SECONDARY_PRODUCT
	{}, # COPRODUCT
	{}, # BYPRODUCT
	{}, # WASTE
	{}, # CRITICAL_INPUT
	{}, # ROUTINE_INPUT
	{}, # CONSUMABLE
	{}, # CLOSED_LOOP_INTERMEDIATE
	{}, # STRATEGIC_RESERVE
	{}, # SPECULATIVE_POSITION
	{}, # PHASE_OUT
]

## Per-operation strategy definitions; index = [enum OperationStrategies]
## value.
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
	{}, # CLEARANCE_LIMITED
]


## Facility-posture strategy. See [enum FacilityStrategies].
var facility_strategy := 0
## Per-resource facility-level strategies. See [enum FacilityResourceStrategies].
var facility_resource_strategies: PackedInt32Array
## Per-operation strategies. See [enum OperationStrategies].
var operation_strategies: PackedInt32Array



# ************************* VIRTUAL & IMPLEMENTATION **************************


func _init() -> void:
	super()
	persist.append(&"facility_strategy")
	persist.append(&"facility_resource_strategies")
	persist.append(&"operation_strategies")
	var n_resources: int = _table_n_rows[&"resources"]
	facility_resource_strategies.resize(n_resources)
	var n_operations: int = _table_n_rows[&"operations"]
	operation_strategies.resize(n_operations)


func process_ai_init() -> void:
	super()
	var player_ai := player as PlayerBaseAI
	assert(player_ai, "FacilityBaseAI expects player to be PlayerBaseAI")
	player_ai.global_strategy_changed.connect(_on_player_global_strategy_changed)
	player_ai.player_resource_strategy_changed.connect(_on_player_resource_strategy_changed)
	player_ai.player_facility_strategy_changed.connect(_on_player_facility_strategy_changed)
	player_ai.body_strategy_changed.connect(_on_player_body_strategy_changed)


func process_ai_interval(_delta: float) -> void:
	pass


# **************************** STRATEGY LISTENERS *****************************

func _on_player_global_strategy_changed(_strategy_id: int) -> void:
	pass


func _on_player_resource_strategy_changed(_resource_type: int, _strategy_id: int) -> void:
	pass


func _on_player_facility_strategy_changed(_facility_id: int, _strategy_id: int) -> void:
	pass


func _on_player_body_strategy_changed(_target_body_id: int, _strategy_id: int) -> void:
	pass
