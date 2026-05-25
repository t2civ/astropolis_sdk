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
## an [int] enum id (see [enum TraderStrategies], [enum ResourceStrategies])
## cached in a [code]<name>_strategy[/code] field; children read parent
## declarations during their own selection. Per-strategy data lives in the
## static [code]*_strategy_defs[/code] arrays as inner [Dictionary]s (empty
## for now); parameter knobs and an optional [code]"method"[/code] key for
## per-strategy logic overrides may grow into them. Cached selections are
## persisted via [member Proxy.persist] so player intent survives save/load,
## and are re-derived on each quarter tick on top of the loaded value.
## Execution (bid/ask submission) is centralized in
## [method process_ai_interval] — currently a placeholder pending base
## [TraderProxy] facilities.
##
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [TraderProxy]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [TraderProxy]. See
## [PlayerCustomAI] for the extension template — the registry / select /
## refresh pattern is the same for all three [code]BaseAI[/code] classes.


## Trader-posture strategies. By convention id 0 is the no-op default
## (NEUTRAL, AUTO, or similar) used as the starting state. Add-on strategies
## from custom AI subclasses begin at [code]N_BASE_TRADER_STRATEGIES[/code].
enum TraderStrategies {
	## Starting / no-op stance; no special posture.
	NEUTRAL,
	## Trade primarily to service the facility's operational needs — replenish
	## inputs, clear outputs. Analog: a procurement / sales desk inside a
	## manufacturing firm.
	FACILITY_SUPPORT,
	## Trade to maximize the trader's own P&L; accept some operational risk
	## to the facility. Analog: a proprietary commodity-trading desk.
	PROFIT_FOCUS,
	## Minimize trading risk; carry ample buffer stock; avoid speculative
	## positions. Analog: utility-style fuel procurement.
	CONSERVATIVE,
	## Pursue spreads and arbitrage aggressively; tolerate inventory
	## volatility. Analog: merchant trader.
	OPPORTUNISTIC,
	## Subordinate trading to the owning player's policy — embargoes, dumping,
	## stockpiling — even at facility cost. Analog: state-owned trading
	## enterprise.
	POLICY_AGENT,
	N_BASE_TRADER_STRATEGIES,
}

## Per-resource trading strategies. By convention id 0 is the no-op default.
## Add-on strategies begin at [code]N_BASE_RESOURCE_STRATEGIES[/code].
enum ResourceStrategies {
	## No special stance; replenish operational reserves and clear surplus at
	## prevailing market prices.
	NEUTRAL,
	## Hold minimal inventory; replenish in small, frequent lots. Analog:
	## lean-manufacturing inputs.
	JUST_IN_TIME,
	## Build inventory well beyond operational need; willing to pay
	## above-market to accumulate. Analog: strategic petroleum reserve,
	## semiconductor stockpile.
	STRATEGIC_RESERVE,
	## Wind down holdings aggressively; sell at unfavorable prices if needed.
	## Analog: divestiture from an asset class.
	LIQUIDATE,
	## Withhold supply from market regardless of price. Analog: OPEC
	## production cut, sovereign export ban.
	HOARD,
	## Sell into the market at depressed prices to clear inventory or harm
	## competing suppliers. Analog: predatory dumping, fire sale.
	DUMP,
	## Quote both bid and ask; profit on the spread; provide liquidity.
	## Analog: market-maker / specialist desks.
	MARKET_MAKING,
	## Build inventory in expectation of price rise; accept carrying cost.
	## Analog: contango trade, commodity bull bet.
	SPECULATIVE_LONG,
	## Defer purchases and run down inventory in expectation of price decline.
	## Analog: shorting commodities.
	SPECULATIVE_SHORT,
	## Do not trade this resource externally; rely on the facility's own
	## production / consumption. Analog: import substitution, closed-cycle
	## process.
	AUTARKIC,
	## Facility produces surplus of this resource; push to market aggressively.
	## Analog: export-oriented industry.
	EXPORT_FOCUS,
	## Facility critically needs this resource; pay a premium to secure
	## continuity. Analog: critical-input procurement under shortage.
	IMPORT_PRIORITY,
	## No standing position; act only on price dislocations. Analog: arbitrage
	## / value buying.
	OPPORTUNISTIC,
	N_BASE_RESOURCE_STRATEGIES,
}


