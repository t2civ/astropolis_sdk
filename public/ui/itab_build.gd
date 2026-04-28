# itab_build.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ITabBuild
extends MarginContainer

## "Build" tab subpanel for [InfoPanel]. Shows construction queue and
## available modules for the selected facility. Currently a stub.

const SCENE := "res://public/ui/itab_build.tscn"  ## Scene file for instancing.


const PERSIST_MODE := IVGlobal.PERSIST_PROCEDURAL  ## Save/load mode (procedural node).
const PERSIST_PROPERTIES: Array[StringName] = []  ## Member names persisted by save/load.


## Refreshes the build tab. Wired to [InfoTabContainer]'s shared 1 s timer.
## Currently a stub.
func timer_update() -> void:
	pass
