# tab_resources.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name TabResources
extends MarginContainer

const CONTENT_MARGIN_LEFT := 16
const BODYFLAGS_SPACECRAFT := IVBody.BodyFlags.BODYFLAGS_SPACECRAFT
const MIN_DISCOVERED_BOOST := 1.1 # Don't show unless this much better than mean


var _db_tables := IVTableData.db_tables
var _tables_aux: Dictionary = ThreadsafeGlobal.tables_aux
var _is_extraction_resources: Array[int] = _tables_aux[&"extraction_resources"]
var _n_is_extraction_resources := _is_extraction_resources.size()
var _stratum_names: Array[StringName] = _db_tables[&"stratum_groups"][&"name"]
var _survey_names: Array[StringName] = _db_tables[&"surveys"][&"name"]
var _survey_substring: Array[StringName] = _db_tables[&"surveys"][&"substring"]
var _stratum_types: Dictionary # table name enumeration

var _body_name: StringName
var _selection_name: StringName
var _fold_memory: Dictionary[StringName, bool] = {} # keep folded states

@onready var _strata_vbox: VBoxContainer = %StrataVBox
@onready var _missing_label: Label = $MissingLabel



func _ready() -> void:
	_stratum_types = IVTableData.enumeration_dicts[&"strata"] # FIXME: why here?


func refresh() -> void:
	if !_body_name or !_selection_name:
		return
	MainThreadGlobal.call_ai_thread(_get_ai_data.bind(_body_name, _selection_name))


func update_selection(body_name: StringName, selection_name: StringName) -> void:
	assert(body_name and selection_name)
	if _body_name != body_name or _selection_name != selection_name:
		_body_name = body_name
		_selection_name = selection_name
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
	
	if !body_interface.has_strata():
		var is_unknown := not body_interface.body_flags & BODYFLAGS_SPACECRAFT
		_update_no_resources.call_deferred(is_unknown)
		return
	
	var stratum_polities := []
	
	var n_strata := body_interface.get_n_strata()

	for i in n_strata:
		var stratum_polity := body_interface.get_stratum_polity(i)
		if polity_name and stratum_polity and polity_name != stratum_polity:
			continue
		if !stratum_polities.has(stratum_polity):
			stratum_polities.append(stratum_polity)
		var masses := body_interface.get_stratum_masses(i)
		var total_mass := body_interface.get_stratum_total_mass(i)
		var survey_type := body_interface.get_stratum_survey_type(i)
		
		var resources_data := []
		# Stratum resource indexes must be converted to resource_type.
		for j in _n_is_extraction_resources:
			var mass: float = masses[j]
			if mass == 0.0:
				continue
			var resource_type: int = _is_extraction_resources[j]
			var distribution_data := body_interface.get_stratum_resource_data(i, resource_type)
			var resource_data := [resource_type, distribution_data]
			resources_data.append(resource_data)
		
		resources_data.sort_custom(_sort_resources)
		
		var survey_name: StringName = _survey_substring[survey_type]
		if !survey_name:
			survey_name = _survey_names[survey_type]
		
		resources_data.append(total_mass)
		resources_data.append(body_interface.get_stratum_density(i))
		resources_data.append(body_interface.get_compostion_thickness(i))
		resources_data.append(body_interface.get_compostion_body_radius(i))
		resources_data.append(survey_name)
		resources_data.append(body_interface.get_stratum_stratum_type(i))
		resources_data.append(stratum_polity)
		
		data.append(resources_data)
	
	_update_display.call_deferred(selection_name, stratum_polities, data)


func _sort_resources(a: Array, b: Array) -> bool:
	# TODO: Remove sort override infrastructure if we don't really want it...
	#var a_override: int = _resource_sort_overrides[a[0]]
	#var b_override: int = _resource_sort_overrides[b[0]]
	#if a_override != b_override:
		#return a_override > b_override
	
	# sort on base_deposits
	return a[1][4] > b[1][4]

# *****************************************************************************
# Main thread !!!!

