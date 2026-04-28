# main_thread_global.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends Node

## Main-thread autoload (registered as [code]MainThreadGlobal[/code]) for
## safe Interface lookups from GUI and other main-thread code.
##
## This global is the canonical entry point for finding [Interface]s by name
## on the main thread. The returned [Interface] objects themselves live on
## the AI thread — only call [Interface] methods marked threadsafe from the
## main thread; for the rest, use [method call_ai_thread] to dispatch work
## to the AI thread.
##
## Access on main thread only!


## Emitted on the main thread when an [Interface] joins the registry.
signal interface_added(interface: Interface)

## Emitted on the main thread when an [Interface] leaves the registry.
signal interface_removed(interface: Interface)

## Emitted by [method call_ai_thread] to dispatch a [Callable] for execution
## on the AI thread.
signal ai_thread_called(callable: Callable)

## Emitted once when every [Interface] has reached the main thread. This is
## the correct barrier for "Interface system is ready" — waiting on
## [code]IVStateManager.simulator_started[/code] alone is insufficient because
## interfaces arrive on the main thread via deferred calls from the AI server
## thread and can continue arriving for a short time after simulator_started.
signal interfaces_ready

const utils := preload("res://public/static/utils.gd")  ## Convenience alias for [Utils].

## All [Interface] instances keyed by [member Interface.name] (e.g.
## [code]&"PLANET_EARTH"[/code], [code]&"PLAYER_NASA"[/code]).
var interfaces_by_name: Dictionary[StringName, Variant] = {}
## Map from body name to facility/player name to redirect selection to a
## single facility or the local player's facility on that body.
var body_selection_redirect := {}
## True after [signal interfaces_ready] has been emitted; reset on
## [code]about_to_free_procedural_nodes[/code].
var interfaces_ready_emitted := false

var _interfaces_pending := 0
var _interfaces_expected := false # true once expect_interfaces has been called


# *****************************************************************************

func _ready() -> void:
	IVStateManager.about_to_free_procedural_nodes.connect(_clear)


func _clear() -> void:
	interfaces_by_name.clear()
	body_selection_redirect.clear()
	interfaces_ready_emitted = false
	_interfaces_pending = 0
	_interfaces_expected = false


# *****************************************************************************
# Access on main thread only!

## Dispatches [param callable] to the AI thread via [signal ai_thread_called].
## Use this from main-thread code that needs to run logic on an [Interface].
func call_ai_thread(callable: Callable) -> void:
	ai_thread_called.emit(callable)


## Returns the body-selection redirect target for [param body_name], or
## [code]&""[/code] if no redirect is set.
func get_body_selection_redirect(body_name: StringName) -> StringName:
	return body_selection_redirect.get(body_name, &"")


## Sets the selection redirect for [param body_name]. Pass [code]&""[/code]
## as [param redirect_name] to clear the redirect.
func set_body_selection_redirect(body_name: StringName, redirect_name: StringName) -> void:
	if redirect_name:
		body_selection_redirect[body_name] = redirect_name
	else:
		body_selection_redirect.erase(body_name)


## Returns the [Interface] with the given [param interface_name], or null if
## no such interface exists. Safe on the main thread, but the returned
## [Interface] itself is not — see class docs.
func get_interface_by_name(interface_name: StringName) -> Interface:
	return interfaces_by_name.get(interface_name)


## Returns the translated GUI name for [param interface_name], or [code]""[/code]
## if not found.
func get_gui_name(interface_name: StringName) -> String:
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return ""
	return interface.gui_name


## Returns the body name for [param interface_name]. Useful (not [code]&""[/code])
## for facilities and bodies.
func get_body_name(interface_name: StringName) -> StringName:
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return &""
	return interface.get_body_name()


## Returns body flags for [param interface_name]. Useful (not 0) for
## facilities and bodies.
func get_body_flags(interface_name: StringName) -> int:
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return 0
	return interface.get_body_flags()


## Returns the player name for [param interface_name]. Useful (not
## [code]&""[/code]) for facilities and players.
func get_player_name(interface_name: StringName) -> StringName:
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return &""
	return interface.get_player_name()


## Returns the player class index for [param interface_name]. Useful (not -1)
## for facilities and players.
func get_player_class(interface_name: StringName) -> int:
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return -1
	return interface.get_player_class()


## Returns the polity name for [param interface_name]. Useful (not
## [code]&""[/code]) for facilities and players.
func get_polity_name(interface_name: StringName) -> StringName:
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return &""
	return interface.get_polity_name()


## Returns true if [param interface_name] contributes development statistics
## (facility, join, player; bodies if they have facilities).
func has_development(interface_name: StringName) -> bool:
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return false
	return interface.has_development()


## Returns true if [param interface_name] participates in markets (has
## inventory).
func has_markets(interface_name: StringName) -> bool:
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return false
	return interface.has_markets()


# *****************************************************************************
# Server only!

## Tells [code]MainThreadGlobal[/code] how many [method add_interface] calls
## to expect before emitting [signal interfaces_ready]. Must be called before
## the corresponding [method add_interface] calls reach the main thread.
func expect_interfaces(count: int) -> void:
	assert(!interfaces_ready_emitted)
	_interfaces_expected = true
	_interfaces_pending += count
	_check_interfaces_ready()


## Registers [param interface] under its name. Emits [signal interface_added].
## Decrements the pending count from [method expect_interfaces] and may emit
## [signal interfaces_ready] when the count reaches zero.
func add_interface(interface: Interface) -> void:
	assert(!interfaces_by_name.has(interface.name))
	interfaces_by_name[interface.name] = interface
	if !interfaces_ready_emitted:
		_interfaces_pending -= 1
		_check_interfaces_ready()
	interface_added.emit(interface)


## Removes [param interface] from the registry. Emits [signal interface_removed].
func remove_interface(interface: Interface) -> void:
	interfaces_by_name.erase(interface.name)
	interface_removed.emit(interface)


func _check_interfaces_ready() -> void:
	if interfaces_ready_emitted:
		return
	if !_interfaces_expected:
		return
	if _interfaces_pending > 0:
		return
	interfaces_ready_emitted = true
	interfaces_ready.emit()
