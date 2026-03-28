# itab_operations.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ITabOperations
extends MarginContainer
const SCENE := "res://public/ui/itab_operations.tscn"

# Tabs follow row enumerations in op_classes.tsv.
# TODO: complete localizations

enum {
	TAB_ENERGY,
	TAB_EXTRACTION,
	TAB_REFINING,
	TAB_CONVERSION,
	TAB_MANUFACTURING,
	TAB_BIOMES,
	TAB_SERVICES,
}

enum {
	GROUP_OPEN,
	GROUP_CLOSED,
	GROUP_SINGULAR,
}

const PROCESS_GROUP_RENEWABLE := Enums.ProcessGroup.PROCESS_GROUP_RENEWABLE
const PROCESS_GROUP_CONVERSION := Enums.ProcessGroup.PROCESS_GROUP_CONVERSION
const PROCESS_GROUP_EXTRACTION := Enums.ProcessGroup.PROCESS_GROUP_EXTRACTION

const N_COLUMNS := 7

const SUBGROUP_INDENT := 17

const PERSIST_MODE := IVGlobal.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = [
	&"current_tab",
	&"_on_ready_tab",
]

# persisted
var current_tab := 0
var _on_ready_tab := 0

# not persisted
var base_column_width := 55.0

var headers_texts: Array[Array] = [
	["Capacity\n(%)", "Power\n(MW)", "Fuel\n(-t/h)", "Revenue\n($M/y)", "Margin\n(gr; %)"],
	["Capacity\n(%)", "Power\n(-MW)", "Rate\n(t/h)", "Revenue\n($M/y)", "Margin\n(gr; %)"],
	["Capacity\n(%)", "Power\n(-MW)", "Rate\n(t/h)", "Revenue\n($M/y)", "Margin\n(gr; %)"],
	["Capacity\n(%)", "Power\n(-MW)", "Rate\n(t/h)", "Revenue\n($M/y)", "Margin\n(gr; %)"],
	["Capacity\n(%)", "Power\n(-MW)", "Rate\n(t/h)", "Revenue\n($M/y)", "Margin\n(gr; %)"],
	["Capacity\n(%)", "Power\n(-MW)", "Bioprod\n(t/h)", "Revenue\n($M/y)", "Margin\n(gr; %)"],
	["Capacity\n(%)", "Power\n(-MW)", "Compute\n(Pflop/s)", "Revenue\n($M/y)", "Margin\n(gr; %)"],
]


var _unit_multipliers := IVUnits.unit_multipliers
var _selection_manager: AstroSelectionManager
var _suppress_tab_listener := true

#var _name_column_width := 250.0 # TODO: resize on GUI resize (also in RowItem)

# table indexing
var _db_tables := IVTableData.db_tables
var _tables_aux: Dictionary = ThreadsafeGlobal.tables_aux
var _operation_names: Array[StringName] = _db_tables[&"operations"][&"name"]
var _operation_sublabels: Array[StringName] = _db_tables[&"operations"][&"sublabel"]
var _operation_process_groups: Array[int] = _db_tables[&"operations"][&"process_group"]
var _op_group_names: Array[StringName] = _db_tables[&"op_groups"][&"name"]
var _op_group_process_groups: Array[int] = _db_tables[&"op_groups"][&"process_group"]
var _op_group_show_singular: Array[bool] = _db_tables[&"op_groups"][&"show_singular"]
var _op_classes_op_groups: Array[Array] = _tables_aux[&"op_classes_op_groups"]
var _op_groups_operations: Array[Array] = _tables_aux[&"op_groups_operations"]

var _revenue_hdrs: Array[Label] = []
var _margin_hdrs: Array[Label] = []

var _fold_icon_substitute := MeshTexture.new()

@warning_ignore("unsafe_property_access")
@onready var _memory: Dictionary = get_parent().memory # open states
@onready var _no_ops_label: Label = $NoOpsLabel
@onready var _tab_container: TabContainer = $TabContainer
@onready var _headers: Array[HBoxContainer] = [
	%EnergyHdrs,
	%ExtractionHdrs,
	%RefiningHdrs,
	%ConversionHdrs,
	%ManufacturingHdrs,
	%BiomesHdrs,
	%ServicesHdrs,
]

@onready var _vboxes: Array[VBoxContainer] = [
	$"%EnergyVBox",
	$"%ExtractionVBox",
	$"%RefiningVBox",
	$"%ConversionVBox",
	$"%ManufacturingVBox",
	$"%BiomesVBox",
	$"%ServicesVBox",
]




