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
## a [StringName] cached in a [code]current_*_strategy[/code] field; child
## AIs ([FacilityBaseAI], [TraderBaseAI]) read these declarations during
## their own selection. Member data lives in the static registries as inner
## [Dictionary]s (empty for now); parameter knobs and an optional
## [code]"method"[/code] key for per-strategy logic overrides may grow into
## them. Execution (construction queue, diplomatic actions, etc.) is
## centralized in [method process_ai_interval] — currently a placeholder
## pending base [PlayerProxy] facilities.
##
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [PlayerProxy]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [PlayerProxy]. See
## [PlayerCustomAI] for the extension template — the registry / select /
## refresh pattern is the same for all three [code]BaseAI[/code] classes.
##
## [b]Global strategies[/b][br]
## • NEUTRAL - Starting / no-op stance; no special posture.[br]
## • HEGEMONY - Pursue dominance across most sectors; accept high cost to maintain primacy. Analog: post-WWII U.S. grand strategy.[br]
## • BALANCING - Maintain rough parity with leading rivals; avoid overcommitment in any single arena. Analog: classical European balance-of-power.[br]
## • AUTONOMY - Maximize self-sufficiency in critical sectors; reduce dependency on rivals. Analog: China's "dual circulation," Gaullist independence.[br]
## • INTEGRATION - Pursue cooperation, joint ventures, and alliances; accept interdependence. Analog: EU integration, multilateral institutions.[br]
## • GROWTH - Maximize footprint and economic expansion; accept thinner margins.[br]
## • CONSOLIDATION - Mature posture; optimize existing portfolio; minimize new commitments. Analog: late-stage industrial economies.[br]
## • PRESTIGE - Pursue flagship visible achievements over economic optimization. Analog: Apollo program, Olympic hosting, national megaprojects.[br]
## • SCIENCE - Prioritize research, exploration, and knowledge production. Analog: NASA / ESA mission selection, basic-research agencies.[br]
## • COMMERCIAL - Treat all activity as profit-seeking; minimize non-economic missions. Analog: SpaceX / Blue Origin business model.[br]
## • STEWARDSHIP - Prioritize long-term sustainability, biome health, and biodiversity over output. Analog: green-economy / degrowth advocacy.[br]
## • EXPANSION - Pursue new bodies and frontier development at high risk. Analog: age-of-exploration powers, settler colonialism.[br]
## • SURVIVAL - Crisis posture; preserve core capabilities; accept losses elsewhere. Analog: post-Soviet Russia, post-collapse states.[br]
## • HARVEST - Late-stage extraction; maximize cash and dividends; minimize reinvestment. Analog: private-equity strip, declining empires monetizing colonies.
##
## [b]Resource strategies[/b][br]
## • NEUTRAL - No special player stance; traders apply their own per-resource strategies independently.[br]
## • DOMINATE_SUPPLY - Pursue market-share leadership in production and export; undercut rivals if needed. Analog: Saudi Arabia in oil, China in rare earths.[br]
## • DOMINATE_DEMAND - Be the buyer-of-resort; lock in supply via long-term contracts. Analog: China's commodity-securing diplomacy.[br]
## • STRATEGIC_STOCKPILE - Maintain reserves across the portfolio well beyond operational need. Analog: U.S. Strategic Petroleum Reserve, national grain reserves.[br]
## • SELF_SUFFICIENCY - Produce all internal needs domestically; avoid net imports. Analog: food-security policy, semiconductor independence.[br]
## • EXPORT_REVENUE - Treat the resource as a primary revenue source; maximize external sales. Analog: petrostates.[br]
## • DIVEST - Reduce exposure; phase out production and inventory. Analog: coal divestment, fossil-fuel phase-out commitments.[br]
## • EMBARGO - Refuse to trade with specified counterparties. Analog: U.S. semiconductor export controls.[br]
## • PRICE_SUPPORT - Buy to maintain a price floor; subsidize producers. Analog: agricultural price supports, sovereign oil-purchase programs.[br]
## • PRICE_SUPPRESS - Release reserves or overproduce to depress price. Analog: Saudi oil price wars, strategic-reserve releases.[br]
## • MONITOR - Watch closely without active intervention; reserve right to act later. Analog: contingency planning.
##
## [b]Facility strategies[/b] (will be renamed [code]facility_type_strategies[/code]
## and re-keyed by facility type once [code]FacilityProxy.facility_class[/code]
## is implemented)[br]
## • NEUTRAL - Let the facility's own AI determine its posture.[br]
## • FLAGSHIP - Showcase asset; priority resourcing and attention. Analog: corporate flagship factory, prestige research center.[br]
## • STAR - High-growth, high-margin asset; reinvest aggressively. Analog: BCG-matrix "star."[br]
## • CASH_COW - Mature profitable asset; optimize for cash extraction; minimal reinvestment. Analog: BCG-matrix "cash cow."[br]
## • QUESTION_MARK - Uncertain prospect; monitor closely; willing to cut if it doesn't perform. Analog: BCG-matrix "question mark."[br]
## • DOG - Underperformer; candidate for divestiture or closure. Analog: BCG-matrix "dog."[br]
## • STRATEGIC_OUTPOST - Maintain regardless of economics for sovereignty or presence reasons. Analog: forward military bases, polar research stations.[br]
## • SUBSIDIZED - Sustained at a loss for political reasons; receives transfers from rest of portfolio. Analog: state-owned enterprises kept alive for employment or prestige.[br]
## • DIVEST - Active wind-down; planned closure or sale. Analog: planned plant closure.
##
## [b]Body strategies[/b][br]
## • NEUTRAL - No special player stance toward this body.[br]
## • PRIORITY_DEVELOPMENT - Concentrate new facility-building and resourcing here. Analog: Project Apollo's Moon focus, Mars-first agencies.[br]
## • SECONDARY_PRESENCE - Maintain a footprint but don't grow it aggressively. Analog: minor research outposts.[br]
## • EXPLOIT - Treat the body primarily as a resource source; extract aggressively. Analog: colonial extractive economies.[br]
## • CONSERVE - Limit development for environmental or scientific reasons. Analog: protected reserves, Antarctica-treaty-style scientific zones.[br]
## • EXIT - Wind down all facilities on this body; withdraw entirely.
##
## [b]Counterparty strategies[/b][br]
## • NEUTRAL - No special stance toward this counterparty.[br]
## • ALLY - Preferred trading partner; willing to support via favorable terms or joint ventures. Analog: NATO members, EU partners.[br]
## • PARTNER - Normal commercial relationship; treat as standard counterparty.[br]
## • RIVAL - Compete actively; deny advantages where practical without open hostility. Analog: U.S.–China economic competition.[br]
## • HOSTILE - Refuse to deal; pursue measures to harm their economy. Analog: Cold War-era trade blocs.[br]
## • EMBARGOED - Comprehensive trade prohibition. Analog: U.S. sanctions on Iran, North Korea.[br]
## • CLIENT - Subordinate counterparty; provide support in exchange for political alignment. Analog: patron-client state relationships.


