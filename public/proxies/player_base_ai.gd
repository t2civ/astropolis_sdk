# player_base_ai.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name PlayerBaseAI
extends PlayerProxy

## Default AI for the local player. Subclass to write custom player AI; the
## base [PlayerProxy] is used for all non-owner peers.
##
## Strategies are declarative. Each [code]select_*_strategy()[/code] returns
## an [int] enum id (see [enum GlobalStrategies], [enum ResourceStrategies],
## etc.) cached in a [code]<name>_strategy[/code] field or in a per-item
## container; child AIs ([FacilityBaseAI], [TraderBaseAI]) read these
## declarations during their own selection. Per-strategy data lives in the
## static [code]*_strategy_defs[/code] arrays as inner [Dictionary]s (empty
## for now); parameter knobs and an optional [code]"method"[/code] key for
## per-strategy logic overrides may grow into them. Cached selections are
## persisted via [member Proxy.persist] so player intent survives save/load,
## and are re-derived on each quarter tick on top of the loaded value.
## Execution (construction queue, diplomatic actions, etc.) is centralized
## in [method process_ai_interval] — currently a placeholder pending base
## [PlayerProxy] facilities.
##
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [PlayerProxy]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [PlayerProxy]. See
## [PlayerCustomAI] for the extension template — the registry / select /
## refresh pattern is the same for all three [code]BaseAI[/code] classes.


## The player's grand strategic posture. By convention id 0 is the no-op
## default (NEUTRAL, AUTO, or similar) used as the starting state. Add-on
## strategies begin at [code]N_BASE_GLOBAL_STRATEGIES[/code].
enum GlobalStrategies {
	## Starting / no-op stance; no special posture.
	NEUTRAL,
	## Pursue dominance across most sectors; accept high cost to maintain
	## primacy. Analog: post-WWII U.S. grand strategy.
	HEGEMONY,
	## Maintain rough parity with leading rivals; avoid overcommitment in any
	## single arena. Analog: classical European balance-of-power.
	BALANCING,
	## Maximize self-sufficiency in critical sectors; reduce dependency on
	## rivals. Analog: China's "dual circulation," Gaullist independence.
	AUTONOMY,
	## Pursue cooperation, joint ventures, and alliances; accept
	## interdependence. Analog: EU integration, multilateral institutions.
	INTEGRATION,
	## Maximize footprint and economic expansion; accept thinner margins.
	GROWTH,
	## Mature posture; optimize existing portfolio; minimize new commitments.
	## Analog: late-stage industrial economies.
	CONSOLIDATION,
	## Pursue flagship visible achievements over economic optimization.
	## Analog: Apollo program, Olympic hosting, national megaprojects.
	PRESTIGE,
	## Prioritize research, exploration, and knowledge production. Analog:
	## NASA / ESA mission selection, basic-research agencies.
	SCIENCE,
	## Treat all activity as profit-seeking; minimize non-economic missions.
	## Analog: SpaceX / Blue Origin business model.
	COMMERCIAL,
	## Prioritize long-term sustainability, biome health, and biodiversity
	## over output. Analog: green-economy / degrowth advocacy.
	STEWARDSHIP,
	## Pursue new bodies and frontier development at high risk. Analog:
	## age-of-exploration powers, settler colonialism.
	EXPANSION,
	## Crisis posture; preserve core capabilities; accept losses elsewhere.
	## Analog: post-Soviet Russia, post-collapse states.
	SURVIVAL,
	## Late-stage extraction; maximize cash and dividends; minimize
	## reinvestment. Analog: private-equity strip, declining empires
	## monetizing colonies.
	HARVEST,
	N_BASE_GLOBAL_STRATEGIES,
}

