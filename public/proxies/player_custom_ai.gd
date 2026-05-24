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
## Each [code]BaseAI[/code] has one or more static
## [code]Dictionary[StringName, Dictionary][/code] registries mapping a
## strategy key to a per-member data dict — see e.g.
## [member PlayerBaseAI.global_strategies],
## [member PlayerBaseAI.resource_strategies],
## [member TraderBaseAI.trader_strategies]. Inner dicts are empty
## [code]{}[/code] today; they may grow parameter knobs (read by the
## central executor) and, as a future extension, an optional
## [code]"method"[/code] key naming a method to call for per-strategy logic
## divergence. The current selection per category is stored in a
## [code]current_*_strategy[/code] field on the AI; descriptions for each
## strategy member live in the [code]##[/code] block at the top of the
## corresponding [code]BaseAI[/code] class file.
##
## [b]Three forms of extension[/b][br]
## [b]Adjust an existing strategy's data[/b] — extend its inner dict in
## [code]_static_init[/code] (e.g. add a parameter knob the executor reads).
## No selection change needed; whoever picks that key gets the new
## payload.[br]
## [b]Take over selection[/b] — override the relevant
## [code]select_*_strategy(...)[/code] and return whichever [StringName] you
## want. The base [code]_refresh_selections[/code] asserts the returned key
## is registered, so typos surface in debug builds.[br]
## [b]Add a new strategy[/b] — register it in [code]_static_init[/code] via
## [code]register_<category>_strategy(key, data)[/code] where [code]data[/code]
## is the inner dict (empty, parameter knobs, and/or — in the future — a
## [code]"method"[/code] key). Then make [code]select_*_strategy[/code]
## return the new key when appropriate.
##
## [b]Worked example[/b][br]
## [codeblock]
## class_name MyPlayerAI
## extends PlayerBaseAI
##
## const OVERRIDE_AI := true
##
## static func _static_init() -> void:
##     register_resource_strategy(&"TABOO", {})
##
## func select_resource_strategy(resource_type: int) -> StringName:
##     if _is_sacred(resource_type):
##         return &"TABOO"
##     return super(resource_type)
## [/codeblock]
## When parameter knobs land, the registration line becomes e.g.
## [code]register_resource_strategy(&"TABOO", {"trade_blocked": true})[/code]
## and the executor reads [code]"trade_blocked"[/code] from the selected
## strategy's data dict. For genuine logic divergence (later), the inner
## dict may include [code]"method": &"_my_taboo_handler"[/code] and the
## executor dispatches to it.
##
## [b]Caveats[/b][br]
## - Static registries are class-level: if multiple [code]CustomAI[/code]
## subclasses are loaded in a build (e.g. competing mods), their
## [code]_static_init[/code] registrations all land in the shared dict.
## [code]register_*_strategy[/code] asserts on duplicate keys, so colliding
## registrations fail loudly in debug builds rather than silent
## last-write-wins. Only the [code]OVERRIDE_AI[/code] class is actually
## dispatched, so a leftover assert-passing entry from a sibling mod is
## inert but visible to anyone iterating the registry.[br]
## - [code]select_*_strategy[/code] returns raw [StringName]s; the base
## [code]_refresh_selections[/code] asserts the returned key is registered.
## Typos surface in debug builds (no silent miss).[br]
## - The registry holds per-strategy data dicts. Expected dict-key
## conventions for parameter knobs evolve with the executor; current inner
## dicts are empty placeholders.


## Marker constant: setting to [code]true[/code] elevates this class to the
## active player AI in place of [PlayerBaseAI].
const OVERRIDE_AI := true
