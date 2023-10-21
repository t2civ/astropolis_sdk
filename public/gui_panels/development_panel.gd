# development_panel.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
extends PanelContainer


const PERSIST_MODE := IVEnums.PERSIST_PROPERTIES_ONLY
const PERSIST_PROPERTIES: Array[StringName] = [
	&"anchor_top",
	&"anchor_left",
	&"anchor_right",
	&"anchor_bottom",
]


func _ready() -> void:
	theme = IVGlobal.themes.main_menu
	@warning_ignore("unsafe_method_access")
	$ControlMod.init_min_size(-1, Vector2.ZERO)
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(1.0, 1.0, 1.0, 0.05) # almost transparent
	set("theme_override_styles/panel", style_box)
	@warning_ignore("unsafe_property_access", "unsafe_method_access")
	$Timer.timeout.connect($StatsGrid.update)
	IVGlobal.system_tree_ready.connect(_delayed_timer_start)
	IVGlobal.simulator_started.connect(_delayed_1st_update)
	@warning_ignore("unsafe_property_access")
	IVGlobal.about_to_free_procedural_nodes.connect(($Timer as Timer).stop)


func _delayed_timer_start(_is_new_game: bool) -> void:
	# wait 0.5 s to offset from InfoPanel/Timer
	await get_tree().create_timer(0.6).timeout
	@warning_ignore("unsafe_method_access")
	$Timer.start()


func _delayed_1st_update() -> void:
	# wait for initial server back-and-forth so there is data to get
	var i := 0
	while i < 8: # add more if needed
		await get_tree().process_frame
		i += 1
	@warning_ignore("unsafe_method_access")
	$StatsGrid.update()

