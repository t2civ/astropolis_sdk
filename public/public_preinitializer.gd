# public_preinitializer.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends RefCounted


const AI_VERBOSE := false
const AI_VERBOSE2 := false
const IVOYAGER_VERBOSE := false
const USE_THREADS := true


func _init() -> void:
	
	var version: String = ProjectSettings.get_setting("application/config/version")
	print("Astropolis v%s - https://t2civ.com" % version)
	print("USE_THREADS = %s" % USE_THREADS)
	
	IVStateManager.core_init_object_instantiated.connect(_on_init_object_instantiated)
	IVGlobal.data_tables_postprocessed.connect(_on_data_tables_postprocessed)
	IVStateManager.core_init_program_objects_instantiated.connect(_on_program_objects_instantiated)

	# properties
	AIBus.verbose = AI_VERBOSE
	AIBus.verbose2 = AI_VERBOSE2
	IVCoreSettings.use_threads = USE_THREADS
	IVCoreSettings.start_time_date_clock = [2025, 1, 1, 12, 0, 0]
	IVCoreSettings.start_time_is_terrestrial_time = false
	
	# changed classes
	IVCoreInitializer.program_refcounteds[&"InfoCloner"] = InfoCloner
	IVCoreInitializer.program_refcounteds.erase(&"CompositionBuilder")
	IVCoreInitializer.tree_program_nodes.append(&"AstropolisGUI")
	
	# translations
	var path_format := "res://public/text/%s.translation"
	IVTranslationImporter.translations.append(path_format % "entities.en")
	IVTranslationImporter.translations.append(path_format % "gui.en")
	IVTranslationImporter.translations.append(path_format % "hints.en")
	IVTranslationImporter.translations.append(path_format % "text.en")
	
	# Units plugin
	IVQFormat.exponent_str = "e"
	
	# Save plugin
	IVSave.file_extension = "AstropolisSave"
	IVSave.file_description = "Astropolis Save"
	IVSave.autosave_uses_suffix_generator = true
	IVSave.quicksave_uses_suffix_generator = true
	IVSave.configure_save_plugin()
	
	# Core plugin static files
	IVSettingsManager.set_default(&"save_base_name", "Astropolis")
	IVSettingsManager.set_default(&"autosave_time_min", 0)


func _on_init_object_instantiated(object: Object) -> void:
	var table_initializer := object as IVTableInitializer
	if table_initializer:
		_on_table_initializer_instantiated(table_initializer)


func _on_table_initializer_instantiated(_table_initializer: IVTableInitializer) -> void:
	# WARNING: Static vars could be modified earlier, but we need to wait so
	# core can do some modding related changes first.
	
	var tables := IVTableInitializer.tables
	tables.erase("wiki_extras")
	
	var path_format := "res://public/tables/%s.tsv"
	
	tables.carrying_capacity_groups = path_format % "carrying_capacity_groups"
	tables.facilities = path_format % "facilities"
	tables.facilities_modules = path_format % "facilities_modules"
	tables.facilities_operations = path_format % "facilities_operations"
	tables.modules = path_format % "modules"
	tables.op_classes = path_format % "op_classes"
	tables.operations = path_format % "operations"
	tables.players = path_format % "players"
	tables.populations = path_format % "populations"
	tables.resource_classes = path_format % "resource_classes"
	tables.resources = path_format % "resources"
	tables.spacecrafts = path_format % "spacecrafts" # ivoyager replacement!
	tables.storage_classes = path_format % "storage_classes"
	tables.strata = path_format % "strata"
	tables.stratum_groups = path_format % "stratum_groups"
	tables.surveys = path_format % "surveys"
	tables.views = path_format % "views" # ivoyager replacement!
	# primary table mods (modify existing ivoyager tables)
	tables.planets_mod = path_format % "planets_mod"
	tables.moons_mod = path_format % "moons_mod"
	# entity x entity tables
	tables.facilities_resources = path_format % "facilities_resources"
	tables.facilities_modules = path_format % "facilities_modules"
	tables.facilities_operations = path_format % "facilities_operations"
	tables.strata_resources = path_format % "strata_resources"


func _on_data_tables_postprocessed() -> void:
	for trade_unit: StringName in IVTableData.db_tables[&"resources"][&"trade_unit"]:
		# Add all trade_unit strings to unit_multipliers for subsequent direct access.
		IVQConvert.include_compound_unit(trade_unit)


