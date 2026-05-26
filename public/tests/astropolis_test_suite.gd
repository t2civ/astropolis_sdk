# astropolis_test_suite.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends IVAssistantTestSuite

## Test suite exposing Astropolis Proxy data via the assistant TCP server.
##
## Provides methods to query Proxy instances and their net component data.
## All methods run on the main thread and access Proxies via
## [MainThreadGlobal.proxies_by_name], calling only threadsafe getters.


const MAX_INDEXED_ENTRIES := 500


func get_method_names() -> Array[String]:
	return [
		"get_astropolis_state",
		"list_proxies",
		"get_proxy_info",
		"get_development_stats",
		"list_components",
		"inspect_component",
		"query_component",
	]


func get_capabilities() -> Array[String]:
	return ["astropolis_proxies"]


func dispatch(method: String, params: Dictionary) -> Variant:
	match method:
		"get_astropolis_state":
			return _get_astropolis_state(params)
		"list_proxies":
			return _list_proxies(params)
		"get_proxy_info":
			return _get_proxy_info(params)
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

func _get_astropolis_state(_params: Dictionary) -> Variant:
	# Lightweight state probe. Clients should poll this after
	# `simulator_started`/`started=true` and wait for `proxies_ready=true`
	# before querying the Proxy system. See `MainThreadGlobal`.
	return {
		"proxies_ready": MainThreadGlobal.proxies_ready_emitted,
		"n_proxies": MainThreadGlobal.proxies_by_name.size(),
	}


# =============================================================================

func _list_proxies(params: Dictionary) -> Variant:
	var filter_has_development: bool = params.get("has_development", false)
	var result := []
	for proxy_name: StringName in MainThreadGlobal.proxies_by_name:
		var proxy: Proxy = MainThreadGlobal.proxies_by_name[proxy_name]
		if !proxy:
			continue
		var has_dev := proxy.has_development()
		if filter_has_development and !has_dev:
			continue
		result.append({
			"name": String(proxy_name),
			"entity_type": proxy.entity_type,
			"has_development": has_dev,
			"gui_name": proxy.gui_name,
		})
	return {"proxies": result}


func _get_proxy_info(params: Dictionary) -> Variant:
	var proxy: Proxy = _resolve_proxy(params)
	if proxy == null:
		return _proxy_error
	return {
		"name": String(proxy.name),
		"entity_type": proxy.entity_type,
		"gui_name": proxy.gui_name,
		"has_development": proxy.has_development(),
		"has_markets": proxy.has_markets(),
		"has_operations": proxy.get_operations() != null,
		"has_population": proxy.get_population() != null,
		"has_biome": proxy.get_biome() != null,
		"has_cyberspace": proxy.get_cyberspace() != null,
		"has_financials": proxy.get_financials() != null,
		"has_inventory": proxy.get_inventory() != null,
	}


func _get_development_stats(params: Dictionary) -> Variant:
	var proxy: Proxy = _resolve_proxy(params)
	if proxy == null:
		return _proxy_error
	if !proxy.has_development():
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "Proxy has no development data: %s" % params.get("name", "")}}
	return {
		"name": String(proxy.name),
		"population": proxy.get_development_population(),
		"economy": proxy.get_development_economy(),
		"power": proxy.get_development_power(),
		"constructions": proxy.get_development_constructions(),
		"manufacturing": proxy.get_development_manufacturing(),
		"information": proxy.get_development_information(),
		"computation": proxy.get_development_computation(),
		"biomass": proxy.get_development_biomass(),
		"bioproductivity": proxy.get_development_bioproductivity(),
		"biodiversity": proxy.get_development_biodiversity(),
	}


func _list_components(params: Dictionary) -> Variant:
	var proxy: Proxy = _resolve_proxy(params)
	if proxy == null:
		return _proxy_error
	var table_n_rows := IVTableData.table_n_rows
	var components := {}

	var ops := proxy.get_operations()
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

	var inv := proxy.get_inventory()
	if inv:
		components["inventory"] = {
			"present": true,
			"index_table": "resources",
			"n_indices": int(table_n_rows[&"resources"]),
		}
	else:
		components["inventory"] = {"present": false}

	var pop := proxy.get_population()
	if pop:
		components["population"] = {
			"present": true,
			"index_table": "populations",
			"n_indices": int(table_n_rows[&"populations"]),
		}
	else:
		components["population"] = {"present": false}

	components["financials"] = {"present": proxy.get_financials() != null,
			"type": "scalar"}
	components["biome"] = {"present": proxy.get_biome() != null,
			"type": "scalar"}
	components["cyberspace"] = {"present": proxy.get_cyberspace() != null,
			"type": "scalar"}

	var has_market := proxy.get_market(-1) != null
	components["market"] = {
		"present": has_market,
		"index_table": "resources" if has_market else "",
		"n_indices": int(table_n_rows[&"resources"]) if has_market else 0,
	}

	return {
		"name": String(proxy.name),
		"entity_type": proxy.entity_type,
		"components": components,
	}


func _inspect_component(params: Dictionary) -> Variant:
	return _do_component_query(params, [], [])


func _query_component(params: Dictionary) -> Variant:
	var entry_filter: Array = params.get("entries", [])
	var field_filter: Array = params.get("fields", [])
	return _do_component_query(params, entry_filter, field_filter)


# ********************************** HELPERS **********************************


var _proxy_error: Dictionary


func _resolve_proxy(params: Dictionary) -> Proxy:
	var proxy_name: String = params.get("name", "")
	if proxy_name.is_empty():
		_proxy_error = {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "'name' parameter is required"}}
		return null
	var proxy: Proxy = MainThreadGlobal.get_proxy_by_name(
			StringName(proxy_name))
	if !proxy:
		_proxy_error = {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "Proxy not found: %s" % proxy_name}}
		return null
	return proxy


