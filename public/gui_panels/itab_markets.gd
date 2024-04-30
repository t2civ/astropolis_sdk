# itab_markets.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ITabMarkets
extends MarginContainer
const SCENE := "res://public/gui_panels/itab_markets.tscn"

# Tabs follow row enumerations in resource_classes.tsv.
#
# FIXME: Volume, Bid/Ask get and format.
# TODO: Header localizations.

const N_COLUMNS := 6

const TRADE_CLASS_TEXTS := [ # correspond to TradeClasses
	"",
	"",
	"ice, ",
	"liq, ",
	"cryo, ",
	"",
	"",
]

const PERSIST_MODE := IVEnums.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = [
	&"vol_toggle",
	&"current_tab",
	&"_on_ready_tab",
]

var unit_multipliers := IVUnits.unit_multipliers

# persisted
var vol_toggle := true # show volume or bid/ask
var current_tab := 0
var _on_ready_tab := 0


var _state: Dictionary = IVGlobal.state
var _selection_manager: SelectionManager
var _suppress_tab_listener := true

var _name_column_width := 230.0 # TODO: resize on GUI resize (also in RowItem)

# table indexing
var _tables: Dictionary = IVTableData.tables
var _tables_aux: Dictionary = ThreadsafeGlobal.tables_aux
var _resource_names: Array[StringName] = _tables[&"resources"][&"name"]
var _trade_classes: Array[int] = _tables[&"resources"][&"trade_class"]
var _trade_units: Array[StringName] = _tables[&"resources"][&"trade_unit"]
var _resource_classes_resources: Array[Array] = _tables_aux[&"resource_classes_resources"]


@onready var _no_markets_label: Label = $NoMarkets
@onready var _tab_container: TabContainer = $TabContainer
@onready var _vboxes: Array[VBoxContainer] = [
	$"%EnergyVBox",
	$"%OresVBox",
	$"%VolatilesVBox",
	$"%MaterialsVBox",
	$"%ManufacturedVBox",
	$"%BiologicalsVBox",
	$"%CyberVBox",
]
@onready var _col0_spacers: Array[Control] = [
	$TabContainer/Energy/Hdrs/Spacer,
	$TabContainer/Ores/Hdrs/Spacer,
	$TabContainer/Volatiles/Hdrs/Spacer,
	$TabContainer/Materials/Hdrs/Spacer,
	$TabContainer/Manufactured/Hdrs/Spacer,
	$TabContainer/Biologicals/Hdrs/Spacer,
	$TabContainer/Cyber/Hdrs/Spacer,
]


func _ready() -> void:
	IVGlobal.about_to_free_procedural_nodes.connect(_clear)
	visibility_changed.connect(_update_tab)
	_selection_manager = IVSelectionManager.get_selection_manager(self)
	_selection_manager.selection_changed.connect(_update_tab)
	_tab_container.tab_changed.connect(_select_tab)
	# rename tabs for abreviated localization
	$TabContainer/Energy.name = &"TAB_MKS_ENERGY"
	$TabContainer/Ores.name = &"TAB_MKS_ORES"
	$TabContainer/Volatiles.name = &"TAB_MKS_VOLATILES"
	$TabContainer/Materials.name = &"TAB_MKS_MATERIALS"
	$TabContainer/Manufactured.name = &"TAB_MKS_MANUFACTURED"
	$TabContainer/Biologicals.name = &"TAB_MKS_BIOLOGICALS"
	$TabContainer/Cyber.name = &"TAB_MKS_CYBER"
	for col0_spacer in _col0_spacers:
		col0_spacer.custom_minimum_size.x = _name_column_width
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


func _update_tab(_suppress_camera_move := false) -> void:
	if !visible or !_state.is_running:
		return
	if !visible or !_state.is_running:
		return
	var target_name := _selection_manager.get_selection_name()
	if MainThreadGlobal.has_markets(target_name):
		MainThreadGlobal.call_ai_thread(_get_ai_data.bind(target_name))
	else:
		_update_no_markets(MainThreadGlobal.has_development(target_name))


