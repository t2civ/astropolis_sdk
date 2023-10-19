# itab_information.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name ITabInformation
extends MarginContainer
const SCENE := "res://astropolis_public/gui_panels/itab_information.tscn"


const PERSIST_MODE := IVEnums.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = []


func timer_update() -> void:
	pass

