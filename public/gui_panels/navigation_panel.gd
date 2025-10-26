# navigation_panel.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends PanelContainer


const PERSIST_MODE := IVGlobal.PERSIST_PROPERTIES_ONLY
const PERSIST_PROPERTIES: Array[StringName] = [
	&"anchor_top",
	&"anchor_left",
	&"anchor_right",
	&"anchor_bottom",
]


func _ready() -> void:
	@warning_ignore("unsafe_method_access")
	$"%AsteroidsHScroll".add_bodies_from_table("asteroids")
	@warning_ignore("unsafe_method_access")
	$"%SpacecraftsHScroll".add_bodies_from_table("spacecrafts")