func _ready() -> void:
	IVStateManager.about_to_free_procedural_nodes.connect(_clear)
	visibility_changed.connect(_update_tab)
	_selection_manager = IVSelectionManager.get_selection_manager(self)
	_selection_manager.selection_changed.connect(_update_tab)
	_tab_container.tab_changed.connect(_select_tab)
	# rename tabs for localization or abreviation
	$TabContainer/Energy.name = &"TAB_OPS_ENERGY"
	$TabContainer/Extraction.name = &"TAB_OPS_EXTRACTION"
	$TabContainer/Refining.name = &"TAB_OPS_REFINING"
	$TabContainer/Conversion.name = &"TAB_OPS_CONVERSION"
	$TabContainer/Manufacturing.name = &"TAB_OPS_MANUFACTURING"
	$TabContainer/Biomes.name = &"TAB_OPS_BIOMES"
	$TabContainer/Services.name = &"TAB_OPS_SERVICES"
	
	_revenue_hdrs.resize(7)
	_margin_hdrs.resize(7)
	
	for tab in 7:
		var header_texts := headers_texts[tab]
		var tab_headers := _headers[tab]
		tab_headers.add_spacer(true)
		for label_column in 5:
			var label := Label.new()
			tab_headers.add_child(label)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.text = header_texts[label_column]
			if label_column == 3:
				_revenue_hdrs[tab] = label
			elif label_column == 4:
				_margin_hdrs[tab] = label
		var spacer := Control.new()
		spacer.size_flags_horizontal = SIZE_SHRINK_CENTER
		tab_headers.add_child(spacer)
	
	_fold_icon_substitute.image_size.x = 16
	
	var gui_size: int = IVSettingsManager.get_setting(&"gui_size")
	_resize(gui_size)
	IVSettingsManager.changed.connect(_settings_listener)
	
	_tab_container.set_current_tab(_on_ready_tab)
	_suppress_tab_listener = false
	_update_tab()


func _clear() -> void:
	if _selection_manager:
		_selection_manager.selection_changed.disconnect(_update_tab)
		_selection_manager = null
	visibility_changed.disconnect(_update_tab)
	_tab_container.tab_changed.disconnect(_select_tab)


func timer_update() -> void:
	_update_tab()


func _select_tab(tab: int) -> void:
	if !_suppress_tab_listener:
		_on_ready_tab = tab
	current_tab = tab
	_update_tab()


func _update_tab(_dummy := false) -> void:
	if !visible or !IVStateManager.running:
		return
	var target_name := _selection_manager.get_name()
	
	
	if MainThreadGlobal.has_development(target_name):
		MainThreadGlobal.call_ai_thread(_get_ai_data.bind(target_name))
	else:
		_update_no_operations()


func _update_no_operations() -> void:
	_tab_container.hide()
	_no_ops_label.show()


func _resize(gui_size: int) -> void:
	const SCROLL_CORRECTION := 7.0
	var column_width := base_column_width * IVCoreSettings.gui_size_multipliers[gui_size]
	for tab in _headers.size():
		var tab_headers := _headers[tab]
		for i in 6:
			var control: Control = tab_headers.get_child(i + 1)
			var width := column_width if i < 5 else column_width + SCROLL_CORRECTION
			control.custom_minimum_size.x = width


func _settings_listener(setting: StringName, value: Variant) -> void:
	if setting == &"gui_size":
		var gui_size: int = value
		_resize(gui_size)


# *****************************************************************************
# AI thread !!!!