# **************************** STRATEGY REGISTRIES ****************************

## The player's grand strategic posture; key -> per-member data dict (empty
## placeholder for now; may grow parameter knobs or an optional
## [code]"method"[/code] key for per-strategy logic overrides). Extend via
## [method register_global_strategy].
static var global_strategies: Dictionary[StringName, Dictionary] = {
	&"NEUTRAL": {},
	&"HEGEMONY": {},
	&"BALANCING": {},
	&"AUTONOMY": {},
	&"INTEGRATION": {},
	&"GROWTH": {},
	&"CONSOLIDATION": {},
	&"PRESTIGE": {},
	&"SCIENCE": {},
	&"COMMERCIAL": {},
	&"STEWARDSHIP": {},
	&"EXPANSION": {},
	&"SURVIVAL": {},
	&"HARVEST": {},
}

## Per-resource player-level strategies; key -> per-member data dict.
## Distinct from [member TraderBaseAI.resource_strategies]: this is how the
## player wants the global market for the resource to look. Extend via
## [method register_resource_strategy].
static var resource_strategies: Dictionary[StringName, Dictionary] = {
	&"NEUTRAL": {},
	&"DOMINATE_SUPPLY": {},
	&"DOMINATE_DEMAND": {},
	&"STRATEGIC_STOCKPILE": {},
	&"SELF_SUFFICIENCY": {},
	&"EXPORT_REVENUE": {},
	&"DIVEST": {},
	&"EMBARGO": {},
	&"PRICE_SUPPORT": {},
	&"PRICE_SUPPRESS": {},
	&"MONITOR": {},
}

## Per-owned-facility player-level strategies; key -> per-member data dict.
## Distinct from [member FacilityBaseAI.facility_strategies]: this is how the
## player views the role of each owned facility in the portfolio. Extend via
## [method register_facility_strategy].[br]
## TODO: rename to [code]facility_type_strategies[/code] and re-key by
## facility type when [member FacilityProxy.facility_class] is implemented.
## Selection then moves from per-instance to per-type.
static var facility_strategies: Dictionary[StringName, Dictionary] = {
	&"NEUTRAL": {},
	&"FLAGSHIP": {},
	&"STAR": {},
	&"CASH_COW": {},
	&"QUESTION_MARK": {},
	&"DOG": {},
	&"STRATEGIC_OUTPOST": {},
	&"SUBSIDIZED": {},
	&"DIVEST": {},
}

## Per-body player-level strategies; key -> per-member data dict. Extend via
## [method register_body_strategy].
static var body_strategies: Dictionary[StringName, Dictionary] = {
	&"NEUTRAL": {},
	&"PRIORITY_DEVELOPMENT": {},
	&"SECONDARY_PRESENCE": {},
	&"EXPLOIT": {},
	&"CONSERVE": {},
	&"EXIT": {},
}

