# itab_physical.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ITabPhysical
extends MarginContainer
const SCENE := "res://public/ui_main/itab_physical.tscn"


const PERSIST_MODE := IVGlobal.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = []

var _selection_manager: SelectionManager

var _body_name: StringName
var _selection_name: StringName

@onready var _tab_resources: TabResources = %Resources



func _ready() -> void:
	visibility_changed.connect(_refresh)
	_selection_manager = IVSelectionManager.get_selection_manager(self)
	_selection_manager.selection_changed.connect(_update_selection)
	_update_selection()


func timer_update() -> void:
	_refresh()


func _refresh() -> void:
	if !visible or !IVStateManager.running:
		return
	if !_body_name or !_selection_name:
		_update_selection()
	_tab_resources.refresh()


func _update_selection(_suppress_camera_move := false) -> void:
	if !visible or !IVStateManager.running:
		return
	var selection_name := _selection_manager.get_selection_name() # body or facility
	if !selection_name:
		return
	var body_name := _selection_manager.get_body_name()
	assert(body_name)
	_body_name = body_name
	_selection_name = selection_name
	_tab_resources.update_selection(body_name, selection_name)
