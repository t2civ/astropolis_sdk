# stats_grid.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name StatsGrid
extends MarginContainer

# IDEA: Click on value to cycle representation. E.g., for population:
#     1.23 Quadrillion
#     1.23 x 10^15
#     1,234,567,890,123,456

signal has_stats_changed(has_stats: bool)

const ivutils := preload("res://addons/ivoyager_core/static/utils.gd")


# GUI values - parent should set only once at init
#var update_interval := 1.0 # seconds
var zero_value := "-" # set "" to print zeros w/ units
var show_missing_interface := true
var force_rows := true # if false, skip rows missing in all interfaces
var min_columns := 3 # inclues row labels
var required_component := &"operations"


var content: Array[Array] = [
	# label_txt, target_path
	[&"LABEL_POPULATION", &"get_development_population", IVQFormat.named_number],
	[&"LABEL_ECONOMY", &"get_development_economy", IVQFormat.modified_named_number.bind(3,
			IVQFormat.TextFormat.SHORT_MIXED_CASE, "$", "", 1.0 / IVUnits.unit_multipliers[&"$"])],
	[&"LABEL_ENERGY", &"get_development_energy", IVQFormat.prefixed_unit.bind(&"W")],
	[&"LABEL_MANUFACTURING", &"get_development_manufacturing", IVQFormat.prefixed_unit.bind(&"t/h")],
	[&"LABEL_CONSTRUCTIONS", &"get_development_constructions", IVQFormat.prefixed_unit.bind(&"t")],
	[&"LABEL_COMPUTATIONS", &"get_development_computations", IVQFormat.prefixed_unit.bind(&"flops")],
	[&"LABEL_INFORMATION", &"get_development_information", IVQFormat.prefixed_unit.bind(&"bit")],
	[&"LABEL_BIOPRODUCTIVITY", &"get_development_bioproductivity", IVQFormat.prefixed_unit.bind(&"t/h")],
	[&"LABEL_BIOMASS", &"get_development_biomass", IVQFormat.prefixed_unit.bind(&"t")],
	[&"LABEL_BIODIVERSITY", &"get_development_biodiversity", IVQFormat.prefixed_unit.bind(&"spp")],
]

var targets: Array[StringName] = [&"PLANET_EARTH", &"JOIN_OFFWORLD"]
var column_names: Array[StringName] = [&"PLANET_EARTH", &"TXT_OFF_EARTH"] # use instead of Interface name
var fallback_names: Array[StringName] = [&"", &""] # if "" will uses targets string

var _thread_targets: Array[StringName]
var _thread_fallback_names: Array[StringName]
var _thread_column_names: Array[StringName]

@onready var _grid: GridContainer = $Grid


func update_targets(targets_: Array[StringName], column_names_: Array[StringName] = [],
		fallback_names_: Array[StringName] = []) -> void:
	targets = targets_
	column_names = column_names_
	fallback_names = fallback_names_
	update()


func update() -> void:
	MainThreadGlobal.call_ai_thread(_set_data)


# *****************************************************************************
# AI thread !!!!

func _set_data() -> void:
	var data := []
	_thread_targets = targets # for thread safety
	_thread_column_names = column_names
	_thread_fallback_names = fallback_names
	
	# get Interfaces and check required components
	var interfaces: Array[Interface] = []
	var has_data := false
	for target in _thread_targets:
		var interface := Interface.get_interface_by_name(target)
		if interface:
			if interface.get(required_component):
				has_data = true
			else:
				interface = null
		if interface or show_missing_interface:
			interfaces.append(interface) # may be null
	if !has_data:
		_no_data.call_deferred()
		return

	# do counts
	var n_interfaces := interfaces.size()
	var n_spacers := 0
	if n_interfaces < min_columns - 1:
		n_spacers = min_columns - n_interfaces - 1
	
	# start building data
	data.append(n_interfaces + 1 + n_spacers) # n_columns
	
	# headers
	var i := 0
	while i < n_interfaces:
		var interface: Interface = interfaces[i]
		var use_name := ""
		if _thread_column_names:
			use_name = _thread_column_names[i]
		elif interface:
			use_name = interface.gui_name if interface.gui_name else tr(interface.name)
		elif _thread_fallback_names[i]:
			use_name = _thread_fallback_names[i]
		else:
			use_name = _thread_targets[i]
		data.append(use_name) # header
		i += 1
	i = 0
	while i < n_spacers:
		data.append("")
		i += 1

	# data rows
	var row := 1
	for line_array in content:
		var method: StringName = line_array[1]
		var values := []
		var is_data := false
		for interface in interfaces:
			var value: Variant = 0.0
			if interface:
				value = interface.call(method)
				if value != null:
					is_data = true
			values.append(value)
		
		if !force_rows and !is_data:
			continue # don't add row
			
		# add row label
		var row_text: String = line_array[0] # row label
		data.append(row_text)
		
		var format_callable: Callable = line_array[2]
		
		# add values
		for value: Variant in values:
			var value_text: String
			if value != null and (value or !zero_value):
				value_text = format_callable.call(value)
			else:
				value_text = zero_value
			data.append(value_text)
		i = 0
		while i < n_spacers:
			data.append("")
			i += 1
		
		# next row
		row += 1

	# add n_rows and finish
	data.append(row)
	_build_grid.call_deferred(data)


# *****************************************************************************
# Main thread !!!!

func _no_data() -> void:
	_grid.hide()
	has_stats_changed.emit(false)


func _build_grid(data: Array) -> void:
	var n_columns: int = data[0] # includes labels
	_grid.columns = n_columns
	var n_rows: int = data[-1] # includes headers
	var n_cells_needed := n_rows * n_columns
	var n_cells := _grid.get_child_count()
	while n_cells < n_cells_needed:
		var label := Label.new()
		#label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		_grid.add_child(label)
		n_cells += 1
		
	# headers
	var column := 1
	while column < n_columns:
		var header_label: Label = _grid.get_child(column)
		var header_text: String = data[column]
		header_label.text = header_text
		header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_label.show()
		column += 1
		
	# data rows
	var row := 1
	while row < n_rows:
		var row_label: Label = _grid.get_child(row * n_columns)
		var row_text: String = data[row * n_columns]
		row_label.text = row_text
		row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row_label.show()
		
		# values
		column = 1
		while column < n_columns:
			var value_label: Label = _grid.get_child(row * n_columns + column)
			var value_text: String = data[row * n_columns + column]
			value_label.text = value_text
			value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			value_label.show()
			column += 1
		row += 1
	
	# hide unsused cells
	while n_cells > n_cells_needed:
		n_cells -= 1
		var label: Label = _grid.get_child(n_cells)
		label.hide()
	
	has_stats_changed.emit(true)
	_grid.show()

