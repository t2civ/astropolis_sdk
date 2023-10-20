# itab_resources.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name ITabResources
extends MarginContainer
const SCENE := "res://astropolis_public/gui_panels/itab_resources.tscn"


const SUPER_OPEN_PREFIX := "\u2304 "
const SUPER_CLOSED_PREFIX := "> "
const STRATUM_OPEN_PREFIX := "  \u2304 "
const STRATUM_CLOSED_PREFIX := "  > "
const RESOURCE_INDENT := "        "
const IS_SPACECRAFT := IVEnums.BodyFlags.IS_SPACECRAFT

const PERSIST_MODE := IVEnums.PERSIST_PROCEDURAL

const LENGTH_M_KM := IVQFormat.DynamicUnitType.LENGTH_M_KM


var _tables: Dictionary = IVTableData.tables
var _is_extraction_resources: Array = _tables.extraction_resources
var _n_is_extraction_resources := _is_extraction_resources.size()
var _resource_sort_overrides: Array = _tables.resources.sort_override
var _init_opens: Array = _tables.compositions.init_open
var _hide_variances: Array = _tables.resources.hide_variances
var _stratum_names: Array = _tables.strata.name
var _survey_names: Array = _tables.surveys.name
var _composition_types: Dictionary # table name enumeration

var _state: Dictionary = IVGlobal.state
var _selection_manager: SelectionManager

@onready var _vbox: VBoxContainer = $VBox
@onready var _no_resources: Label = $NoResources
@onready var _resource_vbox: VBoxContainer = $"%ResourceVBox"
@warning_ignore("unsafe_property_access")
@onready var _memory: Dictionary = get_parent().memory # open states


func _ready() -> void:
	visibility_changed.connect(_update_selection)
	_selection_manager = IVSelectionManager.get_selection_manager(self)
	_selection_manager.selection_changed.connect(_update_selection)
	_composition_types = IVTableData.enumeration_dicts[&"compositions"]
	_update_selection()


func timer_update() -> void:
	_update_selection()


func _update_selection(_suppress_camera_move := false) -> void:
	if !visible or !_state.is_running:
		return
	var selection_name := _selection_manager.get_selection_name() # body or facility
	if !selection_name:
		return
	var body_name := _selection_manager.get_body_name()
	MainThreadGlobal.call_ai_thread(_get_ai_data.bind(body_name, selection_name))


# *****************************************************************************
# AI thread !!!!

func _get_ai_data(body_name: StringName, selection_name: StringName) -> void:
	var data: Array = []
	var polity_name := ""
	if selection_name.begins_with("FACILITY_"):
		var selection_interface := Interface.get_interface_by_name(selection_name)
		polity_name = selection_interface.get_polity_name()
	var body_interface: BodyInterface = Interface.get_interface_by_name(body_name)
	if !body_interface:
		_update_no_resources.call_deferred()
		return
	
	var compositions := body_interface.compositions
	if !compositions:
		var is_unknown := not body_interface.body_flags & IS_SPACECRAFT
		_update_no_resources.call_deferred(is_unknown)
		return
	
	var composition_polities := []
	var open_at_init: Array[bool] = []
	
	var n_compositions := compositions.size()

	for i in n_compositions:
		var composition: Composition = compositions[i]
		var composition_polity := composition.polity_name
		if polity_name and composition_polity and polity_name != composition_polity:
			continue
		var init_open: bool
		if !composition_polities.has(composition_polity):
			composition_polities.append(composition_polity)
			init_open = polity_name == composition_polity # "" == "" at body for commons
			open_at_init.append(init_open)
		var masses := composition.masses
		var heterogeneities := composition.heterogeneities
		var total_mass := composition.get_total_mass()
		var survey_type := composition.survey_type
		
		var resources_data := []
		# We're bypassing some Compsition API for efficiency here, which makes
		# it more complicated. Composition resource indexes must be converted
		# to resource_type.
		for j in _n_is_extraction_resources:
			var mass: float = masses[j]
			if mass == 0.0:
				continue
			var resource_type: int = _is_extraction_resources[j]
			var mean := 100.0 * mass / total_mass # mass percent
			var uncertainty := 0.0
			var heterogeneity := 0.0
			var deposits := 0.0
			if !_hide_variances[resource_type]:
				uncertainty = 100.0 * composition.get_fractional_mass_uncertainty(resource_type)
				if heterogeneities[j]:
					heterogeneity = 100.0 * composition.get_fractional_heterogeneity(resource_type)
					if heterogeneity:
						deposits = 100.0 * composition.get_fractional_deposits(resource_type, true)
			
			var resource_data := [resource_type, mean, uncertainty, heterogeneity, deposits]
			resources_data.append(resource_data)
		
		resources_data.sort_custom(_sort_resources)
		
		var evidence: StringName = _survey_names[survey_type]
		init_open = true
		var composition_type: int = _composition_types.get(composition.name, -1)
		if composition_type != -1:
			init_open = _init_opens[composition_type]
		
		resources_data.append(total_mass)
		resources_data.append(composition.density)
		resources_data.append(composition.get_volume())
		resources_data.append(composition.thickness)
		resources_data.append(composition.body_radius)
		resources_data.append(evidence)
		resources_data.append(composition.stratum_type)
		resources_data.append(init_open)
		resources_data.append(composition_polity)
		
		data.append(resources_data)
	
	_update_display.call_deferred(selection_name, composition_polities, open_at_init, data)