## Per-other-player strategies (diplomatic / trade posture); key ->
## per-member data dict. Extend via [method register_counterparty_strategy].
static var counterparty_strategies: Dictionary[StringName, Dictionary] = {
	&"NEUTRAL": {},
	&"ALLY": {},
	&"PARTNER": {},
	&"RIVAL": {},
	&"HOSTILE": {},
	&"EMBARGOED": {},
	&"CLIENT": {},
}


## Registers [param strategy] in [member global_strategies]. Asserts on
## duplicate to surface accidental collisions between mod registrations.
static func register_global_strategy(strategy: StringName, data: Dictionary) -> void:
	assert(!global_strategies.has(strategy), "Global strategy already registered: %s" % strategy)
	global_strategies[strategy] = data


## Registers [param strategy] in [member resource_strategies]. Asserts on
## duplicate.
static func register_resource_strategy(strategy: StringName, data: Dictionary) -> void:
	assert(!resource_strategies.has(strategy), "Resource strategy already registered: %s" % strategy)
	resource_strategies[strategy] = data


## Registers [param strategy] in [member facility_strategies]. Asserts on
## duplicate.
static func register_facility_strategy(strategy: StringName, data: Dictionary) -> void:
	assert(!facility_strategies.has(strategy), "Facility strategy already registered: %s" % strategy)
	facility_strategies[strategy] = data


## Registers [param strategy] in [member body_strategies]. Asserts on duplicate.
static func register_body_strategy(strategy: StringName, data: Dictionary) -> void:
	assert(!body_strategies.has(strategy), "Body strategy already registered: %s" % strategy)
	body_strategies[strategy] = data


## Registers [param strategy] in [member counterparty_strategies]. Asserts on
## duplicate.
static func register_counterparty_strategy(strategy: StringName, data: Dictionary) -> void:
	assert(!counterparty_strategies.has(strategy), "Counterparty strategy already registered: %s" % strategy)
	counterparty_strategies[strategy] = data


# ********************************** AI API ***********************************

## Currently selected grand strategic posture. Updated by
## [method _refresh_selections] on each quarter tick. Not persisted across
## save/load; re-derived on next quarter tick.
## (If GUI/server ever needs to mirror this, use [code]Proxy.DirtyFlags[/code]
## per the established pattern.)
var current_global_strategy: StringName = &"NEUTRAL"

## Currently selected per-resource strategies, keyed by resource_type (int).
## Lazy-populated. Not persisted.
var current_resource_strategies: Dictionary = {}

## Currently selected per-owned-facility strategies, keyed by [FacilityProxy]
## instance for now. Will be re-keyed by facility type when
## [member FacilityProxy.facility_class] is implemented (see TODO on
## [member facility_strategies]).
var current_facility_strategies: Dictionary = {}

## Currently selected per-body strategies, keyed by [BodyProxy] instance.
## Lazy-populated. Not persisted.
var current_body_strategies: Dictionary = {}

## Currently selected per-counterparty strategies, keyed by [PlayerProxy]
## instance. Lazy-populated. Not persisted.
var current_counterparty_strategies: Dictionary = {}


## Selects this player's grand strategic posture.
func select_global_strategy() -> StringName:
	return &"NEUTRAL"


## Selects the player-level resource strategy for [param resource_type].
func select_resource_strategy(_resource_type: int) -> StringName:
	return &"NEUTRAL"


## Selects the player-level strategy for [param facility].
func select_facility_strategy(_facility: FacilityProxy) -> StringName:
	return &"NEUTRAL"


## Selects the player-level strategy for [param body].
func select_body_strategy(_body: BodyProxy) -> StringName:
	return &"NEUTRAL"


## Selects the player-level strategy toward [param other] player.
func select_counterparty_strategy(_other: PlayerProxy) -> StringName:
	return &"NEUTRAL"


## Updates [member current_global_strategy] from [method select_global_strategy].
## Per-item refresh (resources, facilities, bodies, counterparties) is a TODO
## pending enumeration sources on the base [PlayerProxy] (which resources /
## facilities / bodies / counterparties this player cares about iterating).
func _refresh_selections() -> void:
	current_global_strategy = select_global_strategy()
	assert(global_strategies.has(current_global_strategy),
			"select_global_strategy returned unregistered key: %s" % current_global_strategy)
	# TODO: iterate per-item categories once PlayerProxy exposes the relevant
	# lists (resources of interest, owned facilities, known bodies, known
	# counterparties).


## Placeholder. Future executor will read the [code]current_*[/code] fields
## and issue player-level actions (construction queue, diplomatic state
## changes, etc.) through base [PlayerProxy] facilities (not yet exposed).
func process_ai_interval(_delta: float) -> void:
	pass


func process_ai_new_quarter() -> void:
	_refresh_selections()
