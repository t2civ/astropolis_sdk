# main_thread_global.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends Node

## Singleton [MainThreadGlobal] holds data and API safe for main thread only,
## mainly for GUI or other SceneTree use.
##
## This global is the canonical entry point for finding [Proxy]s by name
## on the main thread. The returned [Proxy] objects themselves live on
## the AI thread — only call [Proxy] methods marked threadsafe from the
## main thread; for the rest, use [method call_ai_thread] to dispatch work
## to the AI thread.
##
## Access on main thread only!


## Emitted on the main thread when a [Proxy] joins the registry.
signal proxy_added(proxy: Proxy)

## Emitted on the main thread when a [Proxy] leaves the registry.
signal proxy_removed(proxy: Proxy)

## Emitted by [method call_ai_thread] to dispatch a [Callable] for execution
## on the AI thread.
signal ai_thread_called(callable: Callable)

## Emitted once when every [Proxy] has reached the main thread. This is
## the correct barrier for "Proxy system is ready" — waiting on
## [code]IVStateManager.simulator_started[/code] alone is insufficient because
## proxies arrive on the main thread via deferred calls from the AI server
## thread and can continue arriving for a short time after simulator_started.
signal proxies_ready

const utils := preload("res://public/static/utils.gd")  ## Convenience alias for [Utils].

## All [Proxy] instances keyed by [member Proxy.name] (e.g.
## [code]&"PLANET_EARTH"[/code], [code]&"PLAYER_NASA"[/code]).
var proxies_by_name: Dictionary[StringName, Variant] = {}
## Map from body name to facility/player name to redirect selection to a
## single facility or the local player's facility on that body.
var body_selection_redirect := {}
## True after [signal proxies_ready] has been emitted; reset on
## [code]about_to_free_procedural_nodes[/code].
var proxies_ready_emitted := false

var _proxies_pending := 0
var _proxies_expected := false # true once expect_proxies has been called


# *****************************************************************************

func _ready() -> void:
	IVStateManager.about_to_free_procedural_nodes.connect(_clear)


func _clear() -> void:
	proxies_by_name.clear()
	body_selection_redirect.clear()
	proxies_ready_emitted = false
	_proxies_pending = 0
	_proxies_expected = false


# *****************************************************************************
# Access on main thread only!

## Dispatches [param callable] to the AI thread via [signal ai_thread_called].
## Use this from main-thread code that needs to run logic on a [Proxy].
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


## Returns the [Proxy] with the given [param proxy_name], or null if
## no such proxy exists. Safe on the main thread, but the returned
## [Proxy] itself is not — see class docs.
func get_proxy_by_name(proxy_name: StringName) -> Proxy:
	return proxies_by_name.get(proxy_name)


## Returns the translated GUI name for [param proxy_name], or [code]""[/code]
## if not found.
func get_gui_name(proxy_name: StringName) -> String:
	var proxy: Proxy = proxies_by_name.get(proxy_name)
	if !proxy:
		return ""
	return proxy.gui_name


## Returns the body name for [param proxy_name]. Useful (not [code]&""[/code])
## for facilities and bodies.
func get_body_name(proxy_name: StringName) -> StringName:
	var proxy: Proxy = proxies_by_name.get(proxy_name)
	if !proxy:
		return &""
	return proxy.get_body_name()


## Returns body flags for [param proxy_name]. Useful (not 0) for
## facilities and bodies.
func get_body_flags(proxy_name: StringName) -> int:
	var proxy: Proxy = proxies_by_name.get(proxy_name)
	if !proxy:
		return 0
	return proxy.get_body_flags()


## Returns the player name for [param proxy_name]. Useful (not
## [code]&""[/code]) for facilities and players.
func get_player_name(proxy_name: StringName) -> StringName:
	var proxy: Proxy = proxies_by_name.get(proxy_name)
	if !proxy:
		return &""
	return proxy.get_player_name()


## Returns the player class index for [param proxy_name]. Useful (not -1)
## for facilities and players.
func get_player_class(proxy_name: StringName) -> int:
	var proxy: Proxy = proxies_by_name.get(proxy_name)
	if !proxy:
		return -1
	return proxy.get_player_class()


## Returns the polity name for [param proxy_name]. Useful (not
## [code]&""[/code]) for facilities and players.
func get_polity_name(proxy_name: StringName) -> StringName:
	var proxy: Proxy = proxies_by_name.get(proxy_name)
	if !proxy:
		return &""
	return proxy.get_polity_name()


## Returns true if [param proxy_name] contributes development statistics
## (facility, join, player; bodies if they have facilities).
func has_development(proxy_name: StringName) -> bool:
	var proxy: Proxy = proxies_by_name.get(proxy_name)
	if !proxy:
		return false
	return proxy.has_development()


## Returns true if [param proxy_name] participates in markets (has
## inventory).
func has_markets(proxy_name: StringName) -> bool:
	var proxy: Proxy = proxies_by_name.get(proxy_name)
	if !proxy:
		return false
	return proxy.has_markets()


# *****************************************************************************
# Server only!

## Tells [code]MainThreadGlobal[/code] how many [method add_proxy] calls
## to expect before emitting [signal proxies_ready]. Must be called before
## the corresponding [method add_proxy] calls reach the main thread.
func expect_proxies(count: int) -> void:
	assert(!proxies_ready_emitted)
	_proxies_expected = true
	_proxies_pending += count
	_check_proxies_ready()


## Registers [param proxy] under its name. Emits [signal proxy_added].
## Decrements the pending count from [method expect_proxies] and may emit
## [signal proxies_ready] when the count reaches zero.
func add_proxy(proxy: Proxy) -> void:
	assert(!proxies_by_name.has(proxy.name))
	proxies_by_name[proxy.name] = proxy
	if !proxies_ready_emitted:
		_proxies_pending -= 1
		_check_proxies_ready()
	proxy_added.emit(proxy)


## Removes [param proxy] from the registry. Emits [signal proxy_removed].
func remove_proxy(proxy: Proxy) -> void:
	proxies_by_name.erase(proxy.name)
	proxy_removed.emit(proxy)


func _check_proxies_ready() -> void:
	if proxies_ready_emitted:
		return
	if !_proxies_expected:
		return
	if _proxies_pending > 0:
		return
	proxies_ready_emitted = true
	proxies_ready.emit()
