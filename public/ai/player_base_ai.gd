# player_base_ai.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name PlayerBaseAI
extends BaseAI

## Default AI for the local player. Subclass to write custom player AI by
## extending this class and adding [code]const OVERRIDE_AI := true[/code];
## see [PlayerCustomAI].
##
## Strategies are declarative. Each [code]select_*_strategy()[/code] returns
## an [int] enum id (see [enum GlobalStrategies], [enum PlayerResourceStrategies],
## etc.) cached in a [code]<name>_strategy[/code] field or per-item container;
## child AIs ([FacilityBaseAI], [TraderBaseAI]) read these declarations
## during their own selection. Cached selections persist via
## [member BaseAI.persist] and are re-derived on each quarter tick.


## Emitted when [member global_strategy] changes.
signal global_strategy_changed(strategy_id: int)
## Emitted when an entry in [member player_resource_strategies] changes.
signal player_resource_strategy_changed(resource_type: int, strategy_id: int)
## Emitted when an entry in [member player_facility_strategies] changes.
signal player_facility_strategy_changed(facility_id: int, strategy_id: int)
## Emitted when an entry in [member body_strategies] changes.
signal body_strategy_changed(body_id: int, strategy_id: int)
## Emitted when an entry in [member counterparty_strategies] changes.
signal counterparty_strategy_changed(player_id: int, strategy_id: int)


## The player's grand strategic posture.
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

## Per-resource player-level strategies — this is how the player wants the
## global market for the resource to look.
enum PlayerResourceStrategies {
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
	N_BASE_PLAYER_RESOURCE_STRATEGIES,
}

## Per-owned-facility player-level strategies — this is how the player views
## the role of each owned facility in the portfolio).
enum PlayerFacilityStrategies {
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
	N_BASE_PLAYER_FACILITY_STRATEGIES,
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


## Grand-strategy definitions; index = [enum GlobalStrategies] value.
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
## [enum PlayerResourceStrategies] value.
static var player_resource_strategy_defs: Array[Dictionary] = [
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
## [enum PlayerFacilityStrategies] value.
static var player_facility_strategy_defs: Array[Dictionary] = [
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
## value.
static var body_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # PRIORITY_DEVELOPMENT
	{}, # SECONDARY_PRESENCE
	{}, # EXPLOIT
	{}, # CONSERVE
	{}, # EXIT
]

## Per-counterparty strategy definitions; index =
## [enum CounterpartyStrategies] value.
static var counterparty_strategy_defs: Array[Dictionary] = [
	{}, # NEUTRAL
	{}, # ALLY
	{}, # PARTNER
	{}, # RIVAL
	{}, # HOSTILE
	{}, # EMBARGOED
	{}, # CLIENT
]


static var _table_n_rows := IVTableData.table_n_rows


var proxy: PlayerProxy


# *****************************************************************************
# persisted

## Grand strategic posture. See [enum GlobalStrategies].
var global_strategy := 0
## Per-resource strategies. See [enum PlayerResourceStrategies].
var player_resource_strategies: PackedInt32Array
## Per-facility strategies keyed by [member FacilityProxy.facility_id]. Absent
## is the same as "NEUTRAL". See [enum PlayerFacilityStrategies].
var player_facility_strategies: Dictionary[int, int]
## Per-body strategies keyed by [member BodyProxy.body_id]. Absent is the same
## as "NEUTRAL". See [enum BodyStrategies].
var body_strategies: Dictionary[int, int]
## Per-counterparty strategies keyed by [member PlayerProxy.player_id]. Absent
## is the same as "NEUTRAL". See [enum CounterpartyStrategies].
var counterparty_strategies: Dictionary[int, int]

# *****************************************************************************


# ************************* VIRTUAL & IMPLEMENTATION **************************

func _init() -> void:
	persist.append(&"global_strategy")
	persist.append(&"player_resource_strategies")
	persist.append(&"player_facility_strategies")
	persist.append(&"body_strategies")
	persist.append(&"counterparty_strategies")
	var n_resources: int = _table_n_rows[&"resources"]
	player_resource_strategies.resize(n_resources)


func _clear_for_destruction() -> void:
	proxy = null


func bind_proxy(proxy_: Proxy) -> void:
	proxy = proxy_ as PlayerProxy


func process_ai_init() -> void:
	pass


func process_ai_interval(_delta: float) -> void:
	pass