func _sort_resources(a: Array, b: Array) -> bool:
	var a_override: int = _resource_sort_overrides[a[0]]
	var b_override: int = _resource_sort_overrides[b[0]]
	if a_override != b_override:
		return a_override > b_override
	if a[4] != b[4]:
		return a[4] > b[4] # deposits
	return a[1] > b[1] # mean


# *****************************************************************************
# Main thread !!!!


func _update_no_resources(is_unknown := true) -> void:
	_vbox.hide()
	_no_resources.text = (&"LABEL_UNKNOWN_RESOURCES_PARENTHESIS" if is_unknown
			else &"LABEL_NO_RESOURCES_PARENTHESIS")
	_no_resources.show()


func _update_display(selection_name: StringName, composition_polities: Array,
		open_at_init: Array[bool], data: Array) -> void:

	# TODO: Sort composition_polities in some sensible way
	var n_polities := composition_polities.size()
	var n_polity_vboxes := _resource_vbox.get_child_count()
	
	# add OwnerVBoxes as needed
	while n_polity_vboxes < n_polities:
		var polity_vbox := PolityVBox.new(_memory)
		_resource_vbox.add_child(polity_vbox)
		n_polity_vboxes += 1

	# set OwnerVBoxes we'll use & hide extras
	var i := 0
	while i < n_polities:
		var polity_vbox: PolityVBox = _resource_vbox.get_child(i)
		var polity_name: StringName = composition_polities[i]
		var init_open: bool = open_at_init[i]
		polity_vbox.set_vbox(selection_name, polity_name, init_open)
		polity_vbox.show()
		i += 1
	while i < n_polity_vboxes:
		var polity_vbox: PolityVBox = _resource_vbox.get_child(i)
		polity_vbox.hide()
		i += 1
	
	# add strata
	var n_strata := data.size()
	i = 0
	while i < n_strata:
		var resources_data: Array = data[i]
		var composition_polity: StringName = resources_data.pop_back()
		var init_open: bool = resources_data.pop_back()
		var stratum_type: int = resources_data.pop_back()
		var evidence: StringName = resources_data.pop_back()
		var body_radius: float = resources_data.pop_back()
		var thickness: float = resources_data.pop_back()
		var volume: float = resources_data.pop_back()
		var density: float = resources_data.pop_back()
		var total_mass: float = resources_data.pop_back()
		# resources_data now in correct form for add_stratum()
		var stratum_name: StringName = _stratum_names[stratum_type]
		var hint_format_str: String
		if body_radius == thickness:
			hint_format_str = tr(&"HINT_STRATUM_FORMAT_1") # radius for sm undiff body
		else:
			hint_format_str = tr(&"HINT_STRATUM_FORMAT_2") # thickness
		var hint := hint_format_str % [
			tr(evidence),
			IVQFormat.dynamic_unit(thickness, LENGTH_M_KM, 3),
			IVQFormat.fixed_unit(volume, &"km^3", 3),
			IVQFormat.fixed_unit(density, &"g/cm^3", 3),
			IVQFormat.fixed_unit(total_mass, &"t", 3),
		]
		
		var polity_index := composition_polities.find(composition_polity)
		var polity_vbox: PolityVBox = _resource_vbox.get_child(polity_index)
		polity_vbox.add_stratum(stratum_name, hint, init_open, resources_data)
		i += 1
	
	for polity_vbox in _resource_vbox.get_children():
		@warning_ignore("unsafe_method_access")
		polity_vbox.finish_strata()
	
	_vbox.show()
	_no_resources.hide()



