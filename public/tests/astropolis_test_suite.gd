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
## Provides methods to query Interface instances and their net component data.
## All methods run on the main thread and access Interfaces via
## [MainThreadGlobal.interfaces_by_name], calling only threadsafe getters.


const MAX_INDEXED_ENTRIES := 500


func get_method_names() -> Array[String]:
	return [
		"list_interfaces",
		"get_interface_info",
		"get_development_stats",
		"list_components",
		"inspect_component",
		"query_component",
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
		"list_components":
			return _list_components(params)
		"inspect_component":
			return _inspect_component(params)
		"query_component":
			return _query_component(params)
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
	var interface: Interface = _resolve_interface(params)
	if interface == null:
		return _interface_error
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
		"has_inventory": interface.get_inventory() != null,
	}


func _get_development_stats(params: Dictionary) -> Variant:
	var interface: Interface = _resolve_interface(params)
	if interface == null:
		return _interface_error
	if !interface.has_development():
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "Interface has no development data: %s" % params.get("name", "")}}
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


func _list_components(params: Dictionary) -> Variant:
	var interface: Interface = _resolve_interface(params)
	if interface == null:
		return _interface_error
	var table_n_rows := IVTableData.table_n_rows
	var components := {}

	var ops := interface.get_operations()
	if ops:
		components["operations"] = {
			"present": true,
			"index_table": "operations",
			"n_indices": int(table_n_rows[&"operations"]),
			"has_financials": ops.has_financials(),
			"is_facility": ops.is_facility(),
		}
	else:
		components["operations"] = {"present": false}

	var inv := interface.get_inventory()
	if inv:
		components["inventory"] = {
			"present": true,
			"index_table": "resources",
			"n_indices": int(table_n_rows[&"resources"]),
		}
	else:
		components["inventory"] = {"present": false}

	var pop := interface.get_population()
	if pop:
		components["population"] = {
			"present": true,
			"index_table": "populations",
			"n_indices": int(table_n_rows[&"populations"]),
		}
	else:
		components["population"] = {"present": false}

	components["financials"] = {"present": interface.get_financials() != null,
			"type": "scalar"}
	components["biome"] = {"present": interface.get_biome() != null,
			"type": "scalar"}
	components["cyberspace"] = {"present": interface.get_cyberspace() != null,
			"type": "scalar"}

	var player_id: int = params.get("player_id", 0)
	var has_marketplace := interface.get_marketplace(player_id) != null
	components["marketplace"] = {
		"present": has_marketplace,
		"index_table": "resources" if has_marketplace else "",
		"n_indices": int(table_n_rows[&"resources"]) if has_marketplace else 0,
	}

	return {
		"name": String(interface.name),
		"entity_type": interface.entity_type,
		"components": components,
	}


func _inspect_component(params: Dictionary) -> Variant:
	return _do_component_query(params, [], [])


func _query_component(params: Dictionary) -> Variant:
	var entry_filter: Array = params.get("entries", [])
	var field_filter: Array = params.get("fields", [])
	return _do_component_query(params, entry_filter, field_filter)


# =============================================================================
# Helpers


var _interface_error: Dictionary


func _resolve_interface(params: Dictionary) -> Interface:
	var interface_name: String = params.get("name", "")
	if interface_name.is_empty():
		_interface_error = {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "'name' parameter is required"}}
		return null
	var interface: Interface = MainThreadGlobal.get_interface_by_name(
			StringName(interface_name))
	if !interface:
		_interface_error = {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "Interface not found: %s" % interface_name}}
		return null
	return interface