## Per-resource player-level strategies (distinct from
## [enum TraderBaseAI.ResourceStrategies] — this is how the player wants the
## global market for the resource to look). By convention id 0 is the no-op
## default. Add-on strategies begin at [code]N_BASE_RESOURCE_STRATEGIES[/code].
enum ResourceStrategies {
	## No special player stance; traders apply their own per-resource
	## strategies independently.
	NEUTRAL,
	## Pursue market-share leadership in production and export; undercut
	## rivals if needed. Analog: Saudi Arabia in oil, China in rare earths.
	DOMINATE_SUPPLY,
	## Be the buyer-of-resort; lock in supply via long-term contracts.
	## Analog: China's commodity-securing diplomacy.
	DOMINATE_DEMAND,
	## Maintain reserves across the portfolio well beyond operational need.
	## Analog: U.S. Strategic Petroleum Reserve, national grain reserves.
	STRATEGIC_STOCKPILE,
	## Produce all internal needs domestically; avoid net imports. Analog:
	## food-security policy, semiconductor independence.
	SELF_SUFFICIENCY,
	## Treat the resource as a primary revenue source; maximize external
	## sales. Analog: petrostates.
	EXPORT_REVENUE,
	## Reduce exposure; phase out production and inventory. Analog: coal
	## divestment, fossil-fuel phase-out commitments.
	DIVEST,
	## Refuse to trade with specified counterparties. Analog: U.S.
	## semiconductor export controls.
	EMBARGO,
	## Buy to maintain a price floor; subsidize producers. Analog:
	## agricultural price supports, sovereign oil-purchase programs.
	PRICE_SUPPORT,
	## Release reserves or overproduce to depress price. Analog: Saudi oil
	## price wars, strategic-reserve releases.
	PRICE_SUPPRESS,
	## Watch closely without active intervention; reserve right to act later.
	## Analog: contingency planning.
	MONITOR,
	N_BASE_RESOURCE_STRATEGIES,
}

## Per-owned-facility player-level strategies (distinct from
## [enum FacilityBaseAI.FacilityStrategies] — this is how the player views
## the role of each owned facility in the portfolio). By convention id 0 is
## the no-op default. Add-on strategies begin at
## [code]N_BASE_FACILITY_STRATEGIES[/code].[br]
## TODO: rename + re-key by facility type when
## [member FacilityProxy.facility_class] is implemented. Selection then moves
## from per-instance to per-type.
enum FacilityStrategies {
	## Let the facility's own AI determine its posture.
	NEUTRAL,
	## Showcase asset; priority resourcing and attention. Analog: corporate
	## flagship factory, prestige research center.
	FLAGSHIP,
	## High-growth, high-margin asset; reinvest aggressively. Analog:
	## BCG-matrix "star."
	STAR,
	## Mature profitable asset; optimize for cash extraction; minimal
	## reinvestment. Analog: BCG-matrix "cash cow."
	CASH_COW,
	## Uncertain prospect; monitor closely; willing to cut if it doesn't
	## perform. Analog: BCG-matrix "question mark."
	QUESTION_MARK,
	## Underperformer; candidate for divestiture or closure. Analog:
	## BCG-matrix "dog."
	DOG,
	## Maintain regardless of economics for sovereignty or presence reasons.
	## Analog: forward military bases, polar research stations.
	STRATEGIC_OUTPOST,
	## Sustained at a loss for political reasons; receives transfers from
	## rest of portfolio. Analog: state-owned enterprises kept alive for
	## employment or prestige.
	SUBSIDIZED,
	## Active wind-down; planned closure or sale. Analog: planned plant
	## closure.
	DIVEST,
	N_BASE_FACILITY_STRATEGIES,
}

## Per-body player-level strategies. By convention id 0 is the no-op default.
## Add-on strategies begin at [code]N_BASE_BODY_STRATEGIES[/code].
enum BodyStrategies {
	## No special player stance toward this body.
	NEUTRAL,
	## Concentrate new facility-building and resourcing here. Analog: Project
	## Apollo's Moon focus, Mars-first agencies.
	PRIORITY_DEVELOPMENT,
	## Maintain a footprint but don't grow it aggressively. Analog: minor
	## research outposts.
	SECONDARY_PRESENCE,
	## Treat the body primarily as a resource source; extract aggressively.
	## Analog: colonial extractive economies.
	EXPLOIT,
	## Limit development for environmental or scientific reasons. Analog:
	## protected reserves, Antarctica-treaty-style scientific zones.
	CONSERVE,
	## Wind down all facilities on this body; withdraw entirely.
	EXIT,
	N_BASE_BODY_STRATEGIES,
}

