# player_interface.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name PlayerInterface
extends Interface

# DO NOT MODIFY THIS FILE! To modify AI, see comments in '_base_ai.gd' files.
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

var operations := Operations.new(true, true)
var financials := Financials.new(true)
var population := Population.new(true)
var biome := Biome.new(true)
var metaverse := Metaverse.new(true)



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


func get_total_population() -> float:
	return population.get_number_total() + operations.get_crew_total()


func get_total_population_by_type(population_type: int) -> float:
	return population.get_number(population_type) + operations.get_crew(population_type)


func get_lfq_gross_output() -> float:
	return operations.lfq_gross_output


func get_total_energy() -> float:
	return operations.get_total_energy()


func get_total_manufacturing() -> float:
	return operations.get_total_manufacturing()


func get_total_constructions() -> float:
	return operations.constructions


func get_total_computations() -> float:
	return metaverse.computations


func get_information() -> float:
	return metaverse.get_information()


func get_total_bioproductivity() -> float:
	return biome.bioproductivity


func get_total_biomass() -> float:
	return biome.biomass


func get_biodiversity() -> float:
	return biome.get_biodiversity()




# *****************************************************************************
# sync

func set_server_init(data: Array) -> void:
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
	var metaverse_data: Array = data[13]
	
	operations.set_server_init(operations_data)
	financials.set_server_init(financials_data)
	population.set_server_init(population_data)
	biome.set_server_init(biome_data)
	metaverse.set_server_init(metaverse_data)


func sync_server_dirty(data: Array) -> void:
	var dirty: int = data[0]
	var k := 1
	if dirty & DIRTY_BASE:
		gui_name = data[k]
		player_class = data[k + 1]
		var part_of_name: StringName = data[k + 2]
		part_of = interfaces_by_name[part_of_name] if part_of_name else null
		polity_name = data[k + 3]
		homeworld = data[k + 4]


func propagate_server_delta(data: Array) -> void:
	var int_data: Array[int] = data[0]
	var dirty: int = int_data[1]
	if dirty & DIRTY_OPERATIONS:
		operations.add_server_delta(data)
	# skip inventory
	if dirty & DIRTY_FINANCIALS:
		financials.add_server_delta(data)
	if dirty & DIRTY_POPULATION:
		population.add_server_delta(data)
	if dirty & DIRTY_BIOME:
		biome.add_server_delta(data)
	if dirty & DIRTY_METAVERSE:
		metaverse.add_server_delta(data)
	
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