func _on_program_objects_instantiated() -> void:
	# program object changes
	
	var speed_manager: IVSpeedManager = IVGlobal.program.SpeedManager
	speed_manager.start_speed = 0
	

	
	# table additions (subtables, re-indexings, or other useful table items)
	var db_tables := IVTableData.db_tables
	var table_n_rows := IVTableData.table_n_rows
	var tables_aux := ThreadsafeGlobal.tables_aux
	
	# unique items
	tables_aux[&"resource_type_electricity"] = IVTableData.db_find(&"resources", &"unique_type",
			Enums.Types.ELECTRICITY)
	assert(tables_aux[&"resource_type_electricity"] != -1)
	# table row subsets (arrays of row_types)
	var extraction_resources := IVTableData.get_db_true_rows(&"resources", &"is_extraction")
	tables_aux[&"extraction_resources"] = extraction_resources
	var volatile_resources := IVTableData.get_db_true_rows(&"resources", &"is_volatile")
	var volatile_extraction_resources := IVArrays.get_intersection(volatile_resources,
			extraction_resources)
	tables_aux[&"volatile_extraction_resources"] = volatile_extraction_resources
	var extraction_operations := IVTableData.get_db_matching_rows(&"operations", &"process_group",
			Enums.ProcessGroup.PROCESS_GROUP_EXTRACTION)
	tables_aux[&"extraction_operations"] = extraction_operations
	# inverted table row subsets (array of indexes in the subset, where non-subset = -1)
	var n_resources: int = table_n_rows[&"resources"]
	tables_aux[&"resource_extractions"] = Utils.invert_subset_indexing(extraction_resources,
			n_resources)
	var n_operations: int = table_n_rows[&"operations"]
	tables_aux[&"operation_extractions"] = Utils.invert_subset_indexing(extraction_operations,
			n_operations)
	# one-to-many indexing (arrays of arrays)
	var module_op_classes: Array[int] = db_tables[&"modules"][&"op_class"]
	var n_op_classes: int = table_n_rows[&"op_classes"]
	tables_aux[&"op_classes_modules"] = Utils.invert_many_to_one_indexing(
			module_op_classes, n_op_classes) # modules for each op_class
	var resource_resource_classes: Array[int] = db_tables[&"resources"][&"resource_class"]
	var n_resource_classes: int = table_n_rows[&"resource_classes"]
	tables_aux[&"resource_classes_resources"] = Utils.invert_many_to_one_indexing(
			resource_resource_classes, n_resource_classes) # resources for each resource_class
	# per-operation net storage use per storage class, in open & closed cycle.
	# Positive = op produces into that storage class; negative = op draws from it.
	# Used by Facility to sample storage fullness once per interval and cap run_rate.
	var n_storage_classes: int = table_n_rows[&"storage_classes"]
	var resource_storage_classes: Array[int] = db_tables[&"resources"][&"storage_class"]
	var resource_convert_extractions: Array[int] = db_tables[&"resources"][&"convert_extraction"]
	var op_electricities: Array[float] = db_tables[&"operations"][&"electricity"]
	var op_closed_cycle_factors: Array[float] = db_tables[&"operations"][&"closed_cycle_factor"]
	var op_process_groups: Array[int] = db_tables[&"operations"][&"process_group"]
	var op_target_rates: Array[float] = db_tables[&"operations"][&"target_rate"]
	var op_in_inventory: Array[Array] = db_tables[&"operations"][&"in_inventory"]
	var op_in_inventory_rates: Array[Array] = db_tables[&"operations"][&"in_inventory_rates"]
	var op_in_atmos: Array[Array] = db_tables[&"operations"][&"in_atmos"]
	var op_in_atmos_rates: Array[Array] = db_tables[&"operations"][&"in_atmos_rates"]
	var op_out_inventory: Array[Array] = db_tables[&"operations"][&"out_inventory"]
	var op_out_inventory_rates: Array[Array] = db_tables[&"operations"][&"out_inventory_rates"]
	var op_out_atmos: Array[Array] = db_tables[&"operations"][&"out_atmos"]
	var op_out_atmos_rates: Array[Array] = db_tables[&"operations"][&"out_atmos_rates"]
	var op_out_surface: Array[Array] = db_tables[&"operations"][&"out_surface"]
	var op_out_surface_rates: Array[Array] = db_tables[&"operations"][&"out_surface_rates"]
	var op_target_deposits: Array[Array] = db_tables[&"operations"][&"target_deposits"]
	var electricity_type: int = tables_aux[&"resource_type_electricity"]
	var storage_class_electricity := resource_storage_classes[electricity_type]
	var open_cycle_uses: Array[Array] = []
	var closed_cycle_uses: Array[Array] = []
	for operation_type in n_operations:
		var open_uses: Array[float] = IVArrays.init_array(n_storage_classes, 0.0, TYPE_FLOAT)
		var closed_uses: Array[float] = IVArrays.init_array(n_storage_classes, 0.0, TYPE_FLOAT)
		# electricity (signed: + generator, - consumer)
		var base_electricity := op_electricities[operation_type]
		if storage_class_electricity != -1 and base_electricity != 0.0:
			open_uses[storage_class_electricity] += base_electricity
			closed_uses[storage_class_electricity] += (
					base_electricity * op_closed_cycle_factors[operation_type])
		# inventory inputs — both cycles draw from storage
		var in_inv_resources: Array[int] = op_in_inventory[operation_type]
		var in_inv_rates: Array[float] = op_in_inventory_rates[operation_type]
		for i in in_inv_resources.size():
			var storage_class := resource_storage_classes[in_inv_resources[i]]
			if storage_class != -1:
				open_uses[storage_class] -= in_inv_rates[i]
				closed_uses[storage_class] -= in_inv_rates[i]
		# inventory outputs — both cycles add to storage
		var out_inv_resources: Array[int] = op_out_inventory[operation_type]
		var out_inv_rates: Array[float] = op_out_inventory_rates[operation_type]
		for i in out_inv_resources.size():
			var storage_class := resource_storage_classes[out_inv_resources[i]]
			if storage_class != -1:
				open_uses[storage_class] += out_inv_rates[i]
				closed_uses[storage_class] += out_inv_rates[i]
		# atmospheric inputs — closed cycle only (open draws from atmosphere)
		var in_atmos_resources: Array[int] = op_in_atmos[operation_type]
		var in_atmos_rates: Array[float] = op_in_atmos_rates[operation_type]
		for i in in_atmos_resources.size():
			var storage_class := resource_storage_classes[in_atmos_resources[i]]
			if storage_class != -1:
				closed_uses[storage_class] -= in_atmos_rates[i]
		# atmospheric outputs — closed cycle only (open vents to atmosphere)
		var out_atmos_resources: Array[int] = op_out_atmos[operation_type]
		var out_atmos_rates: Array[float] = op_out_atmos_rates[operation_type]
		for i in out_atmos_resources.size():
			var storage_class := resource_storage_classes[out_atmos_resources[i]]
			if storage_class != -1:
				closed_uses[storage_class] += out_atmos_rates[i]
		# surface outputs — closed cycle only (open deposits to surface)
		var out_surface_resources: Array[int] = op_out_surface[operation_type]
		var out_surface_rates: Array[float] = op_out_surface_rates[operation_type]
		for i in out_surface_resources.size():
			var storage_class := resource_storage_classes[out_surface_resources[i]]
			if storage_class != -1:
				closed_uses[storage_class] += out_surface_rates[i]
		# extraction targets — real outputs come from stratum at runtime; add
		# target_rate contributions so near-full storage classes throttle extraction
		if op_process_groups[operation_type] == Enums.ProcessGroup.PROCESS_GROUP_EXTRACTION:
			var target_deposits: Array[int] = op_target_deposits[operation_type]
			var extraction_resources_out := (
					target_deposits if target_deposits else volatile_extraction_resources)
			var target_rate := op_target_rates[operation_type]
			for resource_type in extraction_resources_out:
				var convert_extraction := resource_convert_extractions[resource_type]
				var produced_type := (resource_type if convert_extraction == -1
						else convert_extraction)
				var storage_class := resource_storage_classes[produced_type]
				if storage_class != -1:
					open_uses[storage_class] += target_rate
					closed_uses[storage_class] += target_rate
		open_cycle_uses.append(open_uses)
		closed_cycle_uses.append(closed_uses)
	tables_aux[&"operation_open_cycle_storage_uses"] = open_cycle_uses
	tables_aux[&"operation_closed_cycle_storage_uses"] = closed_cycle_uses