class PolityVBox extends VBoxContainer:
	# hide when not in use
	
	var _polity_header := Button.new()
	var _polity_text: String
	var _is_open := true
	var _memory: Dictionary
	var _memory_key: String
	var _next_child_index := 1
	
	
	func _init(memory: Dictionary) -> void:
		_memory = memory
		size_flags_horizontal = SIZE_FILL
		_polity_header.button_down.connect(_toggle_open_close)
		_polity_header.flat = true
		_polity_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_polity_header.size_flags_horizontal = SIZE_FILL
		add_child(_polity_header)
	
	
	func set_vbox(selection_name: StringName, polity_name: StringName, init_open: bool) -> void:
		_next_child_index = 1
		_memory_key = selection_name + polity_name
		if _memory.has(_memory_key):
			_is_open = _memory[_memory_key]
		else:
			_is_open = init_open
		if !polity_name:
			_polity_text = tr(&"LABEL_COMMONS")
		else:
			_polity_text = tr(&"LABEL_TERRITORIAL") + " - " + tr(polity_name)
		if _is_open:
			_polity_header.text = SUPER_OPEN_PREFIX + _polity_text
		else:
			_polity_header.text = SUPER_CLOSED_PREFIX + _polity_text
	
	
	func add_stratum(stratum_name: StringName, hint: StringName, init_open: bool,
			resources_data: Array) -> void:
		var stratum_vbox: StratumVBox
		if _next_child_index < get_child_count():
			stratum_vbox = get_child(_next_child_index)
		else:
			stratum_vbox = StratumVBox.new(_memory)
			add_child(stratum_vbox)
		_next_child_index += 1
		stratum_vbox.set_stratum(stratum_name, hint, resources_data, init_open, _memory_key)
		stratum_vbox.visible = _is_open
	
	
	func finish_strata() -> void: # hide unused
		var i := get_child_count()
		while i > _next_child_index:
			i -= 1
			var stratum_vbox: StratumVBox = get_child(i)
			stratum_vbox.hide()
	
	
	func _toggle_open_close() -> void:
		_is_open = !_is_open
		_memory[_memory_key] = _is_open
		if _is_open:
			_polity_header.text = SUPER_OPEN_PREFIX + _polity_text
		else:
			_polity_header.text = SUPER_CLOSED_PREFIX + _polity_text
		var n_children := get_child_count()
		var i := 1
		while i < n_children:
			var stratum_vbox: StratumVBox = get_child(i)
			stratum_vbox.visible = _is_open
			i += 1



