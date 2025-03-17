# selection_panel.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends PanelContainer

const ViewFlags := IVView.ViewFlags

const PERSIST_MODE := IVEnums.PERSIST_PROPERTIES_ONLY
const PERSIST_PROPERTIES: Array[StringName] = [
	&"anchor_top",
	&"anchor_left",
	&"anchor_right",
	&"anchor_bottom",
]


var default_view_name := &"LABEL_VIEW1" # will increment if taken
var collection_name := &"SP"
var is_cached := false # if false, persisted via gamesave
var view_flags := ViewFlags.ALL
var init_flags := ViewFlags.ALL_CAMERA
var reserved_view_names: Array[StringName] = [&"BUTTON_HOME"]



func _ready() -> void:
	@warning_ignore("unsafe_method_access")
	$"%ViewSaveFlow".init($"%ViewSaveButton", default_view_name, collection_name, is_cached,
			view_flags, init_flags, reserved_view_names)
