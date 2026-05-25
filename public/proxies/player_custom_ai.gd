# player_custom_ai.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name PlayerCustomAI
extends PlayerProxy

## Example custom player AI and template for writing your own. The pattern
## documented here applies to all three [code]BaseAI[/code] classes
## ([TraderBaseAI], [FacilityBaseAI], [PlayerBaseAI]).
##
## [b]What [code]OVERRIDE_AI := true[/code] does[/b][br]
## [code]ProxySelector[/code] picks this class over the corresponding
## [code]BaseAI[/code] when instantiating proxies for the local player.
## Non-owner peers still use the bare proxy. Extend [PlayerBaseAI] (or
## [PlayerProxy] for a from-scratch AI); same applies to trader and
## facility.
##
## [b]Strategy registry pattern[/b][br]
## Each [code]BaseAI[/code] declares one or more strategy [code]enum[/code]s
## (e.g. [enum PlayerBaseAI.GlobalStrategies]) terminated by an
## [code]N_BASE_*[/code] member that records the count of base strategies.
## A parallel static [code]Array[Dictionary][/code] registry
## (e.g. [member PlayerBaseAI.global_strategy_defs]) holds per-strategy data
## indexed by the enum value — the strategy [b]id[/b]. Inner dicts are empty
## [code]{}[/code] today; they may grow parameter knobs (read by the central
## executor) and, as a future extension, an optional [code]"method"[/code] key
## naming a method to call for per-strategy logic divergence. The current
## selection per category is stored in a [code]<name>_strategy[/code] field
## (int) or a per-item [code]<name>_strategies[/code] container (PackedInt32Array
## indexed by [code]resource_type[/code], or [code]Dictionary[int, int][/code]
## keyed by a proxy's domain id). Cached selections are persisted via
## [member Proxy.persist] so player intent survives save/load. Descriptions
## for each strategy member live in the [code]##[/code] doc comment above the
## enum member in the corresponding [code]BaseAI[/code] file.
##
## [b]Three forms of extension[/b][br]
## [b]Adjust an existing strategy's data[/b] — extend its inner dict in
## [code]_static_init[/code] (e.g. add a parameter knob the executor reads).
## No selection change needed; whoever picks that id gets the new payload.[br]
## [b]Take over selection[/b] — override the relevant
## [code]select_*_strategy(...)[/code] and return whichever [int] id you
## want. The base [code]_refresh_selections[/code] asserts the returned id is
## within the registry's bounds, so out-of-range surfaces in debug builds.[br]
## [b]Add a new strategy[/b] — declare an add-on enum anchored at
## [code]N_BASE_<category>_STRATEGIES[/code] so your ids extend the base
## sequence contiguously, then register each member in
## [code]_static_init[/code] via
## [code]register_<category>_strategy(strategy_id, data)[/code] where
## [code]data[/code] is the inner dict (empty, parameter knobs, and/or — in
## the future — a [code]"method"[/code] key). Then make
## [code]select_*_strategy[/code] return the new id when appropriate.
##
## [b]Worked example[/b][br]
## [codeblock]
## class_name MyPlayerAI
## extends PlayerBaseAI
##
## const OVERRIDE_AI := true
##
## # Add-on global-strategy ids. The first member anchors at the base count
## # so registration stays contiguous with [member PlayerBaseAI.global_strategy_defs].
## enum GlobalStrategies2 {
##     TABOO = PlayerBaseAI.GlobalStrategies.N_BASE_GLOBAL_STRATEGIES,
##     SACRED,
## }
##
## static func _static_init() -> void:
##     register_global_strategy(GlobalStrategies2.TABOO, {})
##     register_global_strategy(GlobalStrategies2.SACRED, {})
##
## func select_global_strategy() -> int:
##     if _is_sacred():
##         return GlobalStrategies2.SACRED
##     return super()
## [/codeblock]
## When parameter knobs land, the registration line becomes e.g.
## [code]register_global_strategy(GlobalStrategies2.TABOO, {"trade_blocked": true})[/code]
## and the executor reads [code]"trade_blocked"[/code] from the selected
## strategy's data dict. For genuine logic divergence (later), the inner
## dict may include [code]"method": &"_my_taboo_handler"[/code] and the
## executor dispatches to it.
##
## [b]Caveats[/b][br]
## - Static registries are class-level: if multiple [code]CustomAI[/code]
## subclasses are loaded in a build (e.g. competing mods), their
## [code]_static_init[/code] registrations all land in the shared array.
## [code]register_*_strategy[/code] asserts on non-contiguous ids, so
## colliding add-on enums (e.g. two mods anchoring at the same
## [code]N_BASE_*[/code] value) fail loudly in debug builds rather than
## silent last-write-wins. Only the [code]OVERRIDE_AI[/code] class is
## actually dispatched, so a leftover assert-passing entry from a sibling
## mod is inert but visible to anyone iterating the registry.[br]
## - [code]select_*_strategy[/code] returns raw [int] ids; the base
## [code]_refresh_selections[/code] asserts the returned id is within the
## registry's bounds. Out-of-range surfaces in debug builds (no silent
## miss).[br]
## - Strategy ids are persisted (via [member Proxy.persist]), so renumbering
## an already-shipped enum breaks loaded saves. Append new members; do not
## reorder.[br]
## - The registry holds per-strategy data dicts. Expected dict-key
## conventions for parameter knobs evolve with the executor; current inner
## dicts are empty placeholders.


## Marker constant: setting to [code]true[/code] elevates this class to the
## active player AI in place of [PlayerBaseAI].
const OVERRIDE_AI := true