class StratumVBox extends VBoxContainer:
	# add via PolityVBox API
	
	const N_COLUMNS := 5
	
	var _resource_names: Array = IVTableData.tables.resources.name
	
	var _stratum_header := Button.new()
	var _resource_grid := GridContainer.new()
	var _stratum_name: StringName
	var _text_low := tr(&"LABEL_LOW").to_lower()
	var _memory: Dictionary
	var _memory_key: String
	
	
	func _init(memory: Dictionary) -> void:
		_memory = memory
		size_flags_horizontal = SIZE_FILL
		_stratum_header.button_down.connect(_toggle_open_close)
		_stratum_header.flat = true
		_stratum_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_stratum_header.size_flags_horizontal = SIZE_FILL
		add_child(_stratum_header)
		_resource_grid.columns = N_COLUMNS
		_resource_grid.size_flags_horizontal = SIZE_EXPAND_FILL
		add_child(_resource_grid)
	
	
	func set_stratum(stratum_name: StringName, hint: StringName, resources_data: Array,
			init_open: bool, base_memory_key: String) -> void:
		_memory_key = base_memory_key + stratum_name
		_stratum_name = stratum_name
		var is_open := init_open
		if _memory.has(_memory_key):
			is_open = _memory[_memory_key]
		if is_open:
			_stratum_header.text = STRATUM_OPEN_PREFIX + tr(stratum_name)
			_resource_grid.show()
		else:
			_stratum_header.text = STRATUM_CLOSED_PREFIX + tr(stratum_name)
			_resource_grid.hide()
		_stratum_header.tooltip_text = hint
		var n_resources := resources_data.size()
		var n_cells_needed := N_COLUMNS * n_resources
		var n_cells := _resource_grid.get_child_count()
		
		# make cells as needed
		while n_cells < n_cells_needed:
			var label := Label.new()
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			if n_cells % N_COLUMNS == 0:
				label.custom_minimum_size.x = 230
			else:
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_resource_grid.add_child(label)
			n_cells += 1
		
		# resource loop
		var i := 0
		while i < n_resources:
			var resource_data: Array = resources_data[i]
			var resource_type: int = resource_data[0]
			var mean: float = resource_data[1]
			var uncertainty: float = resource_data[2]
			var heterogeneity: float = resource_data[3]
			var deposits: float = resource_data[4]
			var resource_name: StringName = _resource_names[resource_type]
			var precision := 3
			if uncertainty:
				precision = int(mean / (10.0 * uncertainty)) + 1
				if precision > 3:
					precision = 3
			elif mean < 0.0001:
				precision = 1
			elif mean < 0.001:
				precision = 2
			var resource_text := RESOURCE_INDENT + tr(resource_name)
			var mean_text := IVQFormat.number(mean, precision)
			var uncert_text := ""
			if uncertainty:
				uncert_text = "± " + IVQFormat.number(uncertainty, 1)
			var heter_text := ""
			if heterogeneity:
				if heterogeneity < 0.11 * mean:
					heter_text = _text_low
				else:
					heter_text = "± " + IVQFormat.number(heterogeneity, 1)
			var deposits_text := ""
			if deposits:
				deposits_text = IVQFormat.number(deposits, 1)
			
			# set text & show column labels
			var begin_index := i * N_COLUMNS
			var label: Label = _resource_grid.get_child(begin_index)
			label.text = resource_text
			label.show()
			label = _resource_grid.get_child(begin_index + 1)
			label.text = mean_text
			label.show()
			label = _resource_grid.get_child(begin_index + 2)
			label.text = uncert_text
			label.show()
			label = _resource_grid.get_child(begin_index + 3)
			label.text = heter_text
			label.show()
			label = _resource_grid.get_child(begin_index + 4)
			label.text = deposits_text
			label.show()
			i += 1
		
		# hide unused Labels
		i = n_cells
		while i > n_cells_needed:
			i -= 1
			var label: Label = _resource_grid.get_child(i)
			label.hide()
	
	
	func _toggle_open_close() -> void:
		if _resource_grid.visible:
			_stratum_header.text = STRATUM_CLOSED_PREFIX + tr(_stratum_name)
			_resource_grid.hide()
			_memory[_memory_key] = false
		else:
			_stratum_header.text = STRATUM_OPEN_PREFIX + tr(_stratum_name)
			_resource_grid.show()
			_memory[_memory_key] = true

