# trader_base_ai.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name TraderBaseAI
extends TraderProxy

## Default AI for traders the local player owns. Subclass to write custom
## trader AI; the base [TraderProxy] is used for all non-owner peers.
##
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [TraderProxy]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [TraderProxy]. See
## [PlayerCustomAI] for the extension template — the registry / select /
## implement pattern is the same for all three [code]BaseAI[/code] classes.


# **************************** STRATEGY REGISTRIES ****************************

## Overall trader-posture strategies; key -> stub-method name on this class.
## Extend via [method register_trader_strategy].
static var trader_strategies: Dictionary[StringName, StringName] = {
	&"FACILITY_SUPPORT": &"_trader_facility_support",
	&"PROFIT_FOCUS": &"_trader_profit_focus",
	&"CONSERVATIVE": &"_trader_conservative",
	&"OPPORTUNISTIC": &"_trader_opportunistic",
	&"POLICY_AGENT": &"_trader_policy_agent",
}

## Per-resource trading strategies; key -> stub-method name on this class.
## Extend via [method register_resource_strategy].
static var resource_strategies: Dictionary[StringName, StringName] = {
	&"NEUTRAL": &"_resource_neutral",
	&"JUST_IN_TIME": &"_resource_just_in_time",
	&"STRATEGIC_RESERVE": &"_resource_strategic_reserve",
	&"LIQUIDATE": &"_resource_liquidate",
	&"HOARD": &"_resource_hoard",
	&"DUMP": &"_resource_dump",
	&"MARKET_MAKING": &"_resource_market_making",
	&"SPECULATIVE_LONG": &"_resource_speculative_long",
	&"SPECULATIVE_SHORT": &"_resource_speculative_short",
	&"AUTARKIC": &"_resource_autarkic",
	&"EXPORT_FOCUS": &"_resource_export_focus",
	&"IMPORT_PRIORITY": &"_resource_import_priority",
	&"OPPORTUNISTIC": &"_resource_opportunistic",
}


## Adds or rewires [param strategy] in [member trader_strategies]. Idempotent.
static func register_trader_strategy(strategy: StringName, method_name: StringName) -> void:
	trader_strategies[strategy] = method_name


## Adds or rewires [param strategy] in [member resource_strategies]. Idempotent.
static func register_resource_strategy(strategy: StringName, method_name: StringName) -> void:
	resource_strategies[strategy] = method_name


# ********************************** AI API ***********************************

## Selects this trader's overall posture strategy.
func select_trader_strategy() -> StringName:
	return &"FACILITY_SUPPORT"


## Selects the resource strategy for [param resource_type].
func select_resource_strategy(_resource_type: int) -> StringName:
	return &"NEUTRAL"


## Dispatches [param strategy] for the current interval. Override to change
## dispatch; override the stub method itself to change a strategy's behavior.
func implement_trader_strategy(strategy: StringName, delta: float) -> void:
	var method: StringName = trader_strategies[strategy]
	call(method, delta)


## Dispatches [param strategy] for [param resource_type]. Override to change
## dispatch; override the stub method itself to change a strategy's behavior.
func implement_resource_strategy(resource_type: int, strategy: StringName, delta: float) -> void:
	var method: StringName = resource_strategies[strategy]
	call(method, resource_type, delta)


func process_ai_interval(_delta: float) -> void:
	pass


func process_ai_new_quarter() -> void:
	pass


# ************************** TRADER-POSTURE STUBS *****************************

## Default; trade primarily to service the facility's operational needs —
## replenish inputs, clear outputs. Analog: a procurement / sales desk inside
## a manufacturing firm.
func _trader_facility_support(_delta: float) -> void:
	pass


## Trade to maximize the trader's own P&L; accept some operational risk to
## the facility. Analog: a proprietary commodity-trading desk.
func _trader_profit_focus(_delta: float) -> void:
	pass


## Minimize trading risk; carry ample buffer stock; avoid speculative
## positions. Analog: utility-style fuel procurement.
func _trader_conservative(_delta: float) -> void:
	pass


## Pursue spreads and arbitrage aggressively; tolerate inventory volatility.
## Analog: merchant trader.
func _trader_opportunistic(_delta: float) -> void:
	pass


## Subordinate trading to the owning player's policy — embargoes, dumping,
## stockpiling — even at facility cost. Analog: state-owned trading
## enterprise.
func _trader_policy_agent(_delta: float) -> void:
	pass


# ************************** RESOURCE-STRATEGY STUBS **************************

## No special stance; replenish operational reserves and clear surplus at
## prevailing market prices.
func _resource_neutral(_resource_type: int, _delta: float) -> void:
	pass


## Hold minimal inventory; replenish in small, frequent lots. Analog:
## lean-manufacturing inputs.
func _resource_just_in_time(_resource_type: int, _delta: float) -> void:
	pass


## Build inventory well beyond operational need; willing to pay above-market
## to accumulate. Analog: strategic petroleum reserve, semiconductor
## stockpile.
func _resource_strategic_reserve(_resource_type: int, _delta: float) -> void:
	pass


## Wind down holdings aggressively; sell at unfavorable prices if needed.
## Analog: divestiture from an asset class.
func _resource_liquidate(_resource_type: int, _delta: float) -> void:
	pass


## Withhold supply from market regardless of price. Analog: OPEC production
## cut, sovereign export ban.
func _resource_hoard(_resource_type: int, _delta: float) -> void:
	pass


## Sell into the market at depressed prices to clear inventory or harm
## competing suppliers. Analog: predatory dumping, fire sale.
func _resource_dump(_resource_type: int, _delta: float) -> void:
	pass


## Quote both bid and ask; profit on the spread; provide liquidity. Analog:
## market-maker / specialist desks.
func _resource_market_making(_resource_type: int, _delta: float) -> void:
	pass


## Build inventory in expectation of price rise; accept carrying cost.
## Analog: contango trade, commodity bull bet.
func _resource_speculative_long(_resource_type: int, _delta: float) -> void:
	pass


## Defer purchases and run down inventory in expectation of price decline.
## Analog: shorting commodities.
func _resource_speculative_short(_resource_type: int, _delta: float) -> void:
	pass


## Do not trade this resource externally; rely on the facility's own
## production / consumption. Analog: import substitution, closed-cycle
## process.
func _resource_autarkic(_resource_type: int, _delta: float) -> void:
	pass


## Facility produces surplus of this resource; push to market aggressively.
## Analog: export-oriented industry.
func _resource_export_focus(_resource_type: int, _delta: float) -> void:
	pass


## Facility critically needs this resource; pay a premium to secure
## continuity. Analog: critical-input procurement under shortage.
func _resource_import_priority(_resource_type: int, _delta: float) -> void:
	pass


## No standing position; act only on price dislocations. Analog: arbitrage /
## value buying.
func _resource_opportunistic(_resource_type: int, _delta: float) -> void:
	pass
