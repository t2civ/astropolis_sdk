# proxy_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ProxyInterface
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
# Proxies represent collections of facilites that may be useful for GUI data
# display or possibly AI. Init and and data sync originate from
# FacilityInterface (unlike other Interfaces, there is no corresponding server
# object).
#
# See FacilityInterface._add_proxies() for existing proxies. Override this
# method to add or modify.

static var proxy_interfaces: Array[ProxyInterface] = [] # indexed by proxy_id

var operations: Operations # always created on server init
var inventory: Inventory # on server init or never
var financials: Financials # on server init or never
var population: Population # on server init or never
var biome: Biome # on server init or never
var metaverse: Metaverse # on server init or never

# read-only!
var proxy_id := -1



func _init() -> void:
	super()
	entity_type = ENTITY_PROXY


# *****************************************************************************
# interface API

func has_development() -> bool:
	return true


func has_markets() -> bool:
	return inventory != null
	

func get_development_population(population_type := -1) -> float:
	var total := operations.get_crew(population_type)
	if population:
		total += population.get_number(population_type)
	return total


func get_development_economy() -> float:
	return operations.get_lfq_gross_output()


func get_development_energy() -> float:
	return operations.get_development_energy()


func get_development_manufacturing() -> float:
	return operations.get_development_manufacturing()


func get_development_constructions() -> float:
	return operations.get_constructions()


func get_development_computations() -> float:
	if metaverse:
		return metaverse.get_computations()
	return 0.0


func get_development_information() -> float:
	if metaverse:
		return metaverse.get_development_information()
	return 0.0


func get_development_bioproductivity() -> float:
	if biome:
		return biome.get_bioproductivity()
	return 0.0


func get_development_biomass() -> float:
	if biome:
		return biome.get_biomass()
	return 0.0


func get_development_biodiversity() -> float:
	if biome:
		return biome.get_development_biodiversity()
	return 0.0


# *****************************************************************************
# sync - DON'T MODIFY!

func set_server_init(data: Array) -> void:
	proxy_id = data[2]
	name = data[3]
	gui_name = data[4]
	var operations_data: Array = data[5]
	var inventory_data: Array = data[6]
	var financials_data: Array = data[7]
	var population_data: Array = data[8]
	var biome_data: Array = data[9]
	var metaverse_data: Array = data[10]
	operations = Operations.new(true, !financials_data.is_empty())
	operations.set_server_init(operations_data)
	if inventory_data:
		inventory = Inventory.new(true)
		inventory.set_server_init(inventory_data)
	if financials_data:
		financials = Financials.new(true)
		financials.set_server_init(financials_data)
	if population_data:
		population = Population.new(true)
		population.set_server_init(population_data)
	if biome_data:
		biome = Biome.new(true)
		biome.set_server_init(biome_data)
	if metaverse_data:
		metaverse = Metaverse.new(true)
		metaverse.set_server_init(metaverse_data)


func sync_server_dirty(data: Array) -> void:
	
	var offsets: Array[int] = data[0]
	var int_data: Array[int] = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset
	
	if dirty & DIRTY_OPERATIONS:
		operations.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_INVENTORY:
		inventory.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_FINANCIALS:
		financials.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_POPULATION:
		population.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_BIOME:
		biome.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_METAVERSE:
		metaverse.add_dirty(data, offsets[k], offsets[k + 1])
	
	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated

