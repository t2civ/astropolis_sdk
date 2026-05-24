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
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [PlayerProxy]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [PlayerProxy]. See
## [PlayerCustomAI] for the extension template — the registry / select /
## implement pattern is the same for all three [code]BaseAI[/code] classes.


# **************************** STRATEGY REGISTRIES ****************************

## The player's grand strategic posture; key -> stub-method name on this
## class. Extend via [method register_global_strategy].
static var global_strategies: Dictionary[StringName, StringName] = {
	&"HEGEMONY": &"_global_hegemony",
	&"BALANCING": &"_global_balancing",
	&"AUTONOMY": &"_global_autonomy",
	&"INTEGRATION": &"_global_integration",
	&"GROWTH": &"_global_growth",
	&"CONSOLIDATION": &"_global_consolidation",
	&"PRESTIGE": &"_global_prestige",
	&"SCIENCE": &"_global_science",
	&"COMMERCIAL": &"_global_commercial",
	&"STEWARDSHIP": &"_global_stewardship",
	&"EXPANSION": &"_global_expansion",
	&"SURVIVAL": &"_global_survival",
	&"HARVEST": &"_global_harvest",
}

## Per-resource player-level strategies; key -> stub-method name on this
## class. Distinct from [member TraderBaseAI.resource_strategies]: this is
## how the player wants the global market for the resource to look. Extend
## via [method register_resource_strategy].
static var resource_strategies: Dictionary[StringName, StringName] = {
	&"NEUTRAL": &"_resource_neutral",
	&"DOMINATE_SUPPLY": &"_resource_dominate_supply",
	&"DOMINATE_DEMAND": &"_resource_dominate_demand",
	&"STRATEGIC_STOCKPILE": &"_resource_strategic_stockpile",
	&"SELF_SUFFICIENCY": &"_resource_self_sufficiency",
	&"EXPORT_REVENUE": &"_resource_export_revenue",
	&"DIVEST": &"_resource_divest",
	&"EMBARGO": &"_resource_embargo",
	&"PRICE_SUPPORT": &"_resource_price_support",
	&"PRICE_SUPPRESS": &"_resource_price_suppress",
	&"MONITOR": &"_resource_monitor",
}

## Per-owned-facility player-level strategies; key -> stub-method name on
## this class. Distinct from [member FacilityBaseAI.facility_strategies]:
## this is how the player views the role of each owned facility in the
## portfolio. Extend via [method register_facility_strategy].
static var facility_strategies: Dictionary[StringName, StringName] = {
	&"NEUTRAL": &"_facility_neutral",
	&"FLAGSHIP": &"_facility_flagship",
	&"STAR": &"_facility_star",
	&"CASH_COW": &"_facility_cash_cow",
	&"QUESTION_MARK": &"_facility_question_mark",
	&"DOG": &"_facility_dog",
	&"STRATEGIC_OUTPOST": &"_facility_strategic_outpost",
	&"SUBSIDIZED": &"_facility_subsidized",
	&"DIVEST": &"_facility_divest",
}

## Per-body player-level strategies; key -> stub-method name on this class.
## Extend via [method register_body_strategy].
static var body_strategies: Dictionary[StringName, StringName] = {
	&"NEUTRAL": &"_body_neutral",
	&"PRIORITY_DEVELOPMENT": &"_body_priority_development",
	&"SECONDARY_PRESENCE": &"_body_secondary_presence",
	&"EXPLOIT": &"_body_exploit",
	&"CONSERVE": &"_body_conserve",
	&"EXIT": &"_body_exit",
}

## Per-other-player strategies (diplomatic / trade posture); key -> stub-
## method name on this class. Extend via [method register_counterparty_strategy].
static var counterparty_strategies: Dictionary[StringName, StringName] = {
	&"NEUTRAL": &"_counterparty_neutral",
	&"ALLY": &"_counterparty_ally",
	&"PARTNER": &"_counterparty_partner",
	&"RIVAL": &"_counterparty_rival",
	&"HOSTILE": &"_counterparty_hostile",
	&"EMBARGOED": &"_counterparty_embargoed",
	&"CLIENT": &"_counterparty_client",
}


