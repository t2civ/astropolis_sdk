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
	tables.compositions = path_format % "compositions"
	tables.facilities = path_format % "facilities"
	tables.module_classes = path_format % "module_classes"
	tables.modules = path_format % "modules"
	tables.op_classes = path_format % "op_classes"
	tables.op_groups = path_format % "op_groups"
	tables.operations = path_format % "operations"
	tables.players = path_format % "players"
	tables.populations = path_format % "populations"
	tables.resource_classes = path_format % "resource_classes"
	tables.resources = path_format % "resources"
	tables.spacecrafts = path_format % "spacecrafts" # ivoyager replacement!
	tables.strata = path_format % "strata"
	tables.surveys = path_format % "surveys"
	tables.views = path_format % "views" # ivoyager replacement!
	# primary table mods (modify existing ivoyager tables)
	#tables.asset_adjustments_mod = path_format % "asset_adjustments_mod"
	tables.planets_mod = path_format % "planets_mod"
	tables.moons_mod = path_format % "moons_mod"
	# entity x entity tables
	tables.compositions_resources_deposits = path_format % "compositions_resources_deposits"
	tables.compositions_resources_proportions = path_format % "compositions_resources_proportions"
	tables.compositions_resources_variances = path_format % "compositions_resources_variances"
	tables.facilities_inventories = path_format % "facilities_inventories"
	tables.facilities_operations_capacities = path_format % "facilities_operations_capacities"
	tables.facilities_operations_capacity_factors = path_format % "facilities_operations_capacity_factors"
	tables.facilities_operations_extractions = path_format % "facilities_operations_extractions"
	tables.facilities_populations = path_format % "facilities_populations"


func _on_data_tables_postprocessed() -> void:
	for trade_unit: StringName in IVTableData.db_tables[&"resources"][&"trade_unit"]:
		# Add all trade_unit strings to unit_multipliers for subsequent direct access.
		IVQConvert.include_compound_unit(trade_unit)


func _on_program_objects_instantiated() -> void:
	# program object changes
	
	var timekeeper: IVTimekeeper = IVGlobal.program.Timekeeper
	timekeeper.start_speed = 0
	
#	var model_builder: IVModelBuilder = IVGlobal.program.ModelBuilder
#	model_builder.model_tables.append("spacecrafts")
	
	
	# table additions (subtables, re-indexings, or other useful table items)
	var db_tables := IVTableData.db_tables
	var table_n_rows: Dictionary = IVTableData.table_n_rows
	var tables_aux: Dictionary = ThreadsafeGlobal.tables_aux
	
	# unique items
	tables_aux[&"resource_type_electricity"] = IVTableData.db_find(&"resources", &"unique_type",
			Enums.Types.ELECTRICITY)
	assert(tables_aux[&"resource_type_electricity"] != -1)
	# table row subsets (arrays of row_types)
	var extraction_resources := IVTableData.get_db_true_rows(&"resources", &"is_extraction")
	tables_aux[&"extraction_resources"] = extraction_resources
	var extraction_operations := IVTableData.get_db_matching_rows(&"operations", &"process_group",
			Enums.ProcessGroup.PROCESS_GROUP_EXTRACTION)
	tables_aux[&"extraction_operations"] = extraction_operations
	# inverted table row subsets (array of indexes in the subset, where non-subset = -1)
	var n_resources: int = table_n_rows[&"resources"]
	tables_aux[&"resource_extractions"] = Utils.invert_subset_indexing(extraction_resources, n_resources)
	var n_operations: int = table_n_rows[&"operations"]
	tables_aux[&"operation_extractions"] = Utils.invert_subset_indexing(extraction_operations, n_operations)
	# one-to-many indexing (arrays of arrays)
	var op_group_op_classes: Array[int] = db_tables[&"op_groups"][&"op_class"]
	var n_op_classes: int = table_n_rows[&"op_classes"]
	tables_aux[&"op_classes_op_groups"] = Utils.invert_many_to_one_indexing(op_group_op_classes,
			n_op_classes) # an array of op_groups for each op_class
	var operation_op_groups: Array[int] = db_tables[&"operations"][&"op_group"]
	var n_op_groups: int = table_n_rows[&"op_groups"]
	tables_aux[&"op_groups_operations"] = Utils.invert_many_to_one_indexing(operation_op_groups,
			n_op_groups) # an array of operations for each op_group
	var resource_resource_classes: Array[int] = db_tables[&"resources"][&"resource_class"]
	var n_resource_classes: int = table_n_rows[&"resource_classes"]
	tables_aux[&"resource_classes_resources"] = Utils.invert_many_to_one_indexing(
			resource_resource_classes, n_resource_classes) # an array of resources for each resource_class
	
	# error testing
	for operation_type in IVTableData.get_n_rows(&"operations"):
		# Test redundant 'process_group' in operations.tsv and op_groups.tsv.
		var op_group := IVTableData.get_db_int(&"operations", &"op_group", operation_type)
		var process_group := IVTableData.get_db_int(&"operations", &"process_group", operation_type)
		assert(process_group == IVTableData.get_db_int(&"op_groups", &"process_group", op_group),
				"Inconsistant 'process_group' in 'operations.tsv' and 'op_groups.tsv'")
