# info_tab_container.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name InfoTabContainer
extends TabContainer

# Added by code to allow persistence of info subpanels.
# TODO: Generalize so we don't have to maintain subpanel classes here.

const PERSIST_MODE := IVEnums.PERSIST_PROCEDURAL
const PERSIST_PROPERTIES: Array[StringName] = [
	&"memory",
	&"_on_ready_tab",
]

# persisted
var memory := {} # generic memory that tabs can share, eg, for open states
var _on_ready_tab := 0


# exposed at init so we can set persist values when pinning
var itab_development: ITabDevelopment
var itab_operations: ITabOperations
var itab_markets: ITabMarkets
var itab_resources: ITabResources
var itab_information: ITabInformation
var subpanels: Array[Container]


# not persisted
var _timer := Timer.new()
var _is_new := false
var _suppress_tab_listener := true


func _init(is_new := false) -> void:
	if !is_new:
		return
	_is_new = true
	itab_development = IVFiles.make_object_or_scene(ITabDevelopment)
	itab_operations = IVFiles.make_object_or_scene(ITabOperations)
	itab_markets = IVFiles.make_object_or_scene(ITabMarkets)
	itab_resources = IVFiles.make_object_or_scene(ITabResources)
	itab_information = IVFiles.make_object_or_scene(ITabInformation)
	subpanels = [itab_development, itab_operations, itab_markets, itab_resources, itab_information]


func _ready() -> void:
	name = &"InfoTabContainer"
	mouse_filter = MOUSE_FILTER_PASS
	tab_changed.connect(_tab_listener)
	add_child(_timer)
	_timer.start() # 1 s interval unless we change
	if !_is_new: # loaded game
		IVGlobal.game_load_finished.connect(_on_game_load_finished, CONNECT_ONE_SHOT)
		return
	add_child(itab_development)
	add_child(itab_operations)
	add_child(itab_markets)
	add_child(itab_resources)
	add_child(itab_information)
	_init_tabs()


func _on_game_load_finished() -> void:
	for child in get_children():
		if child is ITabDevelopment:
			itab_development = child
		elif child is ITabOperations:
			itab_operations = child
		elif child is ITabMarkets:
			itab_markets = child
		elif child is ITabResources:
			itab_resources = child
		elif child is ITabInformation:
			itab_information = child
		else:
			continue
		subpanels.append(child)
	_init_tabs()


func _init_tabs() -> void:
	set_current_tab(_on_ready_tab)
	_suppress_tab_listener = false
	itab_development.name = &"TAB_DEVELOPMENT"
	itab_operations.name = &"TAB_OPERATIONS"
	itab_markets.name = &"TAB_MARKETS"
	itab_resources.name = &"TAB_RESOURCES"
	itab_information.name = &"TAB_INFORMATION"
	_timer.timeout.connect(itab_development.timer_update)
	_timer.timeout.connect(itab_operations.timer_update)
	_timer.timeout.connect(itab_markets.timer_update)
	_timer.timeout.connect(itab_resources.timer_update)
	_timer.timeout.connect(itab_information.timer_update)


func _tab_listener(tab: int) -> void:
	if _suppress_tab_listener:
		return
	_on_ready_tab = tab