func _get_ai_data(target_name: StringName) -> void:
	var data := []
	var interface := Interface.get_interface_by_name(target_name)
	if !interface:
		_update_no_operations.call_deferred()
		return
	
	var tab := current_tab
	var operations := interface.get_operations()
	var has_financials := operations.has_financials()
	
	var op_groups: Array[int] = _op_classes_op_groups[tab]
	var n_op_groups := 0 # that we can have
	
	for op_group in op_groups:
		
		if not operations.is_of_interest_group(op_group):
			continue
		
		n_op_groups += 1
		
		var utilization := operations.get_group_utilization(op_group)
		var electricity := operations.get_group_electricity(op_group)
		electricity /= _unit_multipliers[&"MW"]
		var flow := NAN
		var revenue := operations.get_group_revenue(op_group)
		revenue /= _unit_multipliers[&"$M/y"]
		var margin := operations.get_group_gross_margin(op_group)
		
		match tab:
			TAB_ENERGY:
				if _op_group_process_groups[op_group] == PROCESS_GROUP_CONVERSION:
					flow = operations.get_group_fuel_rate(op_group)
					flow /= _unit_multipliers[&"t/h"]
			TAB_EXTRACTION:
				electricity = -electricity
				flow = operations.get_group_extraction_rate(op_group)
				flow /= _unit_multipliers[&"t/h"]
			TAB_REFINING, TAB_CONVERSION, TAB_MANUFACTURING:
				electricity = -electricity
				flow = operations.get_group_mass_conversion_rate(op_group)
				flow /= _unit_multipliers[&"t/h"]
			TAB_BIOMES:
				electricity = -electricity
			TAB_SERVICES:
				electricity = -electricity
				flow = operations.get_group_computation(op_group)
				flow /= _unit_multipliers[&"Pflop/s"]
		
		var group_data := [
			_op_group_names[op_group],
			utilization,
			electricity,
			flow,
			revenue,
			margin,
		]
		data.append(group_data)
		
		var operations_data := []
		data.append(operations_data)
		
		var operation_types: Array[int] = _op_groups_operations[op_group]
		var n_ops := operation_types.size()
		if n_ops < 2 and !_op_group_show_singular[op_group]:
			continue
		
		for operation_type in operation_types:
			
			utilization = operations.get_utilization(operation_type)
			electricity = operations.get_electricity_rate(operation_type)
			electricity /= _unit_multipliers[&"MW"]
			flow = NAN
			revenue = operations.get_revenue_rate(operation_type)
			revenue /= _unit_multipliers[&"$M/y"]
			margin = operations.get_gross_margin(operation_type)
			
			match tab:
				TAB_ENERGY:
					if _operation_process_groups[operation_type] == PROCESS_GROUP_CONVERSION:
						flow = operations.get_fuel_rate(operation_type)
						flow /= _unit_multipliers[&"t/h"]
				TAB_EXTRACTION:
					electricity = -electricity
					flow = operations.get_extraction_rate(operation_type)
					flow /= _unit_multipliers[&"t/h"]
				TAB_REFINING, TAB_CONVERSION, TAB_MANUFACTURING:
					electricity = -electricity
					flow = operations.get_mass_conversion_rate(operation_type)
					flow /= _unit_multipliers[&"t/h"]
				TAB_BIOMES:
					electricity = -electricity
				TAB_SERVICES:
					electricity = -electricity
					flow = operations.get_computation(operation_type)
					flow /= _unit_multipliers[&"Pflop/s"]
			
			var sublabel := _operation_sublabels[operation_type]
			if !sublabel:
				sublabel = _operation_names[operation_type]
			
			var operation_data := [
				sublabel,
				utilization,
				electricity,
				flow,
				revenue,
				margin,
			]
			
			operations_data.append(operation_data)
	
	_update_tab_display.call_deferred(target_name, tab, n_op_groups, has_financials, data)


# *****************************************************************************
# Main thread !!!!


func _update_tab_display(target_name: StringName, tab: int, n_op_groups: int, has_financials: bool,
		data: Array) -> void:
	# TODO: if no op_groups, show something like, "(No Energy Operations)"
	
	# header changes
	var revenue_hdr: Label = _revenue_hdrs[tab]
	var margin_hdr: Label = _margin_hdrs[tab]
	revenue_hdr.text = "Revenue\n($M/y)" if has_financials else ""
	margin_hdr.text = "Margin\n(% gr)" if has_financials else ""
	
	# make GroupFoldables as needed
	var vbox: VBoxContainer = _vboxes[tab]
	var n_children := vbox.get_child_count()
	while n_children < n_op_groups:
		vbox.add_child(GroupFoldable.new(_memory, base_column_width, _fold_icon_substitute))
		n_children += 1
	
	# set and show GroupFoldables
	var i := 0
	while i < n_op_groups:
		var group_data: Array = data[i * 2]
		var operations_data: Array = data[i * 2 + 1]
		var group_box: GroupFoldable = vbox.get_child(i)
		group_box.set_group_item(target_name, group_data, operations_data)
		group_box.show()
		i += 1
	
	# hide unused
	while i < n_children:
		var group_box: GroupFoldable = vbox.get_child(i)
		group_box.hide()
		i += 1
	
	_no_ops_label.hide()
	_tab_container.show()



