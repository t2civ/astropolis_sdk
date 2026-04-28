# info_tab_margin.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name InfoTabMargin
extends MarginContainer

## Thin wrapper around [InfoTabContainer] that adds the top margin needed by
## [InfoPanel]'s header. Added programmatically so it persists with the
## panel.

const PERSIST_MODE := IVGlobal.PERSIST_PROCEDURAL  ## Save/load mode (procedural node).

## The hosted [InfoTabContainer]. Created in [code]_init()[/code] when
## [param is_new] is true; otherwise restored from save state.
var info_tab_container: InfoTabContainer

var _is_new := false



func _init(is_new := false) -> void:
	if !is_new:
		return
	_is_new = true
	info_tab_container = InfoTabContainer.new(true)


func _ready() -> void:
	name = &"InfoTabMargin"
	mouse_filter = MOUSE_FILTER_IGNORE
	set(&"theme_override_constants/margin_top", 28) # TODO: Settings GUI_SIZE listener
	if _is_new:
		add_child(info_tab_container)
