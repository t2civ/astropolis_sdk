# public_preinitializer.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends RefCounted


const AI_VERBOSE := false
const AI_VERBOSE2 := false
const IVOYAGER_VERBOSE := false
const USE_THREADS := false


func _init() -> void:
	
	var version: String = ProjectSettings.get_setting("application/config/version")
	print("Astropolis %s - https://t2civ.com" % version)
	print("USE_THREADS = %s" % USE_THREADS)
	
	IVGlobal.data_tables_imported.connect(_on_data_tables_imported)
	IVGlobal.project_objects_instantiated.connect(_on_project_objects_instantiated)
	IVGlobal.project_nodes_added.connect(_on_project_nodes_added)

	# properties
	AIGlobal.verbose = AI_VERBOSE
	AIGlobal.verbose2 = AI_VERBOSE2
	IVCoreSettings.project_name = "Astropolis"
	IVCoreSettings.project_version = version # helps load file debug
	IVCoreSettings.use_threads = USE_THREADS
	IVCoreSettings.save_file_extension = "AstropolisSave"
	IVCoreSettings.save_file_extension_name = "Astropolis Save"
	IVCoreSettings.start_time = 10.0 * IVUnits.YEAR
	IVCoreSettings.colors.great = Color.BLUE
	
	# translations
	var path_format := "res://public/data/text/%s.translation"
	IVCoreSettings.translations.append(path_format % "entities.en")
	IVCoreSettings.translations.append(path_format % "gui.en")
	IVCoreSettings.translations.append(path_format % "hints.en")
	IVCoreSettings.translations.append(path_format % "text.en")
	
	# tables
	IVCoreSettings.table_project_enums.append(Enums.Types)
	IVCoreSettings.table_project_enums.append(Enums.TradeClasses)
	IVCoreSettings.table_project_enums.append(Enums.PlayerClasses)
	IVCoreSettings.table_project_enums.append(Enums.ProcessGroup)
	
	IVCoreSettings.postprocess_tables.erase("res://addons/ivoyager_core/data/solar_system/spacecrafts.tsv")
	IVCoreSettings.postprocess_tables.erase("res://addons/ivoyager_core/data/solar_system/wiki_extras.tsv")
	
	path_format = "res://public/data/tables/%s.tsv"
	var postprocess_tables_append := [
		# primary tables
		path_format % "carrying_capacity_groups",
		path_format % "compositions",
		path_format % "facilities",
		path_format % "module_classes",
		path_format % "modules",
		path_format % "op_classes",
		path_format % "op_groups",
		path_format % "operations",
		path_format % "players",
		path_format % "populations",
		path_format % "resource_classes",
		path_format % "resources",
		path_format % "spacecrafts", # ivoyager replacement!
		path_format % "strata",
		path_format % "surveys",
		# primary table mods (modify existing ivoyager tables)
		path_format % "asset_adjustments_mod",
		path_format % "planets_mod",
		path_format % "moons_mod",
		# enum x enum tables
		path_format % "compositions_resources_deposits",
		path_format % "compositions_resources_proportions",
		path_format % "compositions_resources_variances",
		path_format % "facilities_inventories",
		path_format % "facilities_operations_capacities",
		path_format % "facilities_operations_capacity_factors",
		path_format % "facilities_operations_extractions",
		path_format % "facilities_populations",
	]
	IVCoreSettings.postprocess_tables.append_array(postprocess_tables_append)
	
	# added/replaced classes
	IVCoreInitializer.program_refcounteds[&"InfoCloner"] = InfoCloner
	IVCoreInitializer.gui_nodes[&"AstroGUI"] = AstroGUI
	
	# extended
	IVCoreInitializer.procedural_objects[&"SelectionManager"] = SelectionManager
	
	# removed
	IVCoreInitializer.program_refcounteds.erase(&"CompositionBuilder")
	IVCoreInitializer.procedural_objects.erase(&"Composition") # using total replacement
	
	# static class changes
	IVQFormat.exponent_str = "e"


func _on_data_tables_imported() -> void:
	for trade_unit: StringName in IVTableData.tables[&"resources"][&"trade_unit"]:
		# This adds some odd unit strings like '14 t' to the unit_multipliers
		# dictionary for subsequent use by GUI. 
		IVQConvert.convert_quantity(1.0, trade_unit)


func _on_project_objects_instantiated() -> void:
	# program object changes
	
	var timekeeper: IVTimekeeper = IVGlobal.program.Timekeeper
	timekeeper.date_format = timekeeper.DATE_FORMAT_Y_M_D_Q_YQ_YM
	timekeeper.start_speed = 0
	
	var settings_manager: IVSettingsManager = IVGlobal.program.SettingsManager
	var defaults: Dictionary = settings_manager.defaults
	defaults.save_base_name = "Astropolis"
	
#	var model_builder: IVModelBuilder = IVGlobal.program.ModelBuilder
#	model_builder.model_tables.append("spacecrafts")
	
	
	# table additions (subtables, re-indexings, or other useful table items)
	var tables: Dictionary = IVTableData.tables
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
	var op_group_op_classes: Array[int] = tables[&"op_groups"][&"op_class"]
	var n_op_classes: int = table_n_rows[&"op_classes"]
	tables_aux[&"op_classes_op_groups"] = Utils.invert_many_to_one_indexing(op_group_op_classes,
			n_op_classes) # an array of op_groups for each op_class
	var operation_op_groups: Array[int] = tables[&"operations"][&"op_group"]
	var n_op_groups: int = table_n_rows[&"op_groups"]
	tables_aux[&"op_groups_operations"] = Utils.invert_many_to_one_indexing(operation_op_groups,
			n_op_groups) # an array of operations for each op_group
	var resource_resource_classes: Array[int] = tables[&"resources"][&"resource_class"]
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


func _on_project_nodes_added() -> void:
	pass

