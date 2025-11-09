# astropolis_gui.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name AstropolisGUI
extends Control

## Replaces [IVShowHideUI] in the [IVUniverseTemplate] schematic.

const PERSIST_MODE := IVGlobal.PERSIST_PROPERTIES_ONLY # child GUIs are persisted


func _ready() -> void:
	hide()
	set_process_unhandled_key_input(false)
	IVStateManager.simulator_started.connect(show)
	IVStateManager.about_to_free_procedural_nodes.connect(hide)
	IVStateManager.system_tree_built.connect(_on_system_tree_built)
	IVGlobal.show_hide_gui_requested.connect(show_hide_gui)


func _on_system_tree_built(is_new_game: bool) -> void:
	set_process_unhandled_key_input(true)
	if !is_new_game:
		return
	var info_panel: InfoPanel = IVFiles.make_object_or_scene(InfoPanel) # FIXME: create()
	info_panel.set_build_subpanels(true)
	add_child(info_panel)
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_all_gui"):
		show_hide_gui()
		get_viewport().set_input_as_handled()


func show_hide_gui(is_toggle := true, is_show := true) -> void:
	if not IVStateManager.built_system:
		return
	visible = !visible if is_toggle else is_show