func _do_component_query(params: Dictionary, entry_filter: Array,
		field_filter: Array) -> Variant:
	var interface: Interface = _resolve_interface(params)
	if interface == null:
		return _interface_error
	var component: String = params.get("component", "")
	if component.is_empty():
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "'component' parameter is required"}}
	var nonzero: bool = params.get("nonzero", true)

	match component:
		"operations":
			var ops := interface.get_operations()
			if !ops:
				return _no_component_error(interface, component)
			return _read_operations(ops, nonzero, entry_filter, field_filter)
		"inventory":
			var inv := interface.get_inventory()
			if !inv:
				return _no_component_error(interface, component)
			return _read_inventory(inv, nonzero, entry_filter, field_filter)
		"population":
			var pop := interface.get_population()
			if !pop:
				return _no_component_error(interface, component)
			return _read_population(pop, nonzero, entry_filter, field_filter)
		"marketplace":
			var mkt_player_id: int = params.get("player_id", 0)
			var mkt := interface.get_marketplace(mkt_player_id)
			if !mkt:
				return _no_component_error(interface, component)
			return _read_marketplace(mkt, nonzero, entry_filter, field_filter)
		"financials":
			var fin := interface.get_financials()
			if !fin:
				return _no_component_error(interface, component)
			return _read_financials(fin)
		"biome":
			var bio := interface.get_biome()
			if !bio:
				return _no_component_error(interface, component)
			return _read_biome(bio)
		"cyberspace":
			var cyb := interface.get_cyberspace()
			if !cyb:
				return _no_component_error(interface, component)
			return _read_cyberspace(cyb)

	return {"_error": {"code": ERR_INVALID_PARAMS,
			"message": ("Unknown component: %s (valid: operations, inventory,"
			+ " population, marketplace, financials, biome, cyberspace)")
			% component}}


func _no_component_error(interface: Interface, component: String) -> Dictionary:
	return {"_error": {"code": ERR_INVALID_PARAMS,
			"message": "Interface '%s' has no %s component"
			% [interface.name, component]}}


static func _sanitize(value: float) -> Variant:
	if is_nan(value) or is_inf(value):
		return null
	return value


static func _is_interesting(value: float) -> bool:
	return value != 0.0 and not is_nan(value) and not is_inf(value)


static func _has_field(field: String, field_filter: Array) -> bool:
	return field_filter.is_empty() or field in field_filter


static func _get_table_names(table_name: StringName) -> Array[StringName]:
	return IVTableData.db_tables[table_name][&"name"]


static func _build_name_to_index(table_name: StringName) -> Dictionary:
	var names: Array[StringName] = _get_table_names(table_name)
	var result := {}
	for i in names.size():
		result[String(names[i])] = i
	return result


func _get_entry_indices(table_name: StringName, entry_filter: Array) -> Array:
	## Returns array of [index, name_string] pairs. If entry_filter is empty,
	## returns all indices. If entry_filter has names, returns only matching.
	var names: Array[StringName] = _get_table_names(table_name)
	var n := names.size()
	if entry_filter.is_empty():
		var all_indices := []
		all_indices.resize(n)
		for i in n:
			all_indices[i] = [i, String(names[i])]
		return all_indices
	var name_to_idx := _build_name_to_index(table_name)
	var filtered_indices := []
	for entry_name: String in entry_filter:
		if name_to_idx.has(entry_name):
			filtered_indices.append([name_to_idx[entry_name], entry_name])
	return filtered_indices


