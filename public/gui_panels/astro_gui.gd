# astro_gui.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name AstroGUI
extends Control
const SCENE := "res://public/gui_panels/astro_gui.tscn"


const PERSIST_MODE := IVEnums.PERSIST_PROPERTIES_ONLY # child GUIs are persisted


func _ready() -> void:
	IVGlobal.system_tree_built_or_loaded.connect(_on_system_tree_built_or_loaded)
	IVGlobal.simulator_started.connect(show)
	IVGlobal.about_to_free_procedural_nodes.connect(hide)
	IVGlobal.show_hide_gui_requested.connect(show_hide_gui)
	hide()


func _on_system_tree_built_or_loaded(is_new_game: bool) -> void:
	if !is_new_game:
		return
	var info_panel: InfoPanel = IVFiles.make_object_or_scene(InfoPanel)
	info_panel.set_build_subpanels(true)
	add_child(info_panel)
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_all_gui"):
		show_hide_gui()
	else:
		return # input NOT handled!
	get_viewport().set_input_as_handled()


func show_hide_gui(is_toggle := true, is_show := true) -> void:
	if !IVGlobal.state.is_system_built:
		return
	visible = !visible if is_toggle else is_show