# **************************** STRATEGY REGISTRIES ****************************

## Trader-posture strategy definitions; index = [enum TraderStrategies] value.
## Each inner [Dictionary] is per-strategy data (empty placeholder for now;
## may grow parameter knobs and an optional [code]"method"[/code] key for
## per-strategy logic overrides). Add-on strategies append via
## [method register_trader_strategy].
static var trader_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # FACILITY_SUPPORT
	{}, # PROFIT_FOCUS
	{}, # CONSERVATIVE
	{}, # OPPORTUNISTIC
	{}, # POLICY_AGENT
]

## Per-resource strategy definitions; index = [enum ResourceStrategies] value.
## Add-on strategies append via [method register_resource_strategy].
static var resource_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # JUST_IN_TIME
	{}, # STRATEGIC_RESERVE
	{}, # LIQUIDATE
	{}, # HOARD
	{}, # DUMP
	{}, # MARKET_MAKING
	{}, # SPECULATIVE_LONG
	{}, # SPECULATIVE_SHORT
	{}, # AUTARKIC
	{}, # EXPORT_FOCUS
	{}, # IMPORT_PRIORITY
	{}, # OPPORTUNISTIC
]


## Appends [param data] for [param strategy_id] in [member trader_strategy_defs].
## [param strategy_id] must equal the current array size (contiguous append) —
## surfaces colliding mod registrations as a debug assert rather than silent
## last-write-wins.
static func register_trader_strategy(strategy_id: int, data: Dictionary) -> void:
	assert(strategy_id == trader_strategy_defs.size(),
			"Non-contiguous trader strategy id %d; expected %d"
			% [strategy_id, trader_strategy_defs.size()])
	trader_strategy_defs.append(data)


## Appends [param data] for [param strategy_id] in
## [member resource_strategy_defs]. See [method register_trader_strategy] for
## the contiguous-append contract.
static func register_resource_strategy(strategy_id: int, data: Dictionary) -> void:
	assert(strategy_id == resource_strategy_defs.size(),
			"Non-contiguous resource strategy id %d; expected %d"
			% [strategy_id, resource_strategy_defs.size()])
	resource_strategy_defs.append(data)


# ********************************** AI API ***********************************

## Currently selected trader-posture strategy id; see [enum TraderStrategies].
## By convention 0 is the NEUTRAL (no-op default) value. Persisted via
## [member Proxy.persist] so player intent survives save/load; updated each
## quarter by [method _refresh_selections].
var trader_strategy := 0

## Currently selected per-resource strategy ids, indexed by [code]resource_type[/code]
## (resources-table row). Sized in [method _init] to the resources-table row
## count; entries default to 0 (NEUTRAL). Persisted via [member Proxy.persist].
var resource_strategies: PackedInt32Array


func _init() -> void:
	super()
	persist.append(&"trader_strategy")
	persist.append(&"resource_strategies")
	var n_resources: int = _table_n_rows[&"resources"]
	resource_strategies.resize(n_resources)


## Selects this trader's overall posture strategy. May consult parent
## declarations via [code]facility.player.<name>_strategy[/code].
func select_trader_strategy() -> int:
	return 0 # NEUTRAL


## Selects the resource strategy for [param resource_type]. May consult
## [code]facility.player.resource_strategies[resource_type][/code].
func select_resource_strategy(_resource_type: int) -> int:
	return 0 # NEUTRAL


## Updates [member trader_strategy] and per-resource selections from the
## [code]select_*[/code] methods. Override to change refresh policy.
## Per-resource refresh is a TODO pending a traded-resource enumeration
## source on [TraderProxy].
func _refresh_selections() -> void:
	trader_strategy = select_trader_strategy()
	assert(trader_strategy >= 0 and trader_strategy < trader_strategy_defs.size(),
			"select_trader_strategy returned invalid id: %d" % trader_strategy)
	# TODO: iterate traded resources and refresh resource_strategies
	# once TraderProxy exposes its resource list.


## Placeholder. Future executor will read [member trader_strategy] and
## [member resource_strategies] and submit/cancel bids and asks through
## base [TraderProxy] facilities (not yet exposed).
func process_ai_interval(_delta: float) -> void:
	pass


func process_ai_new_quarter() -> void:
	_refresh_selections()
