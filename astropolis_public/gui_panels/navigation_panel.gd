# navigation_panel.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
extends PanelContainer


const PERSIST_MODE := IVEnums.PERSIST_PROPERTIES_ONLY
const PERSIST_PROPERTIES: Array[StringName] = [
	&"anchor_top",
	&"anchor_left",
	&"anchor_right",
	&"anchor_bottom",
]


#var _settings: Dictionary = IVGlobal.settings
#onready var _under_moons_spacer: Control = find_node("UnderMoonsSpacer")
#var _under_moons_spacer_sizes := [55.0, 66.0, 77.0]


func _ready() -> void:
	IVGlobal.update_gui_requested.connect(_resize)
	IVGlobal.setting_changed.connect(_settings_listener)
	@warning_ignore("unsafe_method_access")
	$"%AsteroidsHScroll".add_bodies_from_table("asteroids")
	@warning_ignore("unsafe_method_access")
	$"%SpacecraftsHScroll".add_bodies_from_table("spacecrafts")


func _resize() -> void:
	pass
#	var gui_size: int = _settings.gui_size
#	_under_moons_spacer.rect_min_size.y = _under_moons_spacer_sizes[gui_size]


func _settings_listener(setting: StringName, _value) -> void:
	if setting == &"gui_size":
		_resize()

