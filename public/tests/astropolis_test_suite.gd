# astropolis_test_suite.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends IVAssistantTestSuite

## Test suite exposing Astropolis Interface data via the assistant TCP server.
##
## Provides methods to query Interface instances and their development
## statistics. All methods run on the main thread and access Interfaces via
## [MainThreadGlobal.interfaces_by_name], calling only threadsafe getters.


func get_method_names() -> Array[String]:
	return [
		"list_interfaces",
		"get_interface_info",
		"get_development_stats",
	]


func get_capabilities() -> Array[String]:
	return ["astropolis_interfaces"]


func dispatch(method: String, params: Dictionary) -> Variant:
	match method:
		"list_interfaces":
			return _list_interfaces(params)
		"get_interface_info":
			return _get_interface_info(params)
		"get_development_stats":
			return _get_development_stats(params)
	return {"_error": {"code": ERR_UNKNOWN_METHOD,
			"message": "Unknown method: %s" % method}}


# =============================================================================

func _list_interfaces(params: Dictionary) -> Variant:
	var filter_has_development: bool = params.get("has_development", false)
	var result := []
	for interface_name: StringName in MainThreadGlobal.interfaces_by_name:
		var interface: Interface = MainThreadGlobal.interfaces_by_name[interface_name]
		if !interface:
			continue
		var has_dev := interface.has_development()
		if filter_has_development and !has_dev:
			continue
		result.append({
			"name": String(interface_name),
			"entity_type": interface.entity_type,
			"has_development": has_dev,
			"gui_name": interface.gui_name,
		})
	return {"interfaces": result}


func _get_interface_info(params: Dictionary) -> Variant:
	var interface_name: String = params.get("name", "")
	if interface_name.is_empty():
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "'name' parameter is required"}}
	var interface: Interface = MainThreadGlobal.get_interface_by_name(StringName(interface_name))
	if !interface:
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "Interface not found: %s" % interface_name}}
	return {
		"name": String(interface.name),
		"entity_type": interface.entity_type,
		"gui_name": interface.gui_name,
		"has_development": interface.has_development(),
		"has_markets": interface.has_markets(),
		"has_operations": interface.get_operations() != null,
		"has_population": interface.get_population() != null,
		"has_biome": interface.get_biome() != null,
		"has_cyberspace": interface.get_cyberspace() != null,
		"has_financials": interface.get_financials() != null,
	}


func _get_development_stats(params: Dictionary) -> Variant:
	var interface_name: String = params.get("name", "")
	if interface_name.is_empty():
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "'name' parameter is required"}}
	var interface: Interface = MainThreadGlobal.get_interface_by_name(StringName(interface_name))
	if !interface:
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "Interface not found: %s" % interface_name}}
	if !interface.has_development():
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "Interface has no development data: %s" % interface_name}}
	return {
		"name": String(interface.name),
		"population": interface.get_development_population(),
		"economy": interface.get_development_economy(),
		"power": interface.get_development_power(),
		"constructions": interface.get_development_constructions(),
		"manufacturing": interface.get_development_manufacturing(),
		"information": interface.get_development_information(),
		"computation": interface.get_development_computation(),
		"biomass": interface.get_development_biomass(),
		"bioproductivity": interface.get_development_bioproductivity(),
		"biodiversity": interface.get_development_biodiversity(),
	}
