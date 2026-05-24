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
## [code]Dictionary[StringName, StringName][/code]s mapping a strategy key
## to the stub-method name that implements it — see e.g.
## [member PlayerBaseAI.global_strategies],
## [member PlayerBaseAI.resource_strategies],
## [member TraderBaseAI.trader_strategies]. The default
## [code]implement_*_strategy(...)[/code] looks the key up and
## [method Object.call]s the method. Strategy keys are [StringName] literals
## ([code]&"NEUTRAL"[/code], [code]&"HEGEMONY"[/code], …); the description
## of each strategy lives as a [code]##[/code] doc on its stub method.
##
## [b]Three forms of extension[/b][br]
## [b]Modify an existing strategy's behavior[/b] — override its stub method
## directly (e.g. [code]_resource_neutral[/code]). No registry change
## needed; [method Object.call] dispatches polymorphically.[br]
## [b]Take over selection[/b] — override the relevant
## [code]select_*_strategy(...)[/code] and return whichever [StringName] you
## want.[br]
## [b]Add a new strategy[/b] — register it in [code]_static_init[/code] via
## [code]register_<category>_strategy(key, method_name)[/code], then declare
## the stub method. The default dispatcher picks it up automatically.
##
## [b]Worked example[/b][br]
## [codeblock]
## class_name MyPlayerAI
## extends PlayerBaseAI
##
## const OVERRIDE_AI := true
##
## static func _static_init() -> void:
##     register_resource_strategy(&"TABOO", &"_resource_taboo")
##
## func select_resource_strategy(resource_type: int) -> StringName:
##     if _is_sacred(resource_type):
##         return &"TABOO"
##     return super(resource_type)
##
## ## Treat this resource as ceremonial; neither produce nor trade it.
## func _resource_taboo(_resource_type: int, _delta: float) -> void:
##     pass
## [/codeblock]
##
## [b]Caveats[/b][br]
## - Static registries are class-level: if multiple [code]CustomAI[/code]
## subclasses are loaded in a build (e.g. competing mods), all of their
## registrations land in the shared dict. Only the [code]OVERRIDE_AI[/code]
## class is actually dispatched, so leftover entries are inert — but they
## are visible to anyone iterating the registry.[br]
## - [code]select_*[/code] returns raw [StringName]s, so typos won't be
## caught at parse time. Assert against the registry at the call site if you
## want a safety net.[br]
## - The registry holds method names only — any UI display names or
## per-strategy metadata want a parallel map.


## Marker constant: setting to [code]true[/code] elevates this class to the
## active player AI in place of [PlayerBaseAI].
const OVERRIDE_AI := true
