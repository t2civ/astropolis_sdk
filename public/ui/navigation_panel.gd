# navigation_panel.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends PanelContainer

## Astropolis navigation panel — system-tree navigation buttons (sun, planets,
## moons, etc.) docked to the GUI.


const PERSIST_MODE := IVGlobal.PERSIST_PROPERTIES_ONLY  ## Save/load mode (anchors only).
const PERSIST_PROPERTIES: Array[StringName] = [
	&"anchor_top",
	&"anchor_left",
	&"anchor_right",
	&"anchor_bottom",
]
