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


## Trader-posture strategies.
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

## Per-resource trading strategies.
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
	## Run holdings down gradually as part of an orderly exit; sell into
	## rallies, do not add to position. Distinct from [code]LIQUIDATE[/code],
	## which accepts unfavorable prices to clear immediately. Analog: a
	## divesting fund quietly reducing a position over months.
	WIND_DOWN,
	N_BASE_RESOURCE_STRATEGIES,
}


## Trader-posture strategy definitions; index = [enum TraderStrategies] value.
static var trader_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # FACILITY_SUPPORT
	{}, # PROFIT_FOCUS
	{}, # CONSERVATIVE
	{}, # OPPORTUNISTIC
	{}, # POLICY_AGENT
]

## Per-resource strategy definitions; index = [enum ResourceStrategies] value.
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
	{}, # WIND_DOWN
]


# *****************************************************************************
# persisted

## Trader-posture strategy. See [enum TraderStrategies].
var trader_strategy := 0
## Per-resource strategies. See [enum ResourceStrategies].
var resource_strategies: PackedInt32Array

# *****************************************************************************

var _facility_ai: FacilityBaseAI



# ************************* VIRTUAL & IMPLEMENTATION **************************

func _init() -> void:
	super()
	persist.append(&"trader_strategy")
	persist.append(&"resource_strategies")
	var n_resources: int = _table_n_rows[&"resources"]
	resource_strategies.resize(n_resources)


func process_ai_init() -> void:
	super()
	_facility_ai = facility as FacilityBaseAI
	assert(_facility_ai, "TraderBaseAI expects facility to be FacilityBaseAI")
	_facility_ai.facility_resource_strategy_changed.connect(_on_facility_resource_strategy_changed)


func process_ai_interval(_delta: float) -> void:
	pass


# **************************** STRATEGY LISTENERS *****************************

func _on_facility_resource_strategy_changed(_resource_type: int, _strategy_id: int) -> void:
	pass


# *************************** INCOMING MARKET CALLS ***************************

func _update_ask(_data: Array) -> void:
	pass
