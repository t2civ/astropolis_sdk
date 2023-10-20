# selection_manager.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name SelectionManager
extends IVSelectionManager

# Everything here works on the main thread! NOT THREADSAFE!
#
# We use I, Voyager's selection system almost as is. This extended class adds
# methods for making Facility and Proxy selections (static for camera access).
#
# For facility selection: 
#   name              = Facility.name
#   gui_name          = Facility.gui_name (something like 'Moon / NASA')
#   up_selection_name = Body.name
#
# As above for proxy (body/polity) selection.
#
# TODO: Depreciate unused 'is_body' and 'spatial' in base I, Voyager class?

const PLAYER_CLASS_POLITY := Enums.PlayerClasses.PLAYER_CLASS_POLITY

const PERSIST_PROPERTIES2: Array[StringName] = [
	&"info_panel_target_name",
]

var info_panel_target_name: StringName # facility, body or proxy



static func get_or_make_selection(selection_name: StringName) -> IVSelection:
	var selection_: IVSelection = IVGlobal.selections.get(selection_name)
	if selection_:
		return selection_
	if IVGlobal.bodies.has(selection_name): # its a Body in the system
		return make_selection_for_body(selection_name)
	elif selection_name.begins_with("FACILITY_"):
		return make_selection_for_facility(selection_name)
	assert(false, "Missing body or unsupported selection type: " + selection_name)
	return null


static func make_selection_for_facility(facility_name: StringName) -> IVSelection:
	var gui_name: String = MainThreadGlobal.get_gui_name(facility_name)
	var body_name: StringName = MainThreadGlobal.get_body_name(facility_name)
	var body_selection := get_or_make_selection(body_name)
	var selection_ := _duplicate_body_selection(body_selection)
	selection_.name = facility_name
	selection_.gui_name = gui_name
	selection_.up_selection_name = body_name
	IVGlobal.selections[facility_name] = selection_
	return selection_


static func _duplicate_body_selection(body_selection: IVSelection) -> IVSelection:
	var selection_ := IVSelection.new()
	for property in body_selection.PERSIST_PROPERTIES:
		selection_.set(property, body_selection.get(property))
	selection_.texture_2d = body_selection.texture_2d
	selection_.texture_slice_2d = body_selection.texture_slice_2d
	return selection_


func select(selection_: IVSelection, suppress_camera_move := false) -> void:
	_set_info_target_name(selection_)
	super(selection_, suppress_camera_move)


func select_body(body: IVBody, _suppress_camera_move := false) -> void:
	# We override base method so navigation GUI sends us to a facility, usually.
	# Use select_by_name() if you really need the body.
	select_prefer_facility(body.name)


func select_prefer_facility(selection_name: StringName) -> void:
	# Redirects to single facility or local player facility if not Earth
	if !selection_name.begins_with("FACILITY_"):
		var redirect: StringName = MainThreadGlobal.get_body_selection_redirect(selection_name)
		if redirect:
			selection_name = redirect
	var selection_ := get_or_make_selection(selection_name)
	select(selection_)


func get_body_gui_name() -> String:
	var body_name := get_body_name()
	if !body_name:
		return ""
	return MainThreadGlobal.get_gui_name(body_name)


func get_info_target_name() -> StringName:
	return info_panel_target_name


func _set_info_target_name(selection_: IVSelection) -> void:
	# Target is for InfoPanel; could be facility, body or proxy.
	if !selection_:
		return
	var selection_name := selection_.name
	var body_name: StringName
	if selection_name.begins_with("FACILITY_"):
		var player_name: StringName = MainThreadGlobal.get_player_name(selection_name)
		var player_class := MainThreadGlobal.get_player_class(player_name)
		if player_class == PLAYER_CLASS_POLITY:
			# polity proxy (combines polity player, agency & companies)
			body_name = selection_.get_body_name()
			var polity_name: StringName = MainThreadGlobal.get_polity_name(selection_name)
			info_panel_target_name = StringName("PROXY_" + body_name + "_" + polity_name)
			return
		# agency or company facility is the target
		info_panel_target_name = selection_name
		return
	# must be body selection
	body_name = selection_.get_body_name()
	assert(body_name == selection_name)
	var body_flags := MainThreadGlobal.get_body_flags(body_name)
	if body_flags & BodyFlags.IS_STAR:
		# solar system
		var system_name := "SYSTEM_" + body_name
		info_panel_target_name = StringName("PROXY_" + system_name)
		return
	# body is the target
	info_panel_target_name = selection_name