func _update_no_markets(has_development := false) -> void:
	_tab_container.hide()
	_no_markets_label.text = (&"LABEL_NO_MARKETS_SELECT_ENTITY" if has_development
			else &"LABEL_NO_MARKETS")
	_no_markets_label.show()


# *****************************************************************************
# AI thread !!!!

func _get_ai_data(target_name: StringName) -> void:
	
	var interface := Interface.get_interface_by_name(target_name)
	if !interface:
		_update_no_markets.call_deferred()
		return
	var tab := current_tab
	var resource_class_resources: Array = _resource_classes_resources[tab]
	var data := []
	var n_resources := resource_class_resources.size()
	var i := 0
	while i < n_resources:
		var resource_type: int = resource_class_resources[i]
		data.append(resource_type)
		data.append(interface.get_resource_price(resource_type))
		data.append(interface.get_resource_bid(resource_type))
		data.append(interface.get_resource_ask(resource_type))
		data.append(interface.get_resource_in_stock(resource_type))
		data.append(interface.get_resource_contracted(resource_type))
		i += 1
	
	_update_tab_display.call_deferred(tab, n_resources, data)
	

# *****************************************************************************
# Main thread !!!!

func _update_tab_display(tab: int, n_resources: int, data: Array) -> void:
	# We convert prices and quantities to trade_unit here. We're assuming
	# all trade_units are multipliers, but that could change (e.g., if we
	# implement floating currencies).
	
	# make rows as needed
	var vbox: VBoxContainer = _vboxes[tab]
	var n_children := vbox.get_child_count()
	while n_children < n_resources:
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = SIZE_FILL
		var column := 0
		while column < N_COLUMNS:
			var label := Label.new()
			label.size_flags_horizontal = SIZE_EXPAND_FILL
			if column == 0: # resource name
				label.custom_minimum_size.x = _name_column_width
			else: # value
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if column == 2:
				label.visible = !vol_toggle
			elif column == 3:
				label.visible = vol_toggle
			hbox.add_child(label)
			column += 1
		vbox.add_child(hbox)
		n_children += 1
	
	var currency_multiplier: float = unit_multipliers[&"$"]
	
	var i := 0
	while i < n_resources:
		var resource_type: int = data[i * N_COLUMNS]
		var price: float = data[i * N_COLUMNS + 1]
		var bid: float = data[i * N_COLUMNS + 2]
		var ask: float = data[i * N_COLUMNS + 3]
		var in_stock: float = data[i * N_COLUMNS + 4]
		var contracted: float = data[i * N_COLUMNS + 5]
		
		var trade_class: int = _trade_classes[resource_type]
		var trade_unit: StringName = _trade_units[resource_type]
		var unit_multiplier: float = unit_multipliers[trade_unit]
		var price_multiplier := currency_multiplier / unit_multiplier
		
		var resource_text: String = (tr(_resource_names[resource_type])
				+ " (" + TRADE_CLASS_TEXTS[trade_class] + trade_unit + ")")
		var price_text := "" if is_nan(price) else IVQFormat.number(price / price_multiplier, 3)
		var bid_text := "" if is_nan(bid) else IVQFormat.number(bid / price_multiplier, 3)
		var ask_text := "" if is_nan(ask) else IVQFormat.number(ask / price_multiplier, 3)
		var in_stock_text := IVQFormat.number(in_stock / unit_multiplier, 2)
		var contracted_text := IVQFormat.number(contracted / unit_multiplier, 2)
		
		var hbox: HBoxContainer = vbox.get_child(i)
		(hbox.get_child(0) as Label).text = resource_text
		(hbox.get_child(1) as Label).text = price_text
		(hbox.get_child(2) as Label).text = bid_text
		(hbox.get_child(3) as Label).text = ask_text
		(hbox.get_child(4) as Label).text = in_stock_text
		(hbox.get_child(5) as Label).text = contracted_text
		i += 1
	
	# no show/hide needed if we always show all resources

	_no_markets_label.hide()
	_tab_container.show()

