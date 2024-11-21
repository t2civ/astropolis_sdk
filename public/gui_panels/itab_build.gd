# itab_build.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ITabBuild
extends MarginContainer
const SCENE := "res://public/gui_panels/itab_build.tscn"


const PERSIST_MODE := IVEnums.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = []


func timer_update() -> void:
	pass
