# itab_operations.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name ITabOperations
extends MarginContainer
const SCENE := "res://astropolis_public/gui_panels/itab_operations.tscn"

# Tabs follow row enumerations in op_classes.tsv.
# TODO: complete localizations


enum {
	GROUP_OPEN,
	GROUP_CLOSED,
	GROUP_SINGULAR,
}

const N_COLUMNS := 7

const OPEN_PREFIX := "\u2304   "
const CLOSED_PREFIX := ">   "
const SINGULAR_PREFIX := "     "
const SUB_PREFIX := "         "

const PERSIST_MODE := IVEnums.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = [
	&"current_tab",
	&"_on_ready_tab",
]

# persisted
var current_tab := 0
var _on_ready_tab := 0

# not persisted

var _state: Dictionary = IVGlobal.state
var _selection_manager: SelectionManager
var _suppress_tab_listener := true

var _name_column_width := 250.0 # TODO: resize on GUI resize (also in RowItem)

# table indexing
var _tables: Dictionary = IVTableData.tables
var _op_classes_op_groups: Array = _tables.op_classes_op_groups
var _op_group_names: Array = _tables.op_groups.name
var _op_groups_operations: Array = _tables.op_groups_operations
var _operation_names: Array = _tables.operations.name
var _operation_flow_units: Array = _tables.operations.flow_unit

@onready var _multipliers := IVUnits.unit_multipliers
@warning_ignore("unsafe_property_access")
@onready var _memory: Dictionary = get_parent().memory # open states
@onready var _no_ops_label: Label = $NoOpsLabel
@onready var _tab_container: TabContainer = $TabContainer
@onready var _vboxes := [
	$"%EnergyVBox",
	$"%ExtractionVBox",
	$"%RefiningVBox",
	$"%ManufacturingVBox",
	$"%BiomesVBox",
	$"%ServicesVBox",
]
@onready var _col0_spacers := [
	$TabContainer/Energy/Hdrs/Spacer,
	$TabContainer/Extraction/Hdrs/Spacer,
	$TabContainer/Refining/Hdrs/Spacer,
	$TabContainer/Manufacturing/Hdrs/Spacer,
	$TabContainer/Biomes/Hdrs/Spacer,
	$TabContainer/Services/Hdrs/Spacer,
]
@onready var _revenue_hdrs := [
	$TabContainer/Energy/Hdrs/Hdr4,
	$TabContainer/Extraction/Hdrs/Hdr4,
	$TabContainer/Refining/Hdrs/Hdr4,
	$TabContainer/Manufacturing/Hdrs/Hdr4,
	$TabContainer/Biomes/Hdrs/Hdr4,
	$TabContainer/Services/Hdrs/Hdr4,
]
@onready var _margin_hdrs := [
	$TabContainer/Energy/Hdrs/Hdr5,
	$TabContainer/Extraction/Hdrs/Hdr5,
	$TabContainer/Refining/Hdrs/Hdr5,
	$TabContainer/Manufacturing/Hdrs/Hdr5,
	$TabContainer/Biomes/Hdrs/Hdr5,
	$TabContainer/Services/Hdrs/Hdr5,
]


func _ready() -> void:
	IVGlobal.about_to_free_procedural_nodes.connect(_clear)
	visibility_changed.connect(_update_tab)
	_selection_manager = IVSelectionManager.get_selection_manager(self)
	_selection_manager.selection_changed.connect(_update_tab)
	_tab_container.tab_changed.connect(_select_tab)
	# rename tabs for localization or abreviation
	$TabContainer/Energy.name = &"TAB_OPS_ENERGY"
	$TabContainer/Extraction.name = &"TAB_OPS_EXTRACTION"
	$TabContainer/Refining.name = &"TAB_OPS_REFINING"
	$TabContainer/Manufacturing.name = &"TAB_OPS_MANUFACTURING"
	$TabContainer/Biomes.name = &"TAB_OPS_BIOMES"
	$TabContainer/Services.name = &"TAB_OPS_SERVICES"
	
	for col0_spacer in _col0_spacers:
		col0_spacer.custom_minimum_size.x = _name_column_width - 10.0
	
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
	if !visible or !_state.is_running:
		return
	var target_name := _selection_manager.get_info_target_name()
	if MainThreadGlobal.has_development(target_name):
		MainThreadGlobal.call_ai_thread(_get_ai_data.bind(target_name))
	else:
		_update_no_operations()


