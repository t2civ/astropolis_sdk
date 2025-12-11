# selection_manager.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name SelectionManager
extends IVSelectionManager

# Everything here works on the main thread! NOT THREADSAFE!
#
# TODO: Support FacilityInterface, then any Interface and only Interfaces.


static func _static_init() -> void:
	replacement_subclass = SelectionManager



func get_body_gui_name() -> String:
	var body_name := get_body_name()
	if !body_name:
		return ""
	# FIXME: get_gui_name() should be I, Voyager Core
	return MainThreadGlobal.get_gui_name(body_name)
