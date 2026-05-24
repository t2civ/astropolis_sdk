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
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [FacilityProxy]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [FacilityProxy]. See
## [PlayerCustomAI] for the extension template — the registry / select /
## implement pattern is the same for all three [code]BaseAI[/code] classes.


# **************************** STRATEGY REGISTRIES ****************************

## Overall facility-posture strategies; key -> stub-method name on this class.
## Extend via [method register_facility_strategy].
static var facility_strategies: Dictionary[StringName, StringName] = {
	&"GROWTH": &"_facility_growth",
	&"PROFITABILITY": &"_facility_profitability",
	&"DIVERSIFICATION": &"_facility_diversification",
	&"SPECIALIZATION": &"_facility_specialization",
	&"STRATEGIC_OUTPOST": &"_facility_strategic_outpost",
	&"DEVELOPMENT": &"_facility_development",
	&"STEADY_STATE": &"_facility_steady_state",
	&"DECOMMISSIONING": &"_facility_decommissioning",
	&"EMERGENCY": &"_facility_emergency",
}

## Per-operation strategies; key -> stub-method name on this class. Extend
## via [method register_operation_strategy].
static var operation_strategies: Dictionary[StringName, StringName] = {
	&"AUTO": &"_operation_auto",
	&"PROFIT_MAXIMIZE": &"_operation_profit_maximize",
	&"VOLUME_MAXIMIZE": &"_operation_volume_maximize",
	&"BASELOAD": &"_operation_baseload",
	&"PEAKER": &"_operation_peaker",
	&"MOTHBALL": &"_operation_mothball",
	&"DECOMMISSION": &"_operation_decommission",
	&"DEMAND_FOLLOWING": &"_operation_demand_following",
	&"SHORTAGE_RELIEF": &"_operation_shortage_relief",
	&"LEARNING": &"_operation_learning",
	&"HARVEST": &"_operation_harvest",
	&"STRATEGIC_HOLD": &"_operation_strategic_hold",
}


## Adds or rewires [param strategy] in [member facility_strategies].
## Idempotent.
static func register_facility_strategy(strategy: StringName, method_name: StringName) -> void:
	facility_strategies[strategy] = method_name


## Adds or rewires [param strategy] in [member operation_strategies].
## Idempotent.
static func register_operation_strategy(strategy: StringName, method_name: StringName) -> void:
	operation_strategies[strategy] = method_name


# ********************************** AI API ***********************************

## Selects this facility's overall posture strategy.
func select_facility_strategy() -> StringName:
	return &"STEADY_STATE"


## Selects the operation strategy for [param operation_type].
func select_operation_strategy(_operation_type: int) -> StringName:
	return &"AUTO"


## Dispatches [param strategy] for the current interval. Override to change
## dispatch; override the stub method itself to change a strategy's behavior.
func implement_facility_strategy(strategy: StringName, delta: float) -> void:
	var method: StringName = facility_strategies[strategy]
	call(method, delta)


## Dispatches [param strategy] for [param operation_type]. Override to change
## dispatch; override the stub method itself to change a strategy's behavior.
func implement_operation_strategy(operation_type: int, strategy: StringName, delta: float) -> void:
	var method: StringName = operation_strategies[strategy]
	call(method, operation_type, delta)


func process_ai_interval(_delta: float) -> void:
	pass


func process_ai_new_quarter() -> void:
	pass


# ************************** FACILITY-POSTURE STUBS ***************************

## Pursue expansion of capacity and footprint; accept thinner margins.
## Analog: scale-up startup, frontier development.
func _facility_growth(_delta: float) -> void:
	pass


## Optimize ROI on existing capacity; defer expansion. Analog: mature
## industrial site tuning throughput.
func _facility_profitability(_delta: float) -> void:
	pass


## Spread operations across resources and process groups to reduce
## concentration risk. Analog: integrated conglomerate.
func _facility_diversification(_delta: float) -> void:
	pass


## Focus capacity on the most profitable or strategic operations; let others
## wither. Analog: hyper-focused supplier (e.g., a single-product foundry).
func _facility_specialization(_delta: float) -> void:
	pass


## Maintain presence and capability regardless of economics. Analog: forward
## military base, polar research station.
func _facility_strategic_outpost(_delta: float) -> void:
	pass


## Early-stage facility; prioritize learning, training, and capability over
## current profit. Analog: pilot plant, new colony.
func _facility_development(_delta: float) -> void:
	pass


## Mature operations; replace capacity as it depreciates; resist large
## swings. Analog: established refinery or mill.
func _facility_steady_state(_delta: float) -> void:
	pass


## Orderly wind-down of all operations; preserve safety; do not reinvest.
## Analog: planned plant closure.
func _facility_decommissioning(_delta: float) -> void:
	pass


## Crisis mode; activate all available capacity; suspend normal economic
## constraints. Analog: wartime production, disaster response.
func _facility_emergency(_delta: float) -> void:
	pass


# ************************* OPERATION-STRATEGY STUBS **************************

## Delegate to server-side automation hints ([code]OpFlags[/code]); minimal
## AI intervention.
func _operation_auto(_operation_type: int, _delta: float) -> void:
	pass


## Run when gross margin is positive; ramp up in favorable periods; idle
## when unprofitable. Analog: merchant power plant on the spot market.
func _operation_profit_maximize(_operation_type: int, _delta: float) -> void:
	pass


## Run at full capacity regardless of margin. Analog: wartime production
## quota, strategic stockpile build.
func _operation_volume_maximize(_operation_type: int, _delta: float) -> void:
	pass


## Run continuously at a steady rate; do not chase short-term price signals.
## Analog: nuclear plants, blast furnaces — expensive to cycle.
func _operation_baseload(_operation_type: int, _delta: float) -> void:
	pass


## Idle most of the time; activate only during price spikes or shortages.
## Analog: gas-peaking power plants.
func _operation_peaker(_operation_type: int, _delta: float) -> void:
	pass


## Idle but preserve restart capability without decommissioning. Analog:
## laid-up steel mills, cocooned aircraft.
func _operation_mothball(_operation_type: int, _delta: float) -> void:
	pass


## Wind down toward permanent retirement; do not invest in maintenance.
## Analog: end-of-life mine, deprecated fab.
func _operation_decommission(_operation_type: int, _delta: float) -> void:
	pass


## Throttle to match observed local offtake. Analog: load-following power
## plant.
func _operation_demand_following(_operation_type: int, _delta: float) -> void:
	pass


## Ramp up in response to local shortages even at margin loss. Analog:
## emergency-supply duty, public-utility obligation.
func _operation_shortage_relief(_operation_type: int, _delta: float) -> void:
	pass


## Run regardless of margin to drive down unit costs and accumulate
## experience. Analog: early-stage industries (early solar, EVs) on the
## learning curve.
func _operation_learning(_operation_type: int, _delta: float) -> void:
	pass


## Extract maximum output while resource quality is high; defer maintenance
## and reinvestment. Analog: late-stage mining, declining oilfield.
func _operation_harvest(_operation_type: int, _delta: float) -> void:
	pass


## Maintain a minimum viable run rate for strategic reasons even at a loss.
## Analog: keeping a domestic semiconductor fab alive for national security.
func _operation_strategic_hold(_operation_type: int, _delta: float) -> void:
	pass