## Adds or rewires [param strategy] in [member global_strategies]. Idempotent.
static func register_global_strategy(strategy: StringName, method_name: StringName) -> void:
	global_strategies[strategy] = method_name


## Adds or rewires [param strategy] in [member resource_strategies]. Idempotent.
static func register_resource_strategy(strategy: StringName, method_name: StringName) -> void:
	resource_strategies[strategy] = method_name


## Adds or rewires [param strategy] in [member facility_strategies]. Idempotent.
static func register_facility_strategy(strategy: StringName, method_name: StringName) -> void:
	facility_strategies[strategy] = method_name


## Adds or rewires [param strategy] in [member body_strategies]. Idempotent.
static func register_body_strategy(strategy: StringName, method_name: StringName) -> void:
	body_strategies[strategy] = method_name


## Adds or rewires [param strategy] in [member counterparty_strategies].
## Idempotent.
static func register_counterparty_strategy(strategy: StringName, method_name: StringName) -> void:
	counterparty_strategies[strategy] = method_name


# ********************************** AI API ***********************************

## Selects this player's grand strategic posture.
func select_global_strategy() -> StringName:
	return &"CONSOLIDATION"


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


## Dispatches [param strategy] for the current interval. Override to change
## dispatch; override the stub method itself to change a strategy's behavior.
func implement_global_strategy(strategy: StringName, delta: float) -> void:
	var method: StringName = global_strategies[strategy]
	call(method, delta)


## Dispatches [param strategy] for [param resource_type]. Override to change
## dispatch; override the stub method itself to change a strategy's behavior.
func implement_resource_strategy(resource_type: int, strategy: StringName, delta: float) -> void:
	var method: StringName = resource_strategies[strategy]
	call(method, resource_type, delta)


## Dispatches [param strategy] for [param facility]. Override to change
## dispatch; override the stub method itself to change a strategy's behavior.
func implement_facility_strategy(facility: FacilityProxy, strategy: StringName, delta: float) -> void:
	var method: StringName = facility_strategies[strategy]
	call(method, facility, delta)


## Dispatches [param strategy] for [param body]. Override to change
## dispatch; override the stub method itself to change a strategy's behavior.
func implement_body_strategy(body: BodyProxy, strategy: StringName, delta: float) -> void:
	var method: StringName = body_strategies[strategy]
	call(method, body, delta)


## Dispatches [param strategy] toward [param other] player. Override to
## change dispatch; override the stub method itself to change a strategy's
## behavior.
func implement_counterparty_strategy(other: PlayerProxy, strategy: StringName, delta: float) -> void:
	var method: StringName = counterparty_strategies[strategy]
	call(method, other, delta)


func process_ai_interval(_delta: float) -> void:
	pass


func process_ai_new_quarter() -> void:
	pass


# *************************** GLOBAL-STRATEGY STUBS ***************************

## Pursue dominance across most sectors; accept high cost to maintain
## primacy. Analog: post-WWII U.S. grand strategy.
func _global_hegemony(_delta: float) -> void:
	pass


## Maintain rough parity with leading rivals; avoid overcommitment in any
## single arena. Analog: classical European balance-of-power.
func _global_balancing(_delta: float) -> void:
	pass


## Maximize self-sufficiency in critical sectors; reduce dependency on
## rivals. Analog: China's "dual circulation," Gaullist independence.
func _global_autonomy(_delta: float) -> void:
	pass


## Pursue cooperation, joint ventures, and alliances; accept
## interdependence. Analog: EU integration, multilateral institutions.
func _global_integration(_delta: float) -> void:
	pass


## Maximize footprint and economic expansion; accept thinner margins.
func _global_growth(_delta: float) -> void:
	pass


