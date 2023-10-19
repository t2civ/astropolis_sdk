# info_cloner.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name InfoCloner

# Clones InfoPanel on 'clone_and_pin_requested' signal.


func _ivcore_init() -> void:
	IVGlobal.system_tree_ready.connect(_on_system_tree_ready)


func _on_system_tree_ready(_is_new_game: bool) -> void:
	var astro_gui: AstroGUI = IVGlobal.program.AstroGUI
	for child in astro_gui.get_children():
		var info_panel := child as InfoPanel
		if info_panel:
			info_panel.clone_and_pin_requested.connect(_pin_info_panel)


func _pin_info_panel(info_panel: InfoPanel) -> void:
	print("_pin_info_panel")

	# clone selection_manager (clone will be non-listening)
	var selection_manager: SelectionManager = info_panel.selection_manager
	var sm_clone: SelectionManager = SelectionManager.new()
	sm_clone.set_selection_and_history(selection_manager.get_selection_and_history())
	sm_clone.info_panel_target_name = selection_manager.info_panel_target_name
	sm_clone.is_action_listener = false

	# clone subpanel tree w/ persist properties
	var itc: InfoTabContainer = info_panel.get_node("InfoTabMargin/InfoTabContainer")
	var subpanels := itc.subpanels
	var itm_clone := InfoTabMargin.new(true) # we assume no PERSIST_PROPERTIES in this
	var itc_clone := itm_clone.info_tab_container
	var subpanel_clones := itc_clone.subpanels
	var n_subpanels := subpanels.size()
	assert(subpanel_clones.size() == n_subpanels)
	IVSaveBuilder.clone_persist_properties(itc, itc_clone)
	var i := 0
	while i < n_subpanels:
		IVSaveBuilder.clone_persist_properties(subpanels[i], subpanel_clones[i])
		i += 1
	
	# clone InfoPanel (no persist properties we need to worry about)
	var panel_clone: InfoPanel = IVFiles.make_object_or_scene(InfoPanel)
	panel_clone.clone_and_pin_requested.connect(_pin_info_panel)
	panel_clone.selection_manager = sm_clone
	panel_clone.is_pinned = true

	# build the tree
	var astro_gui: AstroGUI = IVGlobal.program.AstroGUI
	astro_gui.add_child(panel_clone)
	panel_clone.add_child(sm_clone)
	panel_clone.add_child(itm_clone)
	# TODO: Smarter positioning of cloned panel
	panel_clone.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
	# delay and do some finish work
	await IVGlobal.get_tree().process_frame
	@warning_ignore("unsafe_method_access")
	panel_clone.get_node("ControlMod").finish_move()

