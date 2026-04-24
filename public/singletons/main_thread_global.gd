# main_thread_global.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends Node

# Singleton "MainThreadGlobal".
#
# This global provides safe data access on the main thread, mainly for GUI.
# Note that Interfaces gotten here are not threadsafe. For Interface access on
# the main thread, use only Interface methods marked 'threadsafe'.
#
# Access on main thread only!

signal interface_added(interface: Interface)
signal interface_removed(interface: Interface)
signal ai_thread_called(callable: Callable)

# Emitted once when every Interface has reached the main thread. This is the
# correct barrier for "Interface system is ready" — waiting on
# [signal IVStateManager.simulator_started] alone is insufficient because
# interfaces arrive on the main thread via deferred calls from the AI server
# thread and can continue arriving for a short time after simulator_started.
signal interfaces_ready

const utils := preload("res://public/static/utils.gd")

var interfaces_by_name: Dictionary[StringName, Variant] = {} # PLANET_EARTH, PLAYER_NASA, etc.
var body_selection_redirect := {} # redirect to single facility or local player facility
var interfaces_ready_emitted := false # reset on about_to_free_procedural_nodes

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

func call_ai_thread(callable: Callable) -> void:
	ai_thread_called.emit(callable)


func get_body_selection_redirect(body_name: StringName) -> StringName:
	return body_selection_redirect.get(body_name, &"")


func set_body_selection_redirect(body_name: StringName, redirect_name: StringName) -> void:
	if redirect_name:
		body_selection_redirect[body_name] = redirect_name
	else:
		body_selection_redirect.erase(body_name)


func get_interface_by_name(interface_name: StringName) -> Interface:
	# Returns null if doesn't exist. This method is safe on main thread, but
	# the returned Interface is not!
	return interfaces_by_name.get(interface_name)


func get_gui_name(interface_name: StringName) -> String:
	# Returns translated GUI name.
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return ""
	return interface.gui_name


func get_body_name(interface_name: StringName) -> StringName:
	# Return is useful (not &"") for facility and body.
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return &""
	return interface.get_body_name()


func get_body_flags(interface_name: StringName) -> int:
	# Return is useful (not 0) for facility and body.
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return 0
	return interface.get_body_flags()


func get_player_name(interface_name: StringName) -> StringName:
	# Return is useful (not -1) for facility and player.
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return &""
	return interface.get_player_name()


func get_player_class(interface_name: StringName) -> int:
	# Return is useful (not -1) for facility and player.
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return -1
	return interface.get_player_class()


func get_polity_name(interface_name: StringName) -> StringName:
	# Return is useful (not &"") for facility and player.
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return &""
	return interface.get_polity_name()


func has_development(interface_name: StringName) -> bool:
	# True for facility, join & player; true for body if it has facilities.
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return false
	return interface.has_development()


func has_markets(interface_name: StringName) -> bool:
	# True if interface has inventory.
	var interface: Interface = interfaces_by_name.get(interface_name)
	if !interface:
		return false
	return interface.has_markets()


# *****************************************************************************
# Server only!

func expect_interfaces(count: int) -> void:
	# Server declares how many add_interface calls to expect before emitting
	# interfaces_ready. Must be called before the corresponding add_interface
	# calls reach the main thread.
	assert(!interfaces_ready_emitted)
	_interfaces_expected = true
	_interfaces_pending += count
	_check_interfaces_ready()


func add_interface(interface: Interface) -> void:
	assert(!interfaces_by_name.has(interface.name))
	interfaces_by_name[interface.name] = interface
	if !interfaces_ready_emitted:
		_interfaces_pending -= 1
		_check_interfaces_ready()
	interface_added.emit(interface)


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
