# player_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name PlayerInterface
extends Interface

# SDK Note: This class will be ported to C++ becoming a GDExtension class. You
# will have access to API (just like any Godot class) but the GDScript class
# will be removed.
#
# To modify AI, see comments in '_base_ai.gd' files.
#
# Warning! This object lives and dies on the AI thread! Containers and many
# methods are not threadsafe. Accessing non-container properties is safe.
#
# Players are never removed, but they are effectively dead if is_facilities == false.

static var player_interfaces: Array[PlayerInterface] = [] # indexed by player_id

# public read-only
var player_id := -1
var player_class := -1 # PlayerClasses enum
var part_of: PlayerInterface # non-polity players only!
var polity_name: StringName
var homeworld := ""
var is_facilities := true # 'alive' player test

var facilities: Array[Interface] = [] # resizable container - not threadsafe!

var operations := OperationsNet.new(true, true)
var financials := FinancialsNet.new(true)
var population := PopulationNet.new(true)
var biome := BiomeNet.new(true)
var cyberspace := CyberspaceNet.new(true)



func _init() -> void:
	super()
	entity_type = ENTITY_PLAYER


func _clear_circular_references() -> void:
	# down hierarchy only
	facilities.clear()


# *****************************************************************************
# interface API


func has_development() -> bool:
	return true


func has_markets() -> bool:
	return false


func get_player_name() -> StringName:
	return name


func get_player_class() -> int:
	return player_class


func get_polity_name() -> StringName:
	return polity_name


func get_facilities() -> Array[Interface]:
	# AI thread only!
	return facilities


func get_development_population(population_type := -1) -> float:
	return population.get_number(population_type) + operations.get_crew(population_type)


func get_development_economy() -> float:
	return operations.get_gross_output_lfq()


func get_development_energy_use() -> float:
	return operations.get_energy_use()


func get_development_construction() -> float:
	return operations.get_construction()


func get_development_built_mass() -> float:
	return operations.get_built_mass()


func get_development_computation() -> float:
	return operations.get_total_computation()


func get_development_information() -> float:
	return cyberspace.get_information()


func get_development_bioproductivity() -> float:
	return biome.get_bioproductivity()


func get_development_biomass() -> float:
	return biome.get_biomass()


func get_development_biodiversity() -> float:
	var biodiversity := biome.get_biodiversity()
	if biodiversity == 1.0 and get_development_population() == 0.0:
		return 0.0 # mech civ!
	return biodiversity


# Components

func get_operations() -> OperationsNet:
	return operations


func get_financials() -> FinancialsNet:
	return financials


func get_population() -> PopulationNet:
	return population


func get_biome() -> BiomeNet:
	return biome


func get_cyberspace() -> CyberspaceNet:
	return cyberspace



# *****************************************************************************
# sync

func set_network_init(data: Array) -> void:
	player_id = data[2]
	name = data[3]
	gui_name = data[4]
	player_class = data[5]
	var part_of_name: StringName = data[6]
	part_of = interfaces_by_name[part_of_name] if part_of_name else null
	polity_name = data[7]
	homeworld = data[8]
	
	var operations_data: Array = data[9]
	var financials_data: Array = data[10]
	var population_data: Array = data[11]
	var biome_data: Array = data[12]
	var cyberspace_data: Array = data[13]
	
	operations.set_network_init(operations_data)
	financials.set_network_init(financials_data)
	population.set_network_init(population_data)
	biome.set_network_init(biome_data)
	cyberspace.set_network_init(cyberspace_data)


func sync_server_dirty(data: Array) -> void:
	
	var offsets: Array[int] = data[0]
	var int_data: Array[int] = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset

	#if dirty & DIRTY_QUARTER:
		#prints("NET", self)

	if dirty & DIRTY_BASE:
		var string_data: Array[String] = data[3]
		gui_name = string_data[0]
		player_class = int_data[1]
		var part_of_name := string_data[1]
		part_of = interfaces_by_name[part_of_name] if part_of_name else null
		polity_name = string_data[2]
		homeworld = string_data[3]
	
	if dirty & DIRTY_OPERATIONS:
		operations.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_FINANCIALS:
		financials.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_POPULATION:
		population.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_BIOME:
		biome.add_dirty(data, offsets[k], offsets[k + 1])
		k += 3
	if dirty & DIRTY_CYBERSPACE:
		cyberspace.add_dirty(data, offsets[k], offsets[k + 1])
	
	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated



func add_facility(facility: Interface) -> void:
	assert(!facilities.has(facility))
	facilities.append(facility)
	is_facilities = true


func remove_facility(facility: Interface) -> void:
	facilities.erase(facility)
	is_facilities = !facilities.is_empty()

