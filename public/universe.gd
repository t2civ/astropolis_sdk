# universe.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name Universe
extends Node3D

## Main scene.
##
## Duplicated and modified from [IVUniverseTemplate].

const PERSIST_MODE := IVGlobal.PERSIST_PROPERTIES_ONLY ## Don't free on load.
const PERSIST_PROPERTIES: Array[StringName] = [&"persist"]

var persist := {}
