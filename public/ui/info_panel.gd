# info_panel.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name InfoPanel
extends PanelContainer

## Astropolis selection-info panel showing tabbed details for the current
## selection.
##
## Original (unpinned) instances share [member AstropolisGUI.selection_manager];
## cloned (pinned) instances each have their own [AstroSelectionManager]
## following an independent selection. [InfoTabMargin], [InfoTabContainer],
## and the per-tab subpanels are added procedurally so they save and restore
## on game load.


const SCENE := "res://public/ui/info_panel.tscn"  ## Scene file for instancing.

## Emitted when the user clicks the pin button. Listener should clone this
## panel and add the clone to the GUI tree.
signal clone_and_pin_requested(info_panel: InfoPanel)


const PERSIST_MODE := IVGlobal.PERSIST_PROCEDURAL  ## Save/load mode (procedural node).
## Member names persisted by save/load.
const PERSIST_PROPERTIES: Array[StringName] = [
	&"anchor_top",
	&"anchor_left",
	&"anchor_right",
	&"anchor_bottom",
	&"selection_manager",
	&"is_pinned",
]

## Selection manager driving this panel. Shared with the GUI for the
## original (unpinned) panel; private for cloned (pinned) panels.
var selection_manager: AstroSelectionManager
## True if this panel is a pinned clone. Pinned panels show a close button
## and follow their own selection.
var is_pinned := false

var _build_subpanels := false

@onready var _header_label: Label = $HeaderLabel



func _ready() -> void:
	# After system built (this panel only...)
	
	# FIXME: SelectionManager handling & UI refresh
	
	
	IVStateManager.about_to_free_procedural_nodes.connect(_clear_procedural)
	($TRButtons/Pin as Button).pressed.connect(_clone_and_pin)
	if is_pinned:
		($TRButtons/Close as Button).pressed.connect(_close)
		_init_after_system()
	else:
		IVStateManager.system_tree_ready.connect(_init_after_system, CONNECT_ONE_SHOT)
		($TRButtons/Close as Button).hide()


func _clear_procedural() -> void:
	selection_manager = null


## Tells this panel to build its [InfoTabMargin] and tab subpanels at ready.
## Set to true on the original (non-cloned) panel; cloned panels skip this
## because they're already populated when serialized.
func set_build_subpanels(build_subpanels: bool) -> void:
	_build_subpanels = build_subpanels


func _init_after_system(_dummy := false) -> void:
	if !selection_manager:
		# This is the original (non-cloned) InfoPanel and a new game!
		selection_manager = IVSelectionManager.get_selection_manager(self)
	selection_manager.selection_changed.connect(_update_selection)
	IVGlobal.ui_dirty.connect(_update_selection)
	visibility_changed.connect(_update_selection)
	_update_selection()
	
	if _build_subpanels:
		var info_tab_margin := InfoTabMargin.new(true)
		add_child(info_tab_margin)


func _update_selection(_dummy := false) -> void:
	if !visible or !IVStateManager.running:
		return
	_header_label.text = selection_manager.get_gui_name()


func _clone_and_pin() -> void:
	clone_and_pin_requested.emit(self)


func _close() -> void:
	queue_free()
