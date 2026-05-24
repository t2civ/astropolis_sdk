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
## Strategies are declarative. Each [code]select_*_strategy()[/code] returns
## a [StringName] that is cached in a [code]current_*_strategy[/code] field;
## children read parent declarations during their own selection. Member data
## lives in the static registries as inner [Dictionary]s (empty for now);
## parameter knobs and an optional [code]"method"[/code] key for per-strategy
## logic overrides may grow into them. Execution (bid/ask submission) is
## centralized in [method process_ai_interval] — currently a placeholder
## pending base [TraderProxy] facilities.
##
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [TraderProxy]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [TraderProxy]. See
## [PlayerCustomAI] for the extension template — the registry / select /
## refresh pattern is the same for all three [code]BaseAI[/code] classes.
##
## [b]Trader strategies[/b][br]
## • NEUTRAL - Starting / no-op stance; no special posture.[br]
## • FACILITY_SUPPORT - Trade primarily to service the facility's operational needs — replenish inputs, clear outputs. Analog: a procurement / sales desk inside a manufacturing firm.[br]
## • PROFIT_FOCUS - Trade to maximize the trader's own P&L; accept some operational risk to the facility. Analog: a proprietary commodity-trading desk.[br]
## • CONSERVATIVE - Minimize trading risk; carry ample buffer stock; avoid speculative positions. Analog: utility-style fuel procurement.[br]
## • OPPORTUNISTIC - Pursue spreads and arbitrage aggressively; tolerate inventory volatility. Analog: merchant trader.[br]
## • POLICY_AGENT - Subordinate trading to the owning player's policy — embargoes, dumping, stockpiling — even at facility cost. Analog: state-owned trading enterprise.
##
## [b]Resource strategies[/b][br]
## • NEUTRAL - No special stance; replenish operational reserves and clear surplus at prevailing market prices.[br]
## • JUST_IN_TIME - Hold minimal inventory; replenish in small, frequent lots. Analog: lean-manufacturing inputs.[br]
## • STRATEGIC_RESERVE - Build inventory well beyond operational need; willing to pay above-market to accumulate. Analog: strategic petroleum reserve, semiconductor stockpile.[br]
## • LIQUIDATE - Wind down holdings aggressively; sell at unfavorable prices if needed. Analog: divestiture from an asset class.[br]
## • HOARD - Withhold supply from market regardless of price. Analog: OPEC production cut, sovereign export ban.[br]
## • DUMP - Sell into the market at depressed prices to clear inventory or harm competing suppliers. Analog: predatory dumping, fire sale.[br]
## • MARKET_MAKING - Quote both bid and ask; profit on the spread; provide liquidity. Analog: market-maker / specialist desks.[br]
## • SPECULATIVE_LONG - Build inventory in expectation of price rise; accept carrying cost. Analog: contango trade, commodity bull bet.[br]
## • SPECULATIVE_SHORT - Defer purchases and run down inventory in expectation of price decline. Analog: shorting commodities.[br]
## • AUTARKIC - Do not trade this resource externally; rely on the facility's own production / consumption. Analog: import substitution, closed-cycle process.[br]
## • EXPORT_FOCUS - Facility produces surplus of this resource; push to market aggressively. Analog: export-oriented industry.[br]
## • IMPORT_PRIORITY - Facility critically needs this resource; pay a premium to secure continuity. Analog: critical-input procurement under shortage.[br]
## • OPPORTUNISTIC - No standing position; act only on price dislocations. Analog: arbitrage / value buying.


# **************************** STRATEGY REGISTRIES ****************************

## Overall trader-posture strategies; key -> per-member data dict (empty
## placeholder for now; may grow parameter knobs or an optional
## [code]"method"[/code] key for per-strategy logic overrides). Extend via
## [method register_trader_strategy].
static var trader_strategies: Dictionary[StringName, Dictionary] = {
	&"NEUTRAL": {},
	&"FACILITY_SUPPORT": {},
	&"PROFIT_FOCUS": {},
	&"CONSERVATIVE": {},
	&"OPPORTUNISTIC": {},
	&"POLICY_AGENT": {},
}

## Per-resource trading strategies; key -> per-member data dict. Extend via
## [method register_resource_strategy].
static var resource_strategies: Dictionary[StringName, Dictionary] = {
	&"NEUTRAL": {},
	&"JUST_IN_TIME": {},
	&"STRATEGIC_RESERVE": {},
	&"LIQUIDATE": {},
	&"HOARD": {},
	&"DUMP": {},
	&"MARKET_MAKING": {},
	&"SPECULATIVE_LONG": {},
	&"SPECULATIVE_SHORT": {},
	&"AUTARKIC": {},
	&"EXPORT_FOCUS": {},
	&"IMPORT_PRIORITY": {},
	&"OPPORTUNISTIC": {},
}


## Registers [param strategy] in [member trader_strategies]. Asserts on
## duplicate to surface accidental collisions between mod registrations.
static func register_trader_strategy(strategy: StringName, data: Dictionary) -> void:
	assert(!trader_strategies.has(strategy), "Trader strategy already registered: %s" % strategy)
	trader_strategies[strategy] = data


## Registers [param strategy] in [member resource_strategies]. Asserts on
## duplicate.
static func register_resource_strategy(strategy: StringName, data: Dictionary) -> void:
	assert(!resource_strategies.has(strategy), "Resource strategy already registered: %s" % strategy)
	resource_strategies[strategy] = data


# ********************************** AI API ***********************************

## Currently selected trader-posture strategy. Updated by
## [method _refresh_selections] on each quarter tick; read by this trader's
## own executor and by anything consulting this trader's declarations.
## Not persisted across save/load; re-derived on next quarter tick.
## (If GUI/server ever needs to mirror this, use [code]Proxy.DirtyFlags[/code]
## per the established pattern — not a parallel sync path.)
var current_trader_strategy: StringName = &"NEUTRAL"

## Currently selected per-resource strategies, keyed by resource_type (int).
## Lazy-populated as resources come into scope. Not persisted.
var current_resource_strategies: Dictionary = {}


## Selects this trader's overall posture strategy. May consult parent
## declarations via [code]facility.player.current_*[/code].
func select_trader_strategy() -> StringName:
	return &"NEUTRAL"


## Selects the resource strategy for [param resource_type]. May consult
## [code]facility.player.current_resource_strategies[resource_type][/code].
func select_resource_strategy(_resource_type: int) -> StringName:
	return &"NEUTRAL"


## Updates [member current_trader_strategy] and per-resource selections from
## the [code]select_*[/code] methods. Override to change refresh policy.
## Per-resource refresh is a TODO pending a traded-resource enumeration source
## on [TraderProxy].
func _refresh_selections() -> void:
	current_trader_strategy = select_trader_strategy()
	assert(trader_strategies.has(current_trader_strategy),
			"select_trader_strategy returned unregistered key: %s" % current_trader_strategy)
	# TODO: iterate traded resources and refresh current_resource_strategies
	# once TraderProxy exposes its resource list.


## Placeholder. Future executor will read [member current_trader_strategy]
## and [member current_resource_strategies] and submit/cancel bids and asks
## through base [TraderProxy] facilities (not yet exposed).
func process_ai_interval(_delta: float) -> void:
	pass


func process_ai_new_quarter() -> void:
	_refresh_selections()
