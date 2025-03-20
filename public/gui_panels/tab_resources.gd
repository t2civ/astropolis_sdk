# tab_resources.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name TabResources
extends MarginContainer


const SUPER_OPEN_PREFIX := "\u2304 "
const SUPER_CLOSED_PREFIX := "> "
const STRATUM_OPEN_PREFIX := "  \u2304 "
const STRATUM_CLOSED_PREFIX := "  > "
const RESOURCE_INDENT := "        "
const BODYFLAGS_SPACECRAFT := IVBody.BodyFlags.BODYFLAGS_SPACECRAFT
const LENGTH_M_KM := IVQFormat.DynamicUnitType.LENGTH_M_KM


var _tables: Dictionary = IVTableData.tables
var _tables_aux: Dictionary = ThreadsafeGlobal.tables_aux
var _is_extraction_resources: Array[int] = _tables_aux[&"extraction_resources"]
var _n_is_extraction_resources := _is_extraction_resources.size()
var _resource_sort_overrides: Array[int] = _tables[&"resources"][&"sort_override"]
var _init_opens: Array[bool] = _tables[&"compositions"][&"init_open"]
var _hide_variances: Array[bool] = _tables[&"resources"][&"hide_variances"]
var _stratum_names: Array[StringName] = _tables[&"strata"][&"name"]
var _survey_names: Array[StringName] = _tables[&"surveys"][&"name"]
var _survey_substring: Array[StringName] = _tables[&"surveys"][&"substring"]
var _composition_types: Dictionary # table name enumeration

var _body_name: StringName
var _selection_name: StringName
var _memory := {} # keep open/closed states

@onready var _compositions_vbox: VBoxContainer = %CompositionsVBox
@onready var _missing_label: Label = $MissingLabel



func _ready() -> void:
	_composition_types = IVTableData.enumeration_dicts[&"compositions"] # FIXME: why here?


func refresh() -> void:
	if !_body_name or !_selection_name:
		return
	MainThreadGlobal.call_ai_thread(_get_ai_data.bind(_body_name, _selection_name))


func update_selection(body_name: StringName, selection_name: StringName) -> void:
	assert(body_name and selection_name)
	if _body_name != body_name or _selection_name != _selection_name:
		_body_name = body_name
		_selection_name = _selection_name
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
	
	if !body_interface.has_compositions():
		var is_unknown := not body_interface.body_flags & BODYFLAGS_SPACECRAFT
		_update_no_resources.call_deferred(is_unknown)
		return
	
	var composition_polities := []
	var open_at_init: Array[bool] = []
	
	var n_compositions := body_interface.get_n_compositions()

	for i in n_compositions:
		var composition_polity := body_interface.get_composition_polity(i)
		if polity_name and composition_polity and polity_name != composition_polity:
			continue
		var init_open: bool
		if !composition_polities.has(composition_polity):
			composition_polities.append(composition_polity)
			init_open = polity_name == composition_polity # "" == "" at body for commons
			open_at_init.append(init_open)
		var masses := body_interface.get_composition_masses(i)
		var variances := body_interface.get_composition_variances(i)
		var total_mass := body_interface.get_composition_total_mass(i)
		var survey_type := body_interface.get_composition_survey_type(i)
		
		var resources_data := []
		# Composition resource indexes must be converted to resource_type.
		for j in _n_is_extraction_resources:
			var mass: float = masses[j]
			if mass == 0.0:
				continue
			var resource_type: int = _is_extraction_resources[j]
			var mean := 100.0 * mass / total_mass # mass percent
			var error := 0.0
			var variance := 0.0
			var deposits := 0.0
			if !_hide_variances[resource_type]:
				error = 100.0 * body_interface.get_composition_mass_error_fraction(
						i, resource_type)
				if variances[j]:
					variance = 100.0 * body_interface.get_composition_variance_fraction(
							i, resource_type)
					if variance:
						deposits = 100.0 * body_interface.get_composition_deposit_fraction(
								i, resource_type, true)
			
			var resource_data := [resource_type, mean, error, variance, deposits]
			resources_data.append(resource_data)
		
		resources_data.sort_custom(_sort_resources)
		
		var survey_name: StringName = _survey_substring[survey_type]
		if !survey_name:
			survey_name = _survey_names[survey_type]
		
		init_open = true
		var composition_name := body_interface.get_composition_name(i)
		var composition_type: int = _composition_types.get(composition_name, -1)
		if composition_type != -1:
			init_open = _init_opens[composition_type]
		
		resources_data.append(total_mass)
		resources_data.append(body_interface.get_composition_density(i))
		resources_data.append(body_interface.get_compostion_thickness(i))
		resources_data.append(body_interface.get_compostion_body_radius(i))
		resources_data.append(survey_name)
		resources_data.append(body_interface.get_composition_stratum_type(i))
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

