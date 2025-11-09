# local_selections.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name LocalSelections
extends MarginContainer

# Contains local selections for info panel navigation:
#    Spacefaring Polities (-> local facility)
#    Space Agencies (-> local facility)
#    Space Companies (-> local facility)
#    Offworld Facilities (-> in orbit or satellite bodies w/ facility)
#    System Facilities (star selection only; -> in orbit or satellite bodies w/ facility)

var _selection_manager: SelectionManager
var _selection_lookup: Dictionary[String, StringName] = {} # item text -> selection name

var _polities: Array[String] = []
var _agencies: Array[String] = []
var _companies: Array[String] = []
var _offworld: Array[String] = []
var _system: Array[String] = []

var _section_content: Array[Array] = [_polities, _agencies, _companies, _offworld, _system]
var _n_sections := _section_content.size()

var _is_busy := false # don't update if getting data on ai thread (cheap mutex)

@onready var _scroll_container: ScrollContainer = $ScrollContainer
@onready var _no_facilities: Label = $NoFacilities
@onready var _section_foldables: Array[FoldableContainer] = [
	$ScrollContainer/VBox/Polities,
	$ScrollContainer/VBox/Agencies,
	$ScrollContainer/VBox/Companies,
	$ScrollContainer/VBox/Offworld,
	$ScrollContainer/VBox/System,
]
@onready var _section_vboxes: Array[VBoxContainer] = [
	$ScrollContainer/VBox/Polities/VBox,
	$ScrollContainer/VBox/Agencies/VBox,
	$ScrollContainer/VBox/Companies/VBox,
	$ScrollContainer/VBox/Offworld/VBox,
	$ScrollContainer/VBox/System/VBox,
]


func _ready() -> void:
	IVGlobal.update_gui_requested.connect(_update_selection)
	IVStateManager.about_to_free_procedural_nodes.connect(_clear_procedural)
	IVStateManager.about_to_start_simulator.connect(_connect_selection_manager)
	if IVStateManager.started_or_about_to_start:
		_connect_selection_manager()


func _clear_procedural() -> void:
	if _selection_manager:
		_selection_manager.selection_changed.disconnect(_update_selection)
		_selection_manager = null


func _connect_selection_manager(_dummy := false) -> void:
	# every sim start
	_selection_manager = IVSelectionManager.get_selection_manager(self)
	assert(_selection_manager, "Did not find valid 'selection_manager' above this node")
	_selection_manager.selection_changed.connect(_update_selection)


func _update_selection(_dummy := false) -> void:
	# Main thread
	if _is_busy:
		return
	var selection := _selection_manager.get_selection()
	if !selection:
		return
	_is_busy = true
	var body_name := selection.get_body_name()
	MainThreadGlobal.call_ai_thread(_set_selections_on_ai_thread.bind(body_name))


func _set_selections_on_ai_thread(body_name: StringName) -> void:
	# AI thread!
	const BODYFLAGS_STAR := IVBody.BodyFlags.BODYFLAGS_STAR
	
	_polities.clear()
	_agencies.clear()
	_companies.clear()
	_offworld.clear()
	_system.clear()
	_selection_lookup.clear()
	
	var body: BodyInterface = Interface.get_interface_by_name(body_name)
	if !body:
		_is_busy = false
		return
	var is_star := bool(body.body_flags & BODYFLAGS_STAR)
	_set_selections_recursive(body, is_star, true)
	# TODO: Sort results in some sensible way
	
	_update_foldables.call_deferred()


func _set_selections_recursive(body: BodyInterface, is_star: bool, root_call := false) -> void:
	# AI thread!
	const PLAYER_CLASS_POLITY := Enums.PlayerClasses.PLAYER_CLASS_POLITY
	const PLAYER_CLASS_AGENCY := Enums.PlayerClasses.PLAYER_CLASS_AGENCY
	const PLAYER_CLASS_COMPANY := Enums.PlayerClasses.PLAYER_CLASS_COMPANY
	
	# add players that have a facility here
	for facility: FacilityInterface in body.get_facilities():
		var player := facility.player
		var player_gui_name := player.gui_name
		if !player_gui_name: # hidden player
			continue
		var player_class_array: Array
		match player.player_class:
			PLAYER_CLASS_POLITY:
				player_class_array = _polities
			PLAYER_CLASS_AGENCY:
				player_class_array = _agencies
			PLAYER_CLASS_COMPANY:
				player_class_array = _companies
			_:
				assert(false, "Unknown player_class")
		if !player_class_array.has(player_gui_name):
			player_class_array.append(player_gui_name)
			_selection_lookup[player_gui_name] = facility.name
		elif player.homeworld == body.name: # has precedence over any others
			_selection_lookup[player_gui_name] = facility.name
	
	# add "offworld" or "system" bodies that have facilities
	if !root_call and body.has_development():
		# add body
		var body_gui_name := body.gui_name
		if is_star:
			_system.append(body_gui_name)
		else:
			_offworld.append(body_gui_name)
		_selection_lookup[body_gui_name] = body.name
	
	# recurse satallites
	for satellite_name in body.satellites:
		_set_selections_recursive(body.satellites[satellite_name], is_star)


func _update_foldables() -> void:
	# Main thread
	var has_facilities := false
	for i in _n_sections:
		if _section_content[i]:
			has_facilities = true
			_section_foldables[i].show()
			_update_foldable(i)
		else:
			_section_foldables[i].hide()
	_scroll_container.visible = has_facilities
	_no_facilities.visible = !has_facilities
	_is_busy = false # safe to call again


func _update_foldable(index: int) -> void:
	# Main thread
	var vbox := _section_vboxes[index]
	var n_buttons := vbox.get_child_count()
	var content: Array[String] = _section_content[index]
	var n_items := content.size()
	# add buttons as needed
	while n_buttons < n_items:
		var button := Button.new()
		button.pressed.connect(_on_pressed.bind(button))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		vbox.add_child(button)
		n_buttons += 1
	# set button texts
	var item_index := 0
	while item_index < n_items:
		var button: Button = vbox.get_child(item_index)
		button.text = content[item_index]
		button.show()
		item_index += 1
	# hide unused
	while item_index < n_buttons:
		var button: Button = vbox.get_child(item_index)
		button.hide()
		item_index += 1


func _on_pressed(button: Button) -> void:
	var selection_name := _selection_lookup[button.text]
	_selection_manager.select_prefer_facility(selection_name)