func _update_display(selection_name: StringName, stratum_polities: Array, data: Array) -> void:

	# TODO: Sort stratum_polities in some sensible way
	var n_polities := stratum_polities.size()
	var is_single_polity := n_polities == 1
	var n_polity_foldables := _strata_vbox.get_child_count()

	# add PolityFoldables as needed
	while n_polity_foldables < n_polities:
		var polity_foldable := PolityFoldable.new(_fold_memory)
		_strata_vbox.add_child(polity_foldable)
		n_polity_foldables += 1

	# set PolityFoldables we'll use & hide extras
	var i := 0
	while i < n_polities:
		var polity_foldable: PolityFoldable = _strata_vbox.get_child(i)
		var polity_name: StringName = stratum_polities[i]
		polity_foldable.set_polity(selection_name, polity_name, is_single_polity)
		polity_foldable.show()
		i += 1
	while i < n_polity_foldables:
		var polity_foldable: PolityFoldable = _strata_vbox.get_child(i)
		polity_foldable.hide()
		i += 1

	# add strata
	var n_strata := data.size()
	i = 0
	while i < n_strata:
		var resources_data: Array = data[i]
		var stratum_polity: StringName = resources_data.pop_back()
		var stratum_group: int = resources_data.pop_back()
		var survey_name: StringName = resources_data.pop_back()
		var body_radius: float = resources_data.pop_back() # FIXME: outer radius
		var thickness: float = resources_data.pop_back()
		var density: float = resources_data.pop_back()
		var total_mass: float = resources_data.pop_back()
		# resources_data now in correct form for add_stratum()

		var stratum_str := tr(_stratum_names[stratum_group]) + " ("
		if body_radius != thickness:
			stratum_str += IVQFormat.dynamic_unit(thickness, &"length_m_km", 2) + "; "
		stratum_str += IVQFormat.fixed_unit(density, &"g/cm^3", 2) + "; "
		stratum_str += IVQFormat.fixed_unit(total_mass, &"t", 2) + "; "
		stratum_str += tr(survey_name).to_lower() + ")"

		var polity_index := stratum_polities.find(stratum_polity)
		var polity_foldable: PolityFoldable = _strata_vbox.get_child(polity_index)
		polity_foldable.add_stratum(stratum_str, resources_data)
		i += 1

	i = 0
	while i < n_polities:
		var polity_foldable: PolityFoldable = _strata_vbox.get_child(i)
		polity_foldable.finish_strata()
		i += 1

	_missing_label.hide()
	_strata_vbox.show()



func _update_no_resources(is_unknown := true) -> void:
	_strata_vbox.hide()
	_missing_label.text = (&"LABEL_UNKNOWN_RESOURCES_PARENTHESIS" if is_unknown
			else &"LABEL_NO_RESOURCES_PARENTHESIS")
	_missing_label.show()



class PolityFoldable extends FoldableContainer:
	# hide when not in use

	var _content_vbox := VBoxContainer.new()
	var _fold_memory: Dictionary[StringName, bool]
	var _memory_key: StringName
	var _next_child_index := 0


	func _init(fold_memory: Dictionary[StringName, bool]) -> void:
		_fold_memory = fold_memory
		size_flags_horizontal = SIZE_FILL
		var margin := MarginContainer.new()
		margin.add_theme_constant_override(&"margin_left", CONTENT_MARGIN_LEFT)
		margin.size_flags_horizontal = SIZE_FILL
		_content_vbox.size_flags_horizontal = SIZE_FILL
		margin.add_child(_content_vbox)
		add_child(margin)
		folding_changed.connect(_on_folding_changed)


	func set_polity(selection_name: StringName, polity_name: StringName,
			is_single_polity: bool) -> void:
		_next_child_index = 0
		_memory_key = StringName(selection_name + polity_name)

		if !polity_name:
			title = tr(&"LABEL_COMMONS")
		else:
			title = tr(&"LABEL_TERRITORIAL") + " - " + tr(polity_name)

		folded = _fold_memory.get(_memory_key, !is_single_polity)


	func add_stratum(stratum_str: String, resources_data: Array) -> void:
		var stratum_foldable: StratumFoldable
		if _next_child_index < _content_vbox.get_child_count():
			stratum_foldable = _content_vbox.get_child(_next_child_index)
		else:
			stratum_foldable = StratumFoldable.new(_fold_memory)
			_content_vbox.add_child(stratum_foldable)
		_next_child_index += 1
		stratum_foldable.set_stratum(stratum_str, resources_data, _memory_key)
		stratum_foldable.show()


	func finish_strata() -> void: # hide unused
		var i := _content_vbox.get_child_count()
		while i > _next_child_index:
			i -= 1
			var stratum_foldable: StratumFoldable = _content_vbox.get_child(i)
			stratum_foldable.hide()


	func _on_folding_changed(is_folded_: bool) -> void:
		_fold_memory[_memory_key] = is_folded_



