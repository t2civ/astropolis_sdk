# info_tab_container.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
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
var itab_physical: ITabPhysical
var itab_orbit: ITabOrbit
var itab_build: ITabBuild
var itab_budget: ITabBudget
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
	itab_physical = IVFiles.make_object_or_scene(ITabPhysical)
	itab_orbit = IVFiles.make_object_or_scene(ITabOrbit)
	itab_build = IVFiles.make_object_or_scene(ITabBuild)
	itab_budget = IVFiles.make_object_or_scene(ITabBudget)
	subpanels = [itab_development, itab_operations, itab_markets, itab_physical, itab_orbit,
			itab_build, itab_budget]


func _ready() -> void:
	name = &"InfoTabContainer"
	mouse_filter = MOUSE_FILTER_PASS
	tab_changed.connect(_tab_listener)
	add_child(_timer)
	_timer.start() # 1 s interval unless we change
	if !_is_new: # loaded game
		IVSave.load_finished.connect(_on_game_load_finished, CONNECT_ONE_SHOT)
		return
	add_child(itab_development)
	add_child(itab_operations)
	add_child(itab_markets)
	add_child(itab_physical)
	add_child(itab_orbit)
	add_child(itab_build)
	add_child(itab_budget)
	_init_tabs()


func _on_game_load_finished() -> void:
	for child in get_children():
		if child is ITabDevelopment:
			itab_development = child
		elif child is ITabOperations:
			itab_operations = child
		elif child is ITabMarkets:
			itab_markets = child
		elif child is ITabPhysical:
			itab_physical = child
		elif child is ITabOrbit:
			itab_orbit = child
		elif child is ITabBuild:
			itab_build = child
		elif child is ITabBudget:
			itab_budget = child
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
	itab_physical.name = &"TAB_PHYSICAL"
	itab_orbit.name = &"TAB_ORBIT"
	itab_build.name = &"TAB_BUILD"
	itab_budget.name = &"TAB_BUDGET"
	_timer.timeout.connect(itab_development.timer_update)
	_timer.timeout.connect(itab_operations.timer_update)
	_timer.timeout.connect(itab_markets.timer_update)
	_timer.timeout.connect(itab_physical.timer_update)
	_timer.timeout.connect(itab_orbit.timer_update)
	_timer.timeout.connect(itab_build.timer_update)
	_timer.timeout.connect(itab_budget.timer_update)


func _tab_listener(tab: int) -> void:
	if _suppress_tab_listener:
		return
	_on_ready_tab = tab
