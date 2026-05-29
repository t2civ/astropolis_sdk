# player_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
@abstract
class_name PlayerProxy
extends Proxy

## [PlayerProxy] represents a polity, faction, or sub-entity that owns
## [FacilityProxy]s.
##
## Server-side Player aggregates component data from facilities and pushes
## changes to PlayerProxy. Players are never removed during a game; an "alive"
## player is one with [member is_facilities] true.
##
## To modify AI, see [BaseAI] and the [code]*_base_ai.gd[/code] files.
##
## WARNING: Lives on the proxy thread. Containers and many methods are not
## threadsafe; accessing non-container properties is safe.


# public read-only
var player_id := -1 ## Index into [member ProxyBus.player_proxies].
var player_class := -1 ## Player class index ([code]PlayerClasses[/code] enum).
var polity: PlayerProxy ## Self if [member player_class] == [code]PLAYER_CLASS_POLITY[/code].
var homeworld := "" ## Name of this player's homeworld body.
var is_facilities := true ## True while this player owns at least one facility ("alive" test).

## Facilities owned by this player. Resizable container — not threadsafe!
var facilities: Array[Proxy] = []


# ************************* VIRTUAL & IMPLEMENTATION **************************

func _init() -> void:
	const ENTITY_PLAYER := Proxy.EntityType.ENTITY_PLAYER
	super()
	entity_type = ENTITY_PLAYER


func _clear_for_destruction() -> void:
	polity = null
	facilities.clear()
	ai = null


# ********************************* PROXY API *********************************

func has_development() -> bool:
	return true


func get_player_name() -> StringName:
	return name


func get_player_class() -> int:
	return player_class


func get_polity_name() -> StringName:
	return polity.name


## Returns this player's [member facilities]. proxy thread only!
func get_facilities() -> Array[Proxy]:
	return facilities


## Registers [param facility] under this player. Marks the player "alive".
func add_facility(facility: Proxy) -> void:
	assert(!facilities.has(facility))
	facilities.append(facility)
	is_facilities = true


## Removes [param facility] from this player. Updates [member is_facilities]
## to reflect whether the player still owns any facilities.
func remove_facility(facility: Proxy) -> void:
	facilities.erase(facility)
	is_facilities = !facilities.is_empty()