## Per-other-player strategies (diplomatic / trade posture). By convention
## id 0 is the no-op default. Add-on strategies begin at
## [code]N_BASE_COUNTERPARTY_STRATEGIES[/code].
enum CounterpartyStrategies {
	## No special stance toward this counterparty.
	NEUTRAL,
	## Preferred trading partner; willing to support via favorable terms or
	## joint ventures. Analog: NATO members, EU partners.
	ALLY,
	## Normal commercial relationship; treat as standard counterparty.
	PARTNER,
	## Compete actively; deny advantages where practical without open
	## hostility. Analog: U.S.–China economic competition.
	RIVAL,
	## Refuse to deal; pursue measures to harm their economy. Analog: Cold
	## War-era trade blocs.
	HOSTILE,
	## Comprehensive trade prohibition. Analog: U.S. sanctions on Iran, North
	## Korea.
	EMBARGOED,
	## Subordinate counterparty; provide support in exchange for political
	## alignment. Analog: patron-client state relationships.
	CLIENT,
	N_BASE_COUNTERPARTY_STRATEGIES,
}


# **************************** STRATEGY REGISTRIES ****************************

## Grand-strategy definitions; index = [enum GlobalStrategies] value. Each
## inner [Dictionary] is per-strategy data (empty placeholder for now; may
## grow parameter knobs and an optional [code]"method"[/code] key for
## per-strategy logic overrides). Add-on strategies append via
## [method register_global_strategy].
static var global_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # HEGEMONY
	{}, # BALANCING
	{}, # AUTONOMY
	{}, # INTEGRATION
	{}, # GROWTH
	{}, # CONSOLIDATION
	{}, # PRESTIGE
	{}, # SCIENCE
	{}, # COMMERCIAL
	{}, # STEWARDSHIP
	{}, # EXPANSION
	{}, # SURVIVAL
	{}, # HARVEST
]

## Per-resource player-level strategy definitions; index =
## [enum ResourceStrategies] value. Add-on strategies append via
## [method register_resource_strategy].
static var resource_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # DOMINATE_SUPPLY
	{}, # DOMINATE_DEMAND
	{}, # STRATEGIC_STOCKPILE
	{}, # SELF_SUFFICIENCY
	{}, # EXPORT_REVENUE
	{}, # DIVEST
	{}, # EMBARGO
	{}, # PRICE_SUPPORT
	{}, # PRICE_SUPPRESS
	{}, # MONITOR
]

## Per-owned-facility player-level strategy definitions; index =
## [enum FacilityStrategies] value. Add-on strategies append via
## [method register_facility_strategy].[br]
## TODO: rename + re-key by facility type when
## [member FacilityProxy.facility_class] is implemented.
static var facility_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # FLAGSHIP
	{}, # STAR
	{}, # CASH_COW
	{}, # QUESTION_MARK
	{}, # DOG
	{}, # STRATEGIC_OUTPOST
	{}, # SUBSIDIZED
	{}, # DIVEST
]

## Per-body player-level strategy definitions; index = [enum BodyStrategies]
## value. Add-on strategies append via [method register_body_strategy].
static var body_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # PRIORITY_DEVELOPMENT
	{}, # SECONDARY_PRESENCE
	{}, # EXPLOIT
	{}, # CONSERVE
	{}, # EXIT
]

## Per-counterparty strategy definitions; index =
## [enum CounterpartyStrategies] value. Add-on strategies append via
## [method register_counterparty_strategy].
static var counterparty_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # ALLY
	{}, # PARTNER
	{}, # RIVAL
	{}, # HOSTILE
	{}, # EMBARGOED
	{}, # CLIENT
]


## Appends [param data] for [param strategy_id] in
## [member global_strategy_defs]. [param strategy_id] must equal the current
## array size (contiguous append) — surfaces colliding mod registrations as
## a debug assert rather than silent last-write-wins.
static func register_global_strategy(strategy_id: int, data: Dictionary) -> void:
	assert(strategy_id == global_strategy_defs.size(),
			"Non-contiguous global strategy id %d; expected %d"
			% [strategy_id, global_strategy_defs.size()])
	global_strategy_defs.append(data)


## Appends [param data] for [param strategy_id] in
## [member resource_strategy_defs]. See [method register_global_strategy] for
## the contiguous-append contract.
static func register_resource_strategy(strategy_id: int, data: Dictionary) -> void:
	assert(strategy_id == resource_strategy_defs.size(),
			"Non-contiguous resource strategy id %d; expected %d"
			% [strategy_id, resource_strategy_defs.size()])
	resource_strategy_defs.append(data)


## Appends [param data] for [param strategy_id] in
## [member facility_strategy_defs]. See [method register_global_strategy] for
## the contiguous-append contract.
static func register_facility_strategy(strategy_id: int, data: Dictionary) -> void:
	assert(strategy_id == facility_strategy_defs.size(),
			"Non-contiguous facility strategy id %d; expected %d"
			% [strategy_id, facility_strategy_defs.size()])
	facility_strategy_defs.append(data)


