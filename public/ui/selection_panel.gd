# selection_panel.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends PanelContainer

## Astropolis selection panel. Hosts the selection image, name label, and
## navigation widgets bound to the GUI's selection manager.


const PERSIST_MODE := IVGlobal.PERSIST_PROPERTIES_ONLY  ## Save/load mode (anchors only).
const PERSIST_PROPERTIES: Array[StringName] = [
	&"anchor_top",
	&"anchor_left",
	&"anchor_right",
	&"anchor_bottom",
]