## Mature posture; optimize existing portfolio; minimize new commitments.
## Analog: late-stage industrial economies.
func _global_consolidation(_delta: float) -> void:
	pass


## Pursue flagship visible achievements over economic optimization. Analog:
## Apollo program, Olympic hosting, national megaprojects.
func _global_prestige(_delta: float) -> void:
	pass


## Prioritize research, exploration, and knowledge production. Analog: NASA
## / ESA mission selection, basic-research agencies.
func _global_science(_delta: float) -> void:
	pass


## Treat all activity as profit-seeking; minimize non-economic missions.
## Analog: SpaceX / Blue Origin business model.
func _global_commercial(_delta: float) -> void:
	pass


## Prioritize long-term sustainability, biome health, and biodiversity over
## output. Analog: green-economy / degrowth advocacy.
func _global_stewardship(_delta: float) -> void:
	pass


## Pursue new bodies and frontier development at high risk. Analog: age-of-
## exploration powers, settler colonialism.
func _global_expansion(_delta: float) -> void:
	pass


## Crisis posture; preserve core capabilities; accept losses elsewhere.
## Analog: post-Soviet Russia, post-collapse states.
func _global_survival(_delta: float) -> void:
	pass


## Late-stage extraction; maximize cash and dividends; minimize
## reinvestment. Analog: private-equity strip, declining empires monetizing
## colonies.
func _global_harvest(_delta: float) -> void:
	pass


# ************************** RESOURCE-STRATEGY STUBS **************************

## No special player stance; traders apply their own per-resource strategies
## independently.
func _resource_neutral(_resource_type: int, _delta: float) -> void:
	pass


## Pursue market-share leadership in production and export; undercut rivals
## if needed. Analog: Saudi Arabia in oil, China in rare earths.
func _resource_dominate_supply(_resource_type: int, _delta: float) -> void:
	pass


## Be the buyer-of-resort; lock in supply via long-term contracts. Analog:
## China's commodity-securing diplomacy.
func _resource_dominate_demand(_resource_type: int, _delta: float) -> void:
	pass


## Maintain reserves across the portfolio well beyond operational need.
## Analog: U.S. Strategic Petroleum Reserve, national grain reserves.
func _resource_strategic_stockpile(_resource_type: int, _delta: float) -> void:
	pass


## Produce all internal needs domestically; avoid net imports. Analog: food-
## security policy, semiconductor independence.
func _resource_self_sufficiency(_resource_type: int, _delta: float) -> void:
	pass


## Treat the resource as a primary revenue source; maximize external sales.
## Analog: petrostates.
func _resource_export_revenue(_resource_type: int, _delta: float) -> void:
	pass


## Reduce exposure; phase out production and inventory. Analog: coal
## divestment, fossil-fuel phase-out commitments.
func _resource_divest(_resource_type: int, _delta: float) -> void:
	pass


## Refuse to trade with specified counterparties. Analog: U.S. semiconductor
## export controls.
func _resource_embargo(_resource_type: int, _delta: float) -> void:
	pass


## Buy to maintain a price floor; subsidize producers. Analog: agricultural
## price supports, sovereign oil-purchase programs.
func _resource_price_support(_resource_type: int, _delta: float) -> void:
	pass


## Release reserves or overproduce to depress price. Analog: Saudi oil price
## wars, strategic-reserve releases.
func _resource_price_suppress(_resource_type: int, _delta: float) -> void:
	pass


## Watch closely without active intervention; reserve right to act later.
## Analog: contingency planning.
func _resource_monitor(_resource_type: int, _delta: float) -> void:
	pass


# ************************** FACILITY-STRATEGY STUBS **************************

## Let the facility's own AI determine its posture.
func _facility_neutral(_facility: FacilityProxy, _delta: float) -> void:
	pass