func _update_display(selection_name: StringName, composition_polities: Array,
		open_at_init: Array[bool], data: Array) -> void:

	# TODO: Sort composition_polities in some sensible way
	var n_polities := composition_polities.size()
	var n_polity_vboxes := _compositions_vbox.get_child_count()
	
	# add OwnerVBoxes as needed
	while n_polity_vboxes < n_polities:
		var polity_vbox := PolityVBox.new(_memory)
		_compositions_vbox.add_child(polity_vbox)
		n_polity_vboxes += 1

	# set OwnerVBoxes we'll use & hide extras
	var i := 0
	while i < n_polities:
		var polity_vbox: PolityVBox = _compositions_vbox.get_child(i)
		var polity_name: StringName = composition_polities[i]
		var init_open: bool = open_at_init[i]
		polity_vbox.set_vbox(selection_name, polity_name, init_open)
		polity_vbox.show()
		i += 1
	while i < n_polity_vboxes:
		var polity_vbox: PolityVBox = _compositions_vbox.get_child(i)
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
		var survey_name: StringName = resources_data.pop_back()
		var body_radius: float = resources_data.pop_back() # FIXME: outer radius
		var thickness: float = resources_data.pop_back()
		var density: float = resources_data.pop_back()
		var total_mass: float = resources_data.pop_back()
		# resources_data now in correct form for add_stratum()
		
		var stratum_str := tr(_stratum_names[stratum_type]) + " ("
		if body_radius != thickness:
			stratum_str += IVQFormat.dynamic_unit(thickness, LENGTH_M_KM, 2) + "; "
		stratum_str += IVQFormat.fixed_unit(density, &"g/cm^3", 2) + "; "
		stratum_str += IVQFormat.fixed_unit(total_mass, &"t", 2) + "; "
		stratum_str += tr(survey_name).to_lower() + ")"
		
		var polity_index := composition_polities.find(composition_polity)
		var polity_vbox: PolityVBox = _compositions_vbox.get_child(polity_index)
		polity_vbox.add_stratum(stratum_str, init_open, resources_data)
		i += 1
	
	i = 0
	while i < n_polities:
		var polity_vbox: PolityVBox = _compositions_vbox.get_child(i)
		polity_vbox.finish_strata()
		i += 1
	
	_missing_label.hide()
	_compositions_vbox.show()



func _update_no_resources(is_unknown := true) -> void:
	_compositions_vbox.hide()
	_missing_label.text = (&"LABEL_UNKNOWN_RESOURCES_PARENTHESIS" if is_unknown
			else &"LABEL_NO_RESOURCES_PARENTHESIS")
	_missing_label.show()



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
	
	
	func add_stratum(stratum_str: String, init_open: bool, resources_data: Array) -> void:
		var stratum_vbox: StratumVBox
		if _next_child_index < get_child_count():
			stratum_vbox = get_child(_next_child_index)
		else:
			stratum_vbox = StratumVBox.new(_memory)
			add_child(stratum_vbox)
		_next_child_index += 1
		stratum_vbox.set_stratum(stratum_str, resources_data, init_open, _memory_key)
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
		var i := 1
		while i < _next_child_index:
			var stratum_vbox: StratumVBox = get_child(i)
			stratum_vbox.visible = _is_open
			i += 1



