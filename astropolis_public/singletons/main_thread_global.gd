# main_thread_global.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
extends Node

# Singleton "MainThreadGlobal".
#
# This global provides safe data access on the main thread, mainly for GUI.
# Note that Interfaces gotten here are not threadsafe. For Interface access on
# the main thread, use only Interface methods marked 'threadsafe'.

signal interface_added(interface)
signal interface_removed(interface)
signal ai_thread_called(callable)


const utils := preload("res://astropolis_public/static/utils.gd")

var local_player_name := &"PLAYER_NASA"
var home_facility_name := &"FACILITY_PLANET_EARTH_PLAYER_NASA"

# Access on main thread only!

var interfaces_by_name := {} # PLANET_EARTH, PLAYER_NASA, etc.
var body_selection_redirect := {} # redirect to single facility or local player facility


# *****************************************************************************

func _ready() -> void:
	IVGlobal.about_to_free_procedural_nodes.connect(_clear)


func _clear() -> void:
	interfaces_by_name.clear()
	body_selection_redirect.clear()


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
	# True for facility, proxy & player; true for body if it has facilities.
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

func add_interface(interface: Interface) -> void:
	assert(!interfaces_by_name.has(interface.name))
	interfaces_by_name[interface.name] = interface
	interface_added.emit(interface)


func remove_interface(interface: Interface) -> void:
	interfaces_by_name.erase(interface.name)
	interface_removed.emit(interface)