func _update_no_operations() -> void:
	_tab_container.hide()
	_no_ops_label.show()


# *****************************************************************************
# AI thread !!!!

func _get_ai_data(target_name: StringName) -> void:
	var data := []
	var interface := Interface.get_interface_by_name(target_name)
	if !interface:
		_update_no_operations.call_deferred()
		return
	
	var tab := current_tab
	var operations: Operations = interface.get(&"operations")
	assert(operations)
	var has_financials := operations.has_financials
	var op_groups: Array = _op_classes_op_groups[tab]
	var n_op_groups := op_groups.size()
	var i := 0
	while i < n_op_groups:
		var op_group_type: int = op_groups[i]
		var group_data := [
			_op_group_names[op_group_type],
			operations.get_group_utilization(op_group_type),
			operations.get_group_energy(op_group_type),
			NAN,
			operations.get_group_est_revenue(op_group_type) if has_financials else NAN,
			operations.get_group_est_gross_margin(op_group_type) if has_financials else NAN,
		]
		data.append(group_data)
		
		var ops_data := []
		var ops: Array = _op_groups_operations[op_group_type]
		var n_ops := ops.size()
		if n_ops < 2:
			data.append(ops_data)
			i += 1
			continue
		
		# ops under op_group
		var j := 0
		while j < n_ops:
			var operation_type: int = ops[j]
			var flow: float = operations.get_gui_flow(operation_type)
			if !is_nan(flow):
				flow /= _multipliers[_operation_flow_units[operation_type]]
			var op_data := [
				_operation_names[operation_type],
				operations.get_utilization(operation_type),
				
				# FIXME: Below should be electricity
				
				operations.get_electricity(operation_type),
				flow,
				operations.get_est_revenue(operation_type) if has_financials else NAN,
				operations.get_est_gross_margin(operation_type) if has_financials else NAN,
			]
			ops_data.append(op_data)
			j += 1
		
		data.append(ops_data)
		i += 1
	
	_update_tab_display.call_deferred(target_name, tab, n_op_groups, has_financials, data)


# *****************************************************************************
# Main thread !!!!


func _update_tab_display(target_name: StringName, tab: int, n_op_groups: int, has_financials: bool,
		data: Array) -> void:
	# TODO: if no op_groups, show something like, "(No Energy Operations)"
	
	# header changes
	var revenue_hdr: Label = _revenue_hdrs[tab]
	var margin_hdr: Label = _margin_hdrs[tab]
	revenue_hdr.text = "Revenue" if has_financials else ""
	margin_hdr.text = "Margin" if has_financials else ""
	
	# make GroupBoxes as needed
	var vbox: VBoxContainer = _vboxes[tab]
	var n_children := vbox.get_child_count()
	while n_children < n_op_groups:
		vbox.add_child(GroupBox.new(_memory))
		n_children += 1
	
	# set and show GroupBoxes
	var i := 0
	while i < n_op_groups:
		var group_data: Array = data[i * 2]
		var ops_data: Array = data[i * 2 + 1]
		var group_box: GroupBox = vbox.get_child(i)
		var op_group_type: int = _op_classes_op_groups[tab][i]
		var init_open: bool = _tables.op_groups.init_open[op_group_type]
		group_box.set_group_item(target_name, group_data, ops_data, init_open)
		group_box.show()
		i += 1
	
	# hide unused
	while i < n_children:
		var group_box: GroupBox = vbox.get_child(i)
		group_box.hide()
		i += 1
	
	_no_ops_label.hide()
	_tab_container.show()