func _do_component_query(params: Dictionary, entry_filter: Array,
		field_filter: Array) -> Variant:
	var proxy: Proxy = _resolve_proxy(params)
	if proxy == null:
		return _proxy_error
	var component: String = params.get("component", "")
	if component.is_empty():
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "'component' parameter is required"}}
	var nonzero: bool = params.get("nonzero", true)

	match component:
		"operations":
			var ops := proxy.get_operations()
			if !ops:
				return _no_component_error(proxy, component)
			return _read_operations(ops, nonzero, entry_filter, field_filter)
		"inventory":
			var inv := proxy.get_inventory()
			if !inv:
				return _no_component_error(proxy, component)
			return _read_inventory(inv, nonzero, entry_filter, field_filter)
		"population":
			var pop := proxy.get_population()
			if !pop:
				return _no_component_error(proxy, component)
			return _read_population(pop, nonzero, entry_filter, field_filter)
		"market":
			var market := proxy.get_market(-1)
			if !market:
				return _no_component_error(proxy, component)
			return _read_market(market, nonzero, entry_filter, field_filter)
		"financials":
			var fin := proxy.get_financials()
			if !fin:
				return _no_component_error(proxy, component)
			return _read_financials(fin)
		"biome":
			var bio := proxy.get_biome()
			if !bio:
				return _no_component_error(proxy, component)
			return _read_biome(bio)
		"cyberspace":
			var cyb := proxy.get_cyberspace()
			if !cyb:
				return _no_component_error(proxy, component)
			return _read_cyberspace(cyb)

	return {"_error": {"code": ERR_INVALID_PARAMS,
			"message": ("Unknown component: %s (valid: operations, inventory,"
			+ " population, market, financials, biome, cyberspace)")
			% component}}


func _no_component_error(proxy: Proxy, component: String) -> Dictionary:
	return {"_error": {"code": ERR_INVALID_PARAMS,
			"message": "Proxy '%s' has no %s component"
			% [proxy.name, component]}}


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
	# Returns array of [index, name_string] pairs. If entry_filter is empty,
	# returns all indices. If entry_filter has names, returns only matching.
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
		if ops.is_facility():
			if _has_field("capacity_factor", field_filter):
				var v := ops.get_capacity_factor(i)
				entry["capacity_factor"] = _sanitize(v)
				if _is_interesting(v):
					dominated_by_zero = false
			if _has_field("target_utilization", field_filter):
				var v := ops.get_target_utilization(i)
				entry["target_utilization"] = _sanitize(v)
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
		"ordinal_qtr": ops.ordinal_qtr,
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
		if _has_field("ops_reserve", field_filter):
			var v := inv.get_ops_reserve(i)
			entry["ops_reserve"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("strategic_reserve", field_filter):
			var v := inv.get_strategic_reserve(i)
			entry["strategic_reserve"] = _sanitize(v)
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
		if _has_field("rate", field_filter):
			var v := inv.get_rate(i)
			entry["rate"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("expected_rate", field_filter):
			var v := inv.get_expected_rate(i)
			entry["expected_rate"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if nonzero and dominated_by_zero:
			continue
		entries[entry_name] = entry
		if entries.size() >= MAX_INDEXED_ENTRIES:
			break
	return {
		"component": "inventory",
		"ordinal_qtr": inv.ordinal_qtr,
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
		"ordinal_qtr": pop.ordinal_qtr,
		"entries": entries,
		"n_total": indices.size(),
		"n_returned": entries.size(),
	}


func _read_market(market: MarketProxy, nonzero: bool,
		entry_filter: Array, field_filter: Array) -> Dictionary:
	var indices := _get_entry_indices(&"resources", entry_filter)
	var entries := {}
	for pair: Array in indices:
		var i: int = pair[0]
		var entry_name: String = pair[1]
		var entry := {}
		var dominated_by_zero := true
		if _has_field("price", field_filter):
			var v := market.get_spot_price(i)
			entry["price"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("bid_price", field_filter):
			var v := market.get_spot_bid_price(i)
			entry["bid_price"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("ask_price", field_filter):
			var v := market.get_spot_ask_price(i)
			entry["ask_price"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if _has_field("volume", field_filter):
			var v := market.get_spot_unit_volume(i)
			entry["volume"] = _sanitize(v)
			if _is_interesting(v):
				dominated_by_zero = false
		if nonzero and dominated_by_zero:
			continue
		entries[entry_name] = entry
		if entries.size() >= MAX_INDEXED_ENTRIES:
			break
	return {
		"component": "market",
		"ordinal_qtr": market.ordinal_qtr,
		"entries": entries,
		"n_total": indices.size(),
		"n_returned": entries.size(),
	}


func _read_financials(fin: FinancialsNet) -> Dictionary:
	return {
		"component": "financials",
		"ordinal_qtr": fin.ordinal_qtr,
		"revenue": fin._revenue,
		"gross_output": fin._gross_output,
		"cost_of_goods_sold": fin._cost_of_goods_sold,
		"revenue_lfq": fin.get_revenue_lfq(),
		"gross_output_lfq": fin.get_gross_output_lfq(),
	}


func _read_biome(bio: BiomeNet) -> Dictionary:
	return {
		"component": "biome",
		"ordinal_qtr": bio.ordinal_qtr,
		"bioproductivity": bio.get_bioproductivity(),
		"biomass": bio.get_biomass(),
		"biodiversity": bio.get_biodiversity(),
	}


func _read_cyberspace(cyb: CyberspaceNet) -> Dictionary:
	return {
		"component": "cyberspace",
		"ordinal_qtr": cyb.ordinal_qtr,
		"computation_rate": cyb.get_computation_rate(),
		"information": cyb.get_information(),
	}