## Appends [param data] for [param strategy_id] in
## [member body_strategy_defs]. See [method register_global_strategy] for
## the contiguous-append contract.
static func register_body_strategy(strategy_id: int, data: Dictionary) -> void:
	assert(strategy_id == body_strategy_defs.size(),
			"Non-contiguous body strategy id %d; expected %d"
			% [strategy_id, body_strategy_defs.size()])
	body_strategy_defs.append(data)


## Appends [param data] for [param strategy_id] in
## [member counterparty_strategy_defs]. See [method register_global_strategy]
## for the contiguous-append contract.
static func register_counterparty_strategy(strategy_id: int, data: Dictionary) -> void:
	assert(strategy_id == counterparty_strategy_defs.size(),
			"Non-contiguous counterparty strategy id %d; expected %d"
			% [strategy_id, counterparty_strategy_defs.size()])
	counterparty_strategy_defs.append(data)


# ********************************** AI API ***********************************

## Currently selected grand strategic posture id; see [enum GlobalStrategies].
## By convention 0 is the NEUTRAL (no-op default) value. Persisted via
## [member Proxy.persist] so player intent survives save/load; updated each
## quarter by [method _refresh_selections].
var global_strategy := 0

## Currently selected per-resource player-level strategy ids, indexed by
## [code]resource_type[/code] (resources-table row). Sized in [method _init]
## to the resources-table row count; entries default to 0 (NEUTRAL).
## Persisted via [member Proxy.persist].
var resource_strategies: PackedInt32Array

## Currently selected per-owned-facility player-level strategy ids, keyed by
## [member FacilityProxy.facility_id]. Lazy-populated. Persisted via
## [member Proxy.persist].[br]
## Will be re-keyed by facility type when
## [member FacilityProxy.facility_class] is implemented (see TODO on
## [member facility_strategy_defs]).
var facility_strategies: Dictionary[int, int]

## Currently selected per-body strategy ids, keyed by [member BodyProxy.body_id].
## Lazy-populated. Persisted via [member Proxy.persist].
var body_strategies: Dictionary[int, int]

## Currently selected per-counterparty strategy ids, keyed by
## [member PlayerProxy.player_id]. Lazy-populated. Persisted via
## [member Proxy.persist].
var counterparty_strategies: Dictionary[int, int]


func _init() -> void:
	super()
	persist.append(&"global_strategy")
	persist.append(&"resource_strategies")
	persist.append(&"facility_strategies")
	persist.append(&"body_strategies")
	persist.append(&"counterparty_strategies")
	var n_resources: int = _table_n_rows[&"resources"]
	resource_strategies.resize(n_resources)


## Selects this player's grand strategic posture.
func select_global_strategy() -> int:
	return 0 # NEUTRAL


## Selects the player-level resource strategy for [param resource_type].
func select_resource_strategy(_resource_type: int) -> int:
	return 0 # NEUTRAL


## Selects the player-level strategy for [param facility].
func select_facility_strategy(_facility: FacilityProxy) -> int:
	return 0 # NEUTRAL


## Selects the player-level strategy for [param body].
func select_body_strategy(_body: BodyProxy) -> int:
	return 0 # NEUTRAL


## Selects the player-level strategy toward [param other] player.
func select_counterparty_strategy(_other: PlayerProxy) -> int:
	return 0 # NEUTRAL


## Updates [member global_strategy] from [method select_global_strategy].
## Per-item refresh (resources, facilities, bodies, counterparties) is a TODO
## pending enumeration sources on the base [PlayerProxy] (which resources /
## facilities / bodies / counterparties this player cares about iterating).
func _refresh_selections() -> void:
	global_strategy = select_global_strategy()
	assert(global_strategy >= 0 and global_strategy < global_strategy_defs.size(),
			"select_global_strategy returned invalid id: %d" % global_strategy)
	# TODO: iterate per-item categories once PlayerProxy exposes the relevant
	# lists (resources of interest, owned facilities, known bodies, known
	# counterparties).


## Placeholder. Future executor will read the [code]*_strategy[/code] /
## [code]*_strategies[/code] fields and issue player-level actions
## (construction queue, diplomatic state changes, etc.) through base
## [PlayerProxy] facilities (not yet exposed).
func process_ai_interval(_delta: float) -> void:
	pass


func process_ai_new_quarter() -> void:
	_refresh_selections()
