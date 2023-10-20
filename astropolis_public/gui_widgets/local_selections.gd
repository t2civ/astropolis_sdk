# local_selections.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
extends ScrollContainer

# Contains local selections for info panel navigation:
#    Spacefaring Polities (-> polity at body proxy)
#    Space Agencies (-> local facility)
#    Space Companies (-> local facility)
#    Offworld Facilities (-> in orbit or satellite bodies w/ facility)
#    System Facilities (star selection only; -> in orbit or satellite bodies w/ facility)

const PLAYER_CLASS_POLITY := Enums.PlayerClasses.PLAYER_CLASS_POLITY
const PLAYER_CLASS_AGENCY := Enums.PlayerClasses.PLAYER_CLASS_AGENCY
const PLAYER_CLASS_COMPANY := Enums.PlayerClasses.PLAYER_CLASS_COMPANY
const IS_STAR := IVEnums.BodyFlags.IS_STAR

var section_names := [
	# FIXME
	tr(&"LABEL_SPACEFARING_POLITIES"),
	tr(&"LABEL_SPACE_AGENCIES"),
	tr(&"LABEL_SPACE_COMPANIES"),
	tr(&"LABEL_OFFWORLD_FACILITIES"),
	tr(&"LABEL_SYSTEM_FACILITIES"),
]

var open_prefix := "\u2304   "
var closed_prefix := ">   "
var sub_prefix := "       "
var is_open_sections := [false, false, false, true, true]

var _state: Dictionary = IVGlobal.state

var _pressed_lookup := {} # interface name or section int, indexed by label.text
var _selection_manager: SelectionManager

var _polities: Array[String] = []
var _agencies: Array[String] = []
var _companies: Array[String] = []
var _offworld: Array[String] = []
var _system: Array[String] = []

var _section_arrays := [_polities, _agencies, _companies, _offworld, _system]
var _n_sections := section_names.size()

var _is_busy := false # don't update if getting data on ai thread (cheap mutex)


@onready var _vbox: VBoxContainer = $VBox


func _ready() -> void:
	IVGlobal.simulator_started.connect(_update)
	IVGlobal.about_to_free_procedural_nodes.connect(_clear)
	_update()


func _clear() -> void:
	_selection_manager = null
	_polities.clear()
	_agencies.clear()
	_companies.clear()
	_offworld.clear()
	_system.clear()
	_pressed_lookup.clear()
	for child in _vbox.get_children():
		child.queue_free()


func _init_after_system_built() -> void:
	_selection_manager = IVSelectionManager.get_selection_manager(self)
	_selection_manager.selection_changed.connect(_update)
	var section := 0
	while section < _n_sections:
		var section_text: String = section_names[section]
		_pressed_lookup[open_prefix + section_text] = section
		_pressed_lookup[closed_prefix + section_text] = section
		section += 1


func _update(_dummy := false) -> void:
	if _is_busy:
		return
	if !_state.is_system_built:
		return
	if !_selection_manager:
		_init_after_system_built()
	var selection := _selection_manager.get_selection()
	if !selection:
		return
	_is_busy = true
	var body_name := selection.get_body_name()
	MainThreadGlobal.call_ai_thread(_set_selections_on_ai_thread.bind(body_name))


func _set_selections_on_ai_thread(body_name: StringName) -> void:
	# AI thread!
	_polities.clear()
	_agencies.clear()
	_companies.clear()
	_offworld.clear()
	_system.clear()
	var body: BodyInterface = Interface.get_interface_by_name(body_name)
	if !body:
		_is_busy = false
		return
	var is_star := bool(body.body_flags & IS_STAR)
	_set_selections_recursive(body, is_star, true)
	# TODO: Sort results in some sensible way
	_update_labels.call_deferred()


func _set_selections_recursive(body: BodyInterface, is_star: bool, root_call := false) -> void:
	# AI thread!
	for facility_ in body.get_facilities(): # FIXME Godot 4.2: loop type
		var facility: FacilityInterface = facility_
		
		# add facility for all players here
		var player := facility.player
		var player_gui_name := player.gui_name
		if !player_gui_name: # hidden player
			continue
		var label_text := sub_prefix + player_gui_name
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
		
		if !player_class_array.has(label_text):
			player_class_array.append(label_text)
			_pressed_lookup[label_text] = facility.name
		elif player.homeworld == body.name: # has precedence over any others
			_pressed_lookup[label_text] = facility.name
	
	if !root_call and body.has_development():
		# add body
		var label_text := sub_prefix + body.gui_name
		if is_star:
			_system.append(label_text)
		else:
			_offworld.append(label_text)
		_pressed_lookup[label_text] = body.name
	
	for satellite in body.satellites:
		_set_selections_recursive(satellite, is_star)


func _update_labels() -> void:
	# Main thread
	var n_labels := _vbox.get_child_count()
	var label: Label
	var child_index := 0
	var section := 0
	while section < _n_sections:
		var section_data: Array = _section_arrays[section]
		var n_items := section_data.size()
		while n_labels <= n_items + child_index: # enough if open
			label = Label.new()
			label.mouse_filter = MOUSE_FILTER_PASS
			label.gui_input.connect(_on_gui_input.bind(label))
			_vbox.add_child(label)
			n_labels += 1
		var is_open: bool = is_open_sections[section]
		label = _vbox.get_child(child_index)
		child_index += 1
		if n_items == 0:
			label.hide()
		elif !is_open:
			label.text = closed_prefix + section_names[section]
			label.show()
		else:
			label.text = open_prefix + section_names[section]
			label.show()
			for label_text in section_data:
				label = _vbox.get_child(child_index)
				label.show()
				label.text = label_text
				child_index += 1
		section += 1
	
	_is_busy = false # safe to call again
	
	while child_index < n_labels:
		label = _vbox.get_child(child_index)
		label.hide()
		child_index += 1


func _on_gui_input(event: InputEvent, label: Label) -> void:
	var event_mouse_button := event as InputEventMouseButton
	if !event_mouse_button:
		return
	if !event_mouse_button.pressed:
		return
	if event_mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	# 'lookup' will either be an integer (section index) or string (selection target)
	var lookup = _pressed_lookup.get(label.text)
	if typeof(lookup) == TYPE_INT: # toggle section
		if !_is_busy:
			var section: int = lookup
			is_open_sections[section] = !is_open_sections[section]
			_update_labels()
	else:
		var selection_name: StringName = lookup
		_selection_manager.select_prefer_facility(selection_name)

