# itab_development.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ITabDevelopment
extends MarginContainer
const SCENE := "res://public/gui_panels/itab_development.tscn"

const BodyFlags: Dictionary = IVEnums.BodyFlags
const BodyFlags2: Dictionary = Enums.BodyFlags2
const PLAYER_CLASS_POLITY := Enums.PlayerClasses.PLAYER_CLASS_POLITY

const PERSIST_MODE := IVEnums.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = []

var _state: Dictionary = IVGlobal.state
var _selection_manager: SelectionManager

@onready var _stats_grid: StatsGrid = $StatsGrid
@onready var _no_dev_label: Label = $NoDevLabel


func _ready() -> void:
	IVGlobal.update_gui_requested.connect(_update_selection)
	visibility_changed.connect(_update_selection)
	_stats_grid.has_stats_changed.connect(_update_no_development)
	_selection_manager = IVSelectionManager.get_selection_manager(self)
	_selection_manager.selection_changed.connect(_update_selection)
	_stats_grid.min_columns = 4
	_update_selection()


func timer_update() -> void:
	_stats_grid.update()


func _update_no_development(has_stats: bool) -> void:
	_no_dev_label.visible = !has_stats


func _update_selection(_dummy := false) -> void:
	if !visible or !_state.is_running:
		return
	var selection_name := _selection_manager.get_selection_name()
	if !selection_name:
		return

	prints(selection_name)
	
	# Selection is either a Facility or Body. It's a Facility if user selected
	# a player (NASA, USA, etc.), so show auxilary columns accordingly.
	
	var body_name: StringName = MainThreadGlobal.get_body_name(selection_name)
	var body_flags: int = MainThreadGlobal.get_body_flags(body_name)
	var player_join_name := ""
	if selection_name.begins_with("FACILITY_"):
		player_join_name = "_" + MainThreadGlobal.get_player_name(selection_name)
	
	var targets: Array[StringName] = []
	var column_names: Array[StringName] = []
	
	if body_flags & BodyFlags.IS_PLANET:
		targets.append(selection_name) # Facility or Body name
		column_names.append(&"LABEL_PLANET")
		if body_flags & BodyFlags2.GUI_HAS_ONE_MOON:
			targets.append(StringName("JOIN_" + body_name + "_MOONS" + player_join_name))
			column_names.append(&"LABEL_MOON")
		elif body_flags & BodyFlags2.GUI_HAS_MOONS:
			targets.append(StringName("JOIN_" + body_name + "_MOONS" + player_join_name))
			column_names.append(&"LABEL_MOONS")
		targets.append(StringName("JOIN_" + body_name + "_SPACE" + player_join_name))
		column_names.append(&"LABEL_SPACE")
	
	elif body_flags & BodyFlags.IS_STAR:
		targets.append(StringName("JOIN_" + body_name + "_PLANETS" + player_join_name))
		targets.append(StringName("JOIN_" + body_name + "_MOONS" + player_join_name))
		targets.append(StringName("JOIN_" + body_name + "_PLANETOIDS" + player_join_name))
		targets.append(StringName("JOIN_" + body_name + "_SPACE" + player_join_name))
		column_names.append(&"LABEL_PLANETS")
		column_names.append(&"LABEL_MOONS")
		column_names.append(&"LABEL_PLANETOIDS")
		column_names.append(&"LABEL_SPACE")
	
	else:
		targets.append(body_name)
	
	_stats_grid.update_targets(targets, column_names)

