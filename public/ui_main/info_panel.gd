# info_panel.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name InfoPanel
extends PanelContainer


const SCENE := "res://public/ui_main/info_panel.tscn"

# TODO: We could move clone logic here now that self referencing is ok.

# InfoTabMargin, InfoTabContainer, and the subpanels are added procedurally so
# they can be saved and restored on game load.
# 'selection_manager' points to AstropolisGUI.selection_manager if this is the
# original (unpinned) InfoPanel. If this is a cloned (pinned) InfoPanel, then
# it has its own SelectionManager instance.

signal clone_and_pin_requested(info_panel: InfoPanel)


const PERSIST_MODE := IVGlobal.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = [
	&"anchor_top",
	&"anchor_left",
	&"anchor_right",
	&"anchor_bottom",
	&"selection_manager",
	&"is_pinned",
]

var selection_manager: SelectionManager
var is_pinned := false

var _build_subpanels := false
var _selection: IVSelection

@onready var _header_label: Label = $HeaderLabel



func _ready() -> void:
	# After system built (this panel only...)
	
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
	_selection = null


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