class StratumFoldable extends FoldableContainer:
	# add via PolityFoldable API

	const N_COLUMNS := 4

	var _resource_names: Array[StringName] = IVTableData.db_tables[&"resources"][&"name"]

	var _resource_grid := GridContainer.new()
	var _variance_label: Label
	var _deposits_label: Label
	var _fold_memory: Dictionary[StringName, bool]
	var _memory_key: StringName


	func _init(fold_memory: Dictionary[StringName, bool]) -> void:
		_fold_memory = fold_memory
		size_flags_horizontal = SIZE_FILL
		var margin := MarginContainer.new()
		margin.add_theme_constant_override(&"margin_left", CONTENT_MARGIN_LEFT)
		margin.size_flags_horizontal = SIZE_FILL
		_resource_grid.columns = N_COLUMNS
		_resource_grid.size_flags_horizontal = SIZE_EXPAND_FILL
		margin.add_child(_resource_grid)
		add_child(margin)
		folding_changed.connect(_on_folding_changed)


	func set_stratum(stratum_str: String, resources_data: Array,
			base_memory_key: StringName) -> void:
		_memory_key = StringName(base_memory_key + stratum_str)
		title = stratum_str
		folded = _fold_memory.get(_memory_key, true)

		var n_resources := resources_data.size()
		var n_cells_needed := N_COLUMNS * (n_resources + 1)
		var n_cells := _resource_grid.get_child_count()
		var has_dispersion := false
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
			var resource_name := _resource_names[resource_type]
			var distribution_data: Array[float] = resource_data[1]
			var mean := distribution_data[0] * 100
			var mean_sd := distribution_data[1] * 100
			var dispersion := distribution_data[2]
			var dispersion_sd := distribution_data[3]
			var discovered := distribution_data[5] * 100
			if discovered < mean * MIN_DISCOVERED_BOOST:
				discovered = 0.0

			# TODO: Error format (1.0 ± 0.2)e-6

			var resource_text := tr(resource_name)
			var mean_text := ""
			if mean >= 90:
				mean_text = String.num(mean, 1)
				if mean_sd >= 0.05:
					mean_text += " ± " + IVQFormat.number(mean_sd, 1)
			elif mean >= 0.01:
				mean_text = IVQFormat.number(mean, 2)
				if mean_sd >= 0.01 * mean:
					mean_text += " ± " + IVQFormat.number(mean_sd, 1)
			else:
				mean_text = IVQFormat.number(mean, 1)
				if mean_sd >= 0.1 * mean:
					mean_text += " ± " + IVQFormat.number(mean_sd, 1)
			var dispersion_text := ""
			if dispersion >= 0.05:
				dispersion_text = String.num(dispersion, 1) + " ± " + String.num(dispersion_sd, 1)
				has_dispersion = true
			var deposits_text := ""
			if discovered:
				deposits_text = IVQFormat.number(discovered, 2)
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
			label.text = dispersion_text
			label.show()
			label = _resource_grid.get_child(resource_index + 3)
			label.text = deposits_text
			label.show()
			i += 1

		# show/hide dispersion & deposits headers
		_variance_label.text = &"LABEL_DISPERSION_LOG" if has_dispersion else &""
		_deposits_label.text = &"LABEL_DISCOVERED_PERCENT" if has_deposit else &""

		# hide unused Labels
		i = n_cells
		while i > n_cells_needed:
			i -= 1
			var label: Label = _resource_grid.get_child(i)
			label.hide()


	func _on_folding_changed(is_folded_: bool) -> void:
		_fold_memory[_memory_key] = is_folded_
