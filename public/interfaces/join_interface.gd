# join_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name JoinInterface
extends Interface

## Provides GUI and AI data interface (read only!) for a server 'Join' object,
## which joins component data from Facilities, Bodies and other Joins. 
##
## Joins handle 5 components (Operations, Financials, Population, Biome and
## Cyberspace) that ultimately derive all data from Facilities. Note that Body
## and Player objects also act as Joins for these components.[br][br]
##
## There are two hard-coded Joins and the rest are procedurally made. They are
## connected in tree-structures with Facilities, Bodies and Players as follows:
##
## [codeblock]
## JOIN_OFFWORLD (<-data from all non-homeworld Bodies)
##
## JOIN_ALL (<-data from the next 4 Join types)
## JOIN_<star>_PLANETS (<-data from planet Bodies)
## JOIN_<star>_MOONS (<-data from JOIN_<planet>_MOONS below)
## JOIN_<star>_SPACE (<-data from JOIN_<planet>_SPACE below & non-planet spacecraft)
## JOIN_<star>_PLANETOIDS (<-data from planetoid Bodies; ie, not planet, moon or spacecraft)
##
## <body> (<-data from self Facilities)
## JOIN_<planet>_MOONS (<-data from all moon Bodies of a planet)
## JOIN_<planet>_SPACE (<-data from all spacecraft Bodies of a planet)
##
## JOIN_<star>_PLANETS_<player> (<-data from planet Facilities for Player)
## JOIN_<star>_MOONS_<player> (<-data from JOIN_<planet>_MOONS_<player> below)
## JOIN_<star>_SPACE_<player> (<-data from JOIN_<planet>_SPACE_<player> & non-planet spacecraft)
## JOIN_<star>_PLANETOIDS_<player> (<-data from planetoid Facilities for Player)
##
## JOIN_<planet>_MOONS_<player> (<-data from all moon Facilities of a planet for Player)
## JOIN_<planet>_SPACE_<player> (<-data from all spacecraft Facilities of a planet for Player)
## [/codeblock]
##
## Notes:[br]
## 1. '<star>' = 'STAR_SUN' for our solar system, but should handle multistar systems.[br]
## 2. '<planet>' = 'PLANET_EARTH', 'PLANET_JUPITER', etc. These include dwarf planets.[br]
## 3. 'Moons' only includes moons of planets (or dwarf planets).[br]
## 4. 'Planetoids' are any Body that is not a planet, moon or spacecraft.[br]
## 5. 'spacecraft Bodies of a planet' include any spacecraft 'under' the planet,
##    e.g., a spacecraft orbiting a moon of the planet.[br]
## 6. Not all joined data is a simple sum. E.g., 'information' and 'biodiversity'
##    account for [url=https://en.wikipedia.org/wiki/Mutual_information]mutual
##    information[/url].[br]
## 7. Procedural Joins are created only when needed. E.g., they don't exist for
##    planets that don't yet have associated Facilities.[br]
## 8. Financials is only propagated on player-specific branches.[br][br]
##
## SDK Notes:[br]
## 1. To create or extend an AI, see comments in '_base_ai.gd' files.[br]
## 2. Warning! To optimize for AI access, this object lives and dies on the AI
##    thread. For GUI, use thread call methods for unsafe container access.[br]
## 3. This class will be ported to C++ becoming a GDExtension class. You
##    will have access to API (just like any Godot class) but the GDScript class
##    will be removed.

static var join_interfaces: Array[JoinInterface] = [] # indexed by join_id

var operations: OperationsNet # always
var financials: FinancialsNet # only player-specific Joins
var population: PopulationNet # always
var biome: BiomeNet # always
var cyberspace: CyberspaceNet # always

# read-only!
var join_id := -1



func _init() -> void:
	super()
	entity_type = ENTITY_JOIN


# *****************************************************************************
# interface API

func has_development() -> bool:
	return true


func has_markets() -> bool:
	return false


func get_development_population(population_type := -1) -> float:
	var total := operations.get_crew(population_type)
	if population:
		total += population.get_number(population_type)
	return total


func get_development_economy() -> float:
	return operations.get_gross_output_lfq()


func get_development_power() -> float:
	return operations.get_power()


func get_development_manufacturing() -> float:
	return operations.get_total_manufacturing()


func get_development_constructions() -> float:
	return operations.get_constructions()


func get_development_computation() -> float:
	return operations.get_total_computation()


func get_development_information() -> float:
	var total := operations.get_nominal_information()
	if cyberspace:
		total += cyberspace.get_information()
	return total


func get_development_bioproductivity() -> float:
	if biome:
		return biome.get_bioproductivity()
	return 0.0


func get_development_biomass() -> float:
	var total := operations.get_nominal_biomass()
	if biome:
		total += biome.get_biomass()
	return total


func get_development_biodiversity() -> float:
	if biome:
		var biodiversity := biome.get_biodiversity()
		if biodiversity == 1.0 and get_development_population() == 0.0:
			return 0.0 
		return biodiversity
	return 0.0


# Components

func get_operations() -> OperationsNet:
	return operations


func get_financials() -> FinancialsNet:
	return financials # possible null


func get_population() -> PopulationNet:
	return population


func get_biome() -> BiomeNet:
	return biome


func get_cyberspace() -> CyberspaceNet:
	return cyberspace


# *****************************************************************************
# sync - DON'T MODIFY!

func set_network_init(data: Array) -> void:
	join_id = data[2]
	name = data[3]
	gui_name = data[4]
	var operations_data: Array = data[5]
	var financials_data: Array = data[6]
	var population_data: Array = data[7]
	var biome_data: Array = data[8]
	var cyberspace_data: Array = data[9]
	operations = OperationsNet.new(true, !financials_data.is_empty())
	operations.set_network_init(operations_data)
	if financials_data:
		financials = FinancialsNet.new(true)
		financials.set_network_init(financials_data)
	population = PopulationNet.new(true)
	population.set_network_init(population_data)
	biome = BiomeNet.new(true)
	biome.set_network_init(biome_data)
	cyberspace = CyberspaceNet.new(true)
	cyberspace.set_network_init(cyberspace_data)


func sync_server_dirty(data: Array) -> void:
	
	var offsets: Array[int] = data[0]
	var int_data: Array[int] = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset
	
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