class GroupBox extends VBoxContainer:
	# Reused container for RowItems (which are reused)
	
	var _group_hdr := RowItem.new(true)
	var _is_open: bool
	var _is_singular: bool
	var _memory: Dictionary
	var _memory_key: String
	
	
	func _init(memory: Dictionary) -> void:
		_memory = memory
		size_flags_horizontal = SIZE_FILL
		add_child(_group_hdr)
		_group_hdr.group_button.button_down.connect(_toggle_open_close)
	
	
	func set_group_item(target_name: StringName, group_data: Array, ops_data: Array,
			init_open := true) -> void:
		_memory_key = target_name + group_data[0]
		if _memory.has(_memory_key):
			_is_open = _memory[_memory_key]
		else:
			_is_open = init_open

		var group_state: int
		if ops_data:
			group_state = GROUP_OPEN if _is_open else GROUP_CLOSED
			_is_singular = false
		else:
			group_state = GROUP_SINGULAR
			_is_singular = true
		_group_hdr.set_row(group_data, group_state)
		
		var n_ops := ops_data.size()
		var n_children := get_child_count()
		var n_children_needed := n_ops + 1
		while n_children < n_children_needed:
			add_child(RowItem.new(false))
			n_children += 1
		var i := 0
		while i < n_ops:
			var ops_row: RowItem = get_child(i + 1)
			var ops_datum: Array = ops_data[i]
			ops_row.set_row(ops_datum)
			ops_row.visible = _is_open
			i += 1
		
		# hide unused
		i = n_children_needed
		while i < n_children:
			var ops_row: RowItem = get_child(i)
			ops_row.hide()
			i += 1
	
	
	func _toggle_open_close() -> void:
		if _is_singular:
			return
		_is_open = !_is_open
		_memory[_memory_key] = _is_open
		_group_hdr.set_group_open_close(_is_open)
		var n_children := get_child_count()
		var i := 1
		while i < n_children:
			var ops_row: RowItem = get_child(i)
			ops_row.visible = _is_open
			i += 1


class RowItem extends HBoxContainer:
	
	var group_button: Button # if _is_group == true
	var ops_label: Label # if _is_group == false
	var utilization_label := Label.new()
	var power_label := Label.new()
	var flow_label := Label.new()
	var revenue_label := Label.new()
	var margin_label := Label.new()
	var controler := Control.new() # TODO
	
	var unit_multipliers := IVUnits.unit_multipliers
	
	var _is_group: bool
	var _group_name: StringName
	var _name_column_width := 250.0 # TODO: resize on GUI resize
	
	
	func _init(is_group: bool) -> void:
		_is_group = is_group
		size_flags_horizontal = SIZE_FILL
		
		if is_group:
			group_button = Button.new()
			group_button.size_flags_horizontal = SIZE_EXPAND_FILL
			group_button.custom_minimum_size.x = _name_column_width
			group_button.flat = true
			group_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			add_child(group_button)
		else:
			ops_label = Label.new()
			ops_label.size_flags_horizontal = SIZE_EXPAND_FILL
			ops_label.custom_minimum_size.x = _name_column_width
			add_child(ops_label)
		utilization_label.size_flags_horizontal = SIZE_EXPAND_FILL
		utilization_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		power_label.size_flags_horizontal = SIZE_EXPAND_FILL
		power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		flow_label.size_flags_horizontal = SIZE_EXPAND_FILL
		flow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		revenue_label.size_flags_horizontal = SIZE_EXPAND_FILL
		revenue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		margin_label.size_flags_horizontal = SIZE_EXPAND_FILL
		margin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		controler.size_flags_horizontal = SIZE_FILL
		controler.custom_minimum_size.x = 20
		add_child(utilization_label)
		add_child(power_label)
		add_child(flow_label)
		add_child(revenue_label)
		add_child(margin_label)
		add_child(controler)
	
	
	func set_row(data: Array, group_state := -1) -> void:
		# NAN, blank
		# INF, "?"
		var row_name: StringName = data[0]
		var utilization: float = data[1]
		var power: float = data[2]
		var flow: float = data[3]
		var revenue: float = data[4]
		var margin: float = data[5]

		if _is_group:
			_group_name = row_name
			if group_state == GROUP_SINGULAR:
				group_button.text = SINGULAR_PREFIX + tr(row_name)
			else:
				set_group_open_close(group_state == GROUP_OPEN)
		else:
			ops_label.text = SUB_PREFIX + tr(row_name)
		
		utilization_label.text = "%.f" % (100.0 * utilization)
			
		if is_nan(power):
			power_label.text = " "
		elif power == INF:
			power_label.text = "?"
		else:
			power /= unit_multipliers[&"MW"]
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
			revenue_label.text = IVQFormat.number(revenue / 1e6, 2)
			
		if is_nan(margin):
			margin_label.text = " "
		elif margin == INF:
			margin_label.text = "?"
		else:
			margin_label.text = "%.f" % (100.0 * margin)
	
	
	func set_group_open_close(is_open: bool) -> void:
		assert(_is_group)
		if is_open:
			group_button.text = OPEN_PREFIX + tr(_group_name)
		else:
			group_button.text = CLOSED_PREFIX + tr(_group_name)