## Showcase asset; priority resourcing and attention. Analog: corporate
## flagship factory, prestige research center.
func _facility_flagship(_facility: FacilityProxy, _delta: float) -> void:
	pass


## High-growth, high-margin asset; reinvest aggressively. Analog: BCG-matrix
## "star."
func _facility_star(_facility: FacilityProxy, _delta: float) -> void:
	pass


## Mature profitable asset; optimize for cash extraction; minimal
## reinvestment. Analog: BCG-matrix "cash cow."
func _facility_cash_cow(_facility: FacilityProxy, _delta: float) -> void:
	pass


## Uncertain prospect; monitor closely; willing to cut if it doesn't
## perform. Analog: BCG-matrix "question mark."
func _facility_question_mark(_facility: FacilityProxy, _delta: float) -> void:
	pass


## Underperformer; candidate for divestiture or closure. Analog: BCG-matrix
## "dog."
func _facility_dog(_facility: FacilityProxy, _delta: float) -> void:
	pass


## Maintain regardless of economics for sovereignty or presence reasons.
## Analog: forward military bases, polar research stations.
func _facility_strategic_outpost(_facility: FacilityProxy, _delta: float) -> void:
	pass


## Sustained at a loss for political reasons; receives transfers from rest
## of portfolio. Analog: state-owned enterprises kept alive for employment
## or prestige.
func _facility_subsidized(_facility: FacilityProxy, _delta: float) -> void:
	pass


## Active wind-down; planned closure or sale. Analog: planned plant closure.
func _facility_divest(_facility: FacilityProxy, _delta: float) -> void:
	pass


# **************************** BODY-STRATEGY STUBS ****************************

## No special player stance toward this body.
func _body_neutral(_body: BodyProxy, _delta: float) -> void:
	pass


## Concentrate new facility-building and resourcing here. Analog: Project
## Apollo's Moon focus, Mars-first agencies.
func _body_priority_development(_body: BodyProxy, _delta: float) -> void:
	pass


## Maintain a footprint but don't grow it aggressively. Analog: minor
## research outposts.
func _body_secondary_presence(_body: BodyProxy, _delta: float) -> void:
	pass


## Treat the body primarily as a resource source; extract aggressively.
## Analog: colonial extractive economies.
func _body_exploit(_body: BodyProxy, _delta: float) -> void:
	pass


## Limit development for environmental or scientific reasons. Analog:
## protected reserves, Antarctica-treaty-style scientific zones.
func _body_conserve(_body: BodyProxy, _delta: float) -> void:
	pass


## Wind down all facilities on this body; withdraw entirely.
func _body_exit(_body: BodyProxy, _delta: float) -> void:
	pass


# ************************ COUNTERPARTY-STRATEGY STUBS ************************

## No special stance toward this counterparty.
func _counterparty_neutral(_other: PlayerProxy, _delta: float) -> void:
	pass


## Preferred trading partner; willing to support via favorable terms or
## joint ventures. Analog: NATO members, EU partners.
func _counterparty_ally(_other: PlayerProxy, _delta: float) -> void:
	pass


## Normal commercial relationship; treat as standard counterparty.
func _counterparty_partner(_other: PlayerProxy, _delta: float) -> void:
	pass


## Compete actively; deny advantages where practical without open
## hostility. Analog: U.S.–China economic competition.
func _counterparty_rival(_other: PlayerProxy, _delta: float) -> void:
	pass


## Refuse to deal; pursue measures to harm their economy. Analog: Cold War-
## era trade blocs.
func _counterparty_hostile(_other: PlayerProxy, _delta: float) -> void:
	pass


## Comprehensive trade prohibition. Analog: U.S. sanctions on Iran, North
## Korea.
func _counterparty_embargoed(_other: PlayerProxy, _delta: float) -> void:
	pass


## Subordinate counterparty; provide support in exchange for political
## alignment. Analog: patron-client state relationships.
func _counterparty_client(_other: PlayerProxy, _delta: float) -> void:
	pass