class GroupFoldable extends FoldableContainer:
	# Reused container for RowItems
	
	var _foldable_vbox := VBoxContainer.new()
	var _group_hdr: RowItem
	var _is_singular: bool
	var _memory: Dictionary
	var _base_column_width: float
	var _memory_key: String
	var _fold_icon_substitute: MeshTexture
	
	
	func _init(memory: Dictionary, base_column_width: float, fold_icon_substitute: MeshTexture
			) -> void:
		_memory = memory
		_base_column_width = base_column_width
		_fold_icon_substitute = fold_icon_substitute
		_group_hdr = RowItem.new(true, base_column_width)
		size_flags_horizontal = SIZE_FILL
		add_child(_foldable_vbox)
		add_title_bar_control(_group_hdr)
		folding_changed.connect(_on_folding_changed)
	
	
	func set_group_item(_target_name: StringName, group_data: Array, operations_data: Array
			) -> void:
		_memory_key = group_data[0]
		folded = _memory.get(_memory_key, true)
		
		var group_state: int
		if operations_data:
			group_state = GROUP_OPEN if !folded else GROUP_CLOSED
			remove_theme_icon_override(&"folded_arrow")
			_is_singular = false
		else:
			group_state = GROUP_SINGULAR
			add_theme_icon_override(&"folded_arrow", _fold_icon_substitute)
			_is_singular = true
		var row_name: StringName = group_data[0]
		title = row_name
		_group_hdr.set_row(group_data, group_state)
		
		var n_ops := operations_data.size()
		var n_children := _foldable_vbox.get_child_count()
		var n_children_needed := n_ops
		while n_children < n_children_needed:
			_foldable_vbox.add_child(RowItem.new(false, _base_column_width))
			n_children += 1
		var i := 0
		while i < n_ops:
			var ops_row: RowItem = _foldable_vbox.get_child(i)
			var ops_datum: Array = operations_data[i]
			ops_row.set_row(ops_datum)
			ops_row.show()
			i += 1
		
		# hide unused
		i = n_ops
		while i < n_children:
			var ops_row: RowItem = _foldable_vbox.get_child(i)
			ops_row.hide()
			i += 1
	
	
	func _on_folding_changed(is_folded_: bool) -> void:
		if !_is_singular:
			_memory[_memory_key] = is_folded_
			return
		if !is_folded_:
			fold()



class RowItem extends HBoxContainer:
	
	var ops_label: Label # if _is_group == false
	var utilization_label := Label.new()
	var power_label := Label.new()
	var flow_label := Label.new()
	var revenue_label := Label.new()
	var margin_label := Label.new()
	var controler := Control.new() # TODO
	
	var _is_group: bool
	var _base_column_width: float
	
	func _init(is_group: bool, base_column_width: float) -> void:
		_is_group = is_group
		_base_column_width = base_column_width
		size_flags_horizontal = SIZE_FILL
		
		if !is_group:
			var spacer := Control.new()
			spacer.size_flags_horizontal = SIZE_SHRINK_BEGIN
			spacer.custom_minimum_size.x = SUBGROUP_INDENT
			add_child(spacer)
			ops_label = Label.new()
			ops_label.size_flags_horizontal = SIZE_EXPAND_FILL
			add_child(ops_label)
		utilization_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		revenue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		margin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(utilization_label)
		add_child(power_label)
		add_child(flow_label)
		add_child(revenue_label)
		add_child(margin_label)
		add_child(controler)
		var gui_size: int = IVSettingsManager.get_setting(&"gui_size")
		_resize(gui_size)
		IVSettingsManager.changed.connect(_settings_listener)
	
	
	func set_row(data: Array, _group_state := -1) -> void:
		# NAN, blank
		# INF, "?"
		
		if !_is_group:
			var row_name: StringName = data[0]
			ops_label.text = row_name
		var utilization: float = data[1]
		var power: float = data[2]
		var flow: float = data[3]
		var revenue: float = data[4]
		var margin: float = data[5]
		
		utilization_label.text = "%.f" % (100.0 * utilization)
		
		if is_nan(power):
			power_label.text = " "
		elif power == INF:
			power_label.text = "?"
		else:
			power_label.text = IVQFormat.number(power, 2)
			
		if is_nan(flow):
			flow_label.text = " "
		elif flow == INF:
			flow_label.text = "?"
		else:
			flow_label.text = IVQFormat.number(flow, 2)
			
		if is_nan(revenue):
			revenue_label.text = " "
		elif revenue == INF:
			revenue_label.text = "?"
		else:
			revenue_label.text = IVQFormat.number(revenue, 2)
			
		if is_nan(margin):
			margin_label.text = " "
		elif margin == INF:
			margin_label.text = "?"
		else:
			margin_label.text = "%.f" % (100.0 * margin)
	
	
	func _resize(gui_size: int) -> void:
		var column_width := _base_column_width * IVCoreSettings.gui_size_multipliers[gui_size]
		utilization_label.custom_minimum_size.x = column_width
		power_label.custom_minimum_size.x = column_width
		flow_label.custom_minimum_size.x = column_width
		revenue_label.custom_minimum_size.x = column_width
		margin_label.custom_minimum_size.x = column_width
		controler.custom_minimum_size.x = column_width
	
	
	func _settings_listener(setting: StringName, value: Variant) -> void:
		if setting == &"gui_size":
			var gui_size: int = value
			_resize(gui_size)