class StratumVBox extends VBoxContainer:
	# add via PolityVBox API
	
	const N_COLUMNS := 4
	
	var _resource_names: Array[StringName] = IVTableData[&"tables"][&"resources"][&"name"]
	
	var _stratum_header := Button.new()
	var _resource_grid := GridContainer.new()
	var _stratum_str: String
	var _variance_label: Label
	var _deposits_label: Label
	var _memory: Dictionary
	var _memory_key: String
	
	
	func _init(memory: Dictionary) -> void:
		_memory = memory
		size_flags_horizontal = SIZE_FILL
		_stratum_header.button_down.connect(_toggle_open_close)
		_stratum_header.flat = true
		_stratum_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_stratum_header.size_flags_horizontal = SIZE_EXPAND_FILL
		add_child(_stratum_header)
		_resource_grid.columns = N_COLUMNS
		_resource_grid.size_flags_horizontal = SIZE_EXPAND_FILL
		add_child(_resource_grid)
	
	
	func set_stratum(stratum_str: String, resources_data: Array, init_open: bool,
			base_memory_key: String) -> void:
		_memory_key = base_memory_key + stratum_str
		_stratum_str = stratum_str
		var is_open := init_open
		if _memory.has(_memory_key):
			is_open = _memory[_memory_key]
		if is_open:
			_stratum_header.text = STRATUM_OPEN_PREFIX + stratum_str
			_resource_grid.show()
		else:
			_stratum_header.text = STRATUM_CLOSED_PREFIX + stratum_str
			_resource_grid.hide()
		var n_resources := resources_data.size()
		var n_cells_needed := N_COLUMNS * (n_resources + 1)
		var n_cells := _resource_grid.get_child_count()
		var has_varance := false
		var has_deposit := false
		
		# make cells as needed
		while n_cells < n_cells_needed:
			var label := Label.new()
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			if n_cells % N_COLUMNS == 0:
				label.custom_minimum_size.x = 230
			else:
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if n_cells == 1:
				label.text = &"LABEL_MEAN_PERCENT"
			elif n_cells == 2:
				_variance_label = label
			elif n_cells == 3:
				_deposits_label = label
			_resource_grid.add_child(label)
			n_cells += 1
		
		# resource loop
		var i := 0
		while i < n_resources:
			var resource_data: Array = resources_data[i]
			var resource_type: int = resource_data[0]
			var mean: float = resource_data[1]
			var error: float = resource_data[2]
			var variance: float = resource_data[3]
			var deposits: float = resource_data[4]
			var resource_name := _resource_names[resource_type]
			var precision := 2
			if error:
				precision = int(mean / (10.0 * error)) + 1
				if precision > 2:
					precision = 2
			elif mean < 0.0001:
				precision = 1
			var resource_text := RESOURCE_INDENT + tr(resource_name)
			var mean_text := IVQFormat.number(mean, precision)
			if error:
				mean_text += " ± " + IVQFormat.number(error, 1)
			var variance_text := ""
			if variance and variance > 0.11 * mean:
				variance_text = IVQFormat.number(variance, 1)
				has_varance = true
			var deposits_text := ""
			if deposits:
				deposits_text = IVQFormat.number(deposits, 1)
				has_deposit = true
			
			# set resource texts
			var resource_index := N_COLUMNS * (i + 1)
			var label: Label = _resource_grid.get_child(resource_index)
			label.text = resource_text
			label.show()
			label = _resource_grid.get_child(resource_index + 1)
			label.text = mean_text
			label.show()
			label = _resource_grid.get_child(resource_index + 2)
			label.text = variance_text
			label.show()
			label = _resource_grid.get_child(resource_index + 3)
			label.text = deposits_text
			label.show()
			i += 1
		
		# show/hide variance & deposits headers
		_variance_label.text = &"LABEL_VARIANCE_PERCENT" if has_varance else &""
		_deposits_label.text = &"LABEL_DEPOSITS_PERCENT" if has_deposit else &""
		
		# hide unused Labels
		i = n_cells
		while i > n_cells_needed:
			i -= 1
			var label: Label = _resource_grid.get_child(i)
			label.hide()
	
	
	func _toggle_open_close() -> void:
		if _resource_grid.visible:
			_stratum_header.text = STRATUM_CLOSED_PREFIX + _stratum_str
			_resource_grid.hide()
			_memory[_memory_key] = false
		else:
			_stratum_header.text = STRATUM_OPEN_PREFIX + _stratum_str
			_resource_grid.show()
			_memory[_memory_key] = true
