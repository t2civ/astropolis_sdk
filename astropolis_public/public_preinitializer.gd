# public_preinitializer.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
extends RefCounted

const VERSION := "0.0.4.dev"

const AI_VERBOSE := false
const AI_VERBOSE2 := false
const IVOYAGER_VERBOSE := false
const USE_THREADS := false


func _init():
	print("Astropolis Public %s, USE_THREADS = %s" % [VERSION, USE_THREADS])
	IVGlobal.project_objects_instantiated.connect(_on_project_objects_instantiated)
	IVGlobal.project_nodes_added.connect(_on_project_nodes_added)

	# properties
	AIGlobal.verbose = AI_VERBOSE
	AIGlobal.verbose2 = AI_VERBOSE2
	IVCoreSettings.use_threads = USE_THREADS
	IVCoreSettings.save_file_extension = "AstropolisSave"
	IVCoreSettings.save_file_extension_name = "Astropolis Save"
	IVCoreSettings.start_time = 10.0 * IVUnits.YEAR
	IVCoreSettings.colors.great = Color.BLUE
	
	# translations
	var path_format := "res://astropolis_public/data/text/%s.translation"
	IVCoreSettings.translations.append(path_format % "entities.en")
	IVCoreSettings.translations.append(path_format % "gui.en")
	IVCoreSettings.translations.append(path_format % "hints.en")
	
	# tables
	IVCoreSettings.table_project_enums.append(Enums.OpProcessGroup)
	IVCoreSettings.table_project_enums.append(Enums.TradeClasses)
	IVCoreSettings.table_project_enums.append(Enums.PlayerClasses)
	
	IVCoreSettings.postprocess_tables.erase("res://addons/ivoyager_core/data/solar_system/spacecrafts.tsv")
	IVCoreSettings.postprocess_tables.erase("res://addons/ivoyager_core/data/solar_system/wiki_extras.tsv")
	
	path_format = "res://astropolis_public/data/tables/%s.tsv"
	var postprocess_tables_append := [
		# primary tables
		path_format % "carrying_capacity_groups",
		path_format % "compositions",
		path_format % "facilities",
		path_format % "major_strata",
		path_format % "mod_classes",
		path_format % "modules",
		path_format % "op_classes",
		path_format % "op_groups",
		path_format % "operations",
		path_format % "players",
		path_format % "populations",
		path_format % "resource_classes",
		path_format % "resources",
		path_format % "spacecrafts", # replacement!
		path_format % "strata",
		path_format % "surveys",
		# primary table mods
		path_format % "asset_adjustments_mod",
		path_format % "planets_mod",
		path_format % "moons_mod",
		# enum x enum tables
		path_format % "compositions_resources_heterogeneities",
		path_format % "compositions_resources_percents",
		path_format % "facilities_operations_capacities",
		path_format % "facilities_operations_utilizations",
		path_format % "facilities_populations",
		path_format % "facilities_resources",
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
	var unit_multipliers := IVUnits.unit_multipliers
	unit_multipliers[&"flops"] = 1.0 / IVUnits.SECOND # base unit for computation
	unit_multipliers[&"puhr"] = 1e16 * 3600.0 # 'processor unit hour'; 1e16 flops/s * hr
	unit_multipliers[&"species"] = 1.0
	unit_multipliers[&"t/d"] = IVUnits.TONNE / IVUnits.DAY
	unit_multipliers[&"km^3"] = IVUnits.KM ** 3
	
	
	IVQFormat.exponent_str = "e"


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
	
	# unique items
	tables[&"resource_type_electricity"] = IVTableData.db_find(&"resources", &"unique_type", &"electricity")
	assert(tables[&"resource_type_electricity"] != -1)
	# table row subsets (arrays of row_types)
	var extraction_resources := IVTableData.get_db_true_rows(&"resources", &"is_extraction")
	tables[&"extraction_resources"] = extraction_resources
	tables[&"maybe_free_resources"] = IVTableData.get_db_true_rows(&"resources", &"maybe_free")
	tables[&"is_manufacturing_operations"] = IVTableData.get_db_true_rows(&"operations", &"is_manufacturing")
	var extraction_operations := IVTableData.get_db_matching_rows(&"operations", &"op_process_group",
			Enums.OpProcessGroup.OP_PROCESS_GROUP_EXTRACTION)
	tables[&"extraction_operations"] = extraction_operations
	# inverted table row subsets (array of indexes in the subset, where non-subset = -1)
	var n_resources: int = table_n_rows[&"resources"]
	tables[&"resource_extractions"] = Utils.invert_subset_indexing(extraction_resources, n_resources)
	var n_operations: int = table_n_rows[&"operations"]
	tables[&"operation_extractions"] = Utils.invert_subset_indexing(extraction_operations, n_operations)
	# one-to-many indexing (arrays of arrays)
	var op_group_op_classes: Array[int] = tables[&"op_groups"][&"op_class"]
	var n_op_classes: int = table_n_rows[&"op_classes"]
	tables[&"op_classes_op_groups"] = Utils.invert_many_to_one_indexing(op_group_op_classes,
			n_op_classes) # an array of op_groups for each op_class
	var operation_op_groups: Array[int] = tables[&"operations"][&"op_group"]
	var n_op_groups: int = table_n_rows[&"op_groups"]
	tables[&"op_groups_operations"] = Utils.invert_many_to_one_indexing(operation_op_groups,
			n_op_groups) # an array of operations for each op_group
	var resource_resource_classes: Array[int] = tables[&"resources"][&"resource_class"]
	var n_resource_classes: int = table_n_rows[&"resource_classes"]
	tables[&"resource_classes_resources"] = Utils.invert_many_to_one_indexing(
			resource_resource_classes, n_resource_classes) # an array of resources for each resource_class
	
	# tests
	for i in n_operations:
		assert(IVTableData.get_db_array(&"operations", &"input_resources", i).size()
				== IVTableData.get_db_array(&"operations", &"input_quantities", i).size())
		assert(IVTableData.get_db_array(&"operations", &"output_resources", i).size()
				== IVTableData.get_db_array(&"operations", &"output_quantities", i).size())


func _on_project_nodes_added() -> void:
	# FIXME: This breaks stand-alone SDK...
	IVCoreInitializer.move_top_gui_child_to_sibling(&"AstroGUI", &"SplashScreen", true)

