# astro_selection_manager.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name AstroSelectionManager
extends IVSelectionManager

## Astropolis subclass of [IVSelectionManager] that adds [Interface]
## selections (alongside ivoyager's [code]IVBody[/code] / [code]IVSmallBodiesGroup[/code]
## selections).
##
## Registers itself as the [code]IVSelectionManager[/code] replacement at
## static init and registers [member MainThreadGlobal.interfaces_by_name] as
## an additional selection-name source so any [Interface] can be selected by
## name.


static func _static_init() -> void:
	replacement_subclass = AstroSelectionManager
	add_selection_dictionary(MainThreadGlobal.interfaces_by_name)


## Returns the translated GUI name for the currently-selected body, or
## [code]""[/code] if no body is selected.
func get_body_gui_name() -> String:
	var body_name := get_body_name()
	if !body_name:
		return ""
	# FIXME: get_gui_name() should be I, Voyager Core
	return MainThreadGlobal.get_gui_name(body_name)