func _read_operations(ops: OperationsNet, nonzero: bool,
		entry_filter: Array, field_filter: Array) -> Dictionary:
	var indices := _get_entry_indices(&"operations", entry_filter)
	var has_fin := ops.has_financials()
	var entries := {}
	for pair: Array in indices:
		var i: int = pair[0]
		var entry_name: String = pair[1]
		var entry := {}
		var dominated_by_zero := true
		if _has_field("capacity", field_filter):
			var v := ops.get_capacity(i)
			entry["capacity"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("run_rate", field_filter):
			var v := ops.get_run_rate(i)
			entry["run_rate"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("effective_rate", field_filter):
			var v := ops.get_effective_rate(i)
			entry["effective_rate"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("utilization", field_filter):
			var v := ops.get_utilization(i)
			entry["utilization"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("electricity_rate", field_filter):
			var v := ops.get_electricity_rate(i)
			entry["electricity_rate"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if has_fin:
			if _has_field("revenue_rate", field_filter):
				var v := ops.get_revenue_rate(i)
				entry["revenue_rate"] = _sanitize(v)
				if _is_interesting(v):
					dominated_by_zero = false
			if _has_field("cogs_rate", field_filter):
				var v := ops.get_cogs_rate(i)
				entry["cogs_rate"] = _sanitize(v)
				if _is_interesting(v):
					dominated_by_zero = false
			if _has_field("gross_margin", field_filter):
				var v := ops.get_gross_margin(i)
				entry["gross_margin"] = _sanitize(v)
				if _is_interesting(v):
					dominated_by_zero = false
		if nonzero and dominated_by_zero:
			continue
		entries[entry_name] = entry
		if entries.size() >= MAX_INDEXED_ENTRIES:
			break
	return {
		"component": "operations",
		"run_qtr": ops.run_qtr,
		"entries": entries,
		"n_total": indices.size(),
		"n_returned": entries.size(),
	}


func _read_inventory(inv: InventoryNet, nonzero: bool,
		entry_filter: Array, field_filter: Array) -> Dictionary:
	var indices := _get_entry_indices(&"resources", entry_filter)
	var entries := {}
	for pair: Array in indices:
		var i: int = pair[0]
		var entry_name: String = pair[1]
		var entry := {}
		var dominated_by_zero := true
		if _has_field("stock", field_filter):
			var v := inv.get_stock(i)
			entry["stock"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("surplus", field_filter):
			var v := inv.get_surplus(i)
			entry["surplus"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("in_transit", field_filter):
			var v := inv.get_in_transit(i)
			entry["in_transit"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("contracted", field_filter):
			var v := inv.get_contracted(i)
			entry["contracted"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if nonzero and dominated_by_zero:
			continue
		entries[entry_name] = entry
		if entries.size() >= MAX_INDEXED_ENTRIES:
			break
	return {
		"component": "inventory",
		"run_qtr": inv.run_qtr,
		"entries": entries,
		"n_total": indices.size(),
		"n_returned": entries.size(),
	}


func _read_population(pop: PopulationNet, nonzero: bool,
		entry_filter: Array, field_filter: Array) -> Dictionary:
	var indices := _get_entry_indices(&"populations", entry_filter)
	var entries := {}
	for pair: Array in indices:
		var i: int = pair[0]
		var entry_name: String = pair[1]
		var entry := {}
		var dominated_by_zero := true
		if _has_field("number", field_filter):
			var v := pop.get_number(i)
			entry["number"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if nonzero and dominated_by_zero:
			continue
		entries[entry_name] = entry
		if entries.size() >= MAX_INDEXED_ENTRIES:
			break
	return {
		"component": "population",
		"run_qtr": pop.run_qtr,
		"entries": entries,
		"n_total": indices.size(),
		"n_returned": entries.size(),
	}


func _read_marketplace(mkt: MarketplaceNet, nonzero: bool,
		entry_filter: Array, field_filter: Array) -> Dictionary:
	var indices := _get_entry_indices(&"resources", entry_filter)
	var entries := {}
	for pair: Array in indices:
		var i: int = pair[0]
		var entry_name: String = pair[1]
		var entry := {}
		var dominated_by_zero := true
		if _has_field("price", field_filter):
			var v := mkt.get_price(i)
			entry["price"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("bid", field_filter):
			var v := mkt.get_bid(i)
			entry["bid"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("ask", field_filter):
			var v := mkt.get_ask(i)
			entry["ask"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("volume", field_filter):
			var v := mkt.get_volume(i)
			entry["volume"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if nonzero and dominated_by_zero:
			continue
		entries[entry_name] = entry
		if entries.size() >= MAX_INDEXED_ENTRIES:
			break
	return {
		"component": "marketplace",
		"run_qtr": mkt.run_qtr,
		"entries": entries,
		"n_total": indices.size(),
		"n_returned": entries.size(),
	}


func _read_financials(fin: FinancialsNet) -> Dictionary:
	return {
		"component": "financials",
		"run_qtr": fin.run_qtr,
		"revenue": fin._revenue,
		"gross_output": fin._gross_output,
		"cost_of_goods_sold": fin._cost_of_goods_sold,
		"revenue_lfq": fin.get_revenue_lfq(),
		"gross_output_lfq": fin.get_gross_output_lfq(),
	}


func _read_biome(bio: BiomeNet) -> Dictionary:
	return {
		"component": "biome",
		"run_qtr": bio.run_qtr,
		"bioproductivity": bio.get_bioproductivity(),
		"biomass": bio.get_biomass(),
		"biodiversity": bio.get_biodiversity(),
	}


func _read_cyberspace(cyb: CyberspaceNet) -> Dictionary:
	return {
		"component": "cyberspace",
		"run_qtr": cyb.run_qtr,
		"computation_rate": cyb.get_computation_rate(),
		"information": cyb.get_information(),
	}
