# player_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name PlayerProxy
extends Proxy

## [PlayerProxy] represents a polity, faction, or sub-entity that owns
## [FacilityProxy]s.
##
## A [PlayerProxy] aggregates component data ([OperationsNet],
## [FinancialsNet], [PopulationNet], [BiomeNet], [CyberspaceNet]) propagated
## from its facilities. It has no [InventoryNet] of its own.
##
## Server-side Player pushes changes to [PlayerProxy] and its components.
## Players are never removed during a game; an "alive" player is one with
## [member is_facilities] true.
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## To modify AI, see comments in '_base_ai.gd' files.
##
## Warning! This object lives and dies on the proxy thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.


# public read-only
var player_id := -1 ## Index into [member ProxyBus.player_proxies].
var player_class := -1 ## Player class index ([code]PlayerClasses[/code] enum).
var polity: PlayerProxy ## Self if [member player_class] == [code]PLAYER_CLASS_POLITY[/code].
var homeworld := "" ## Name of this player's homeworld body.
var is_facilities := true ## True while this player owns at least one facility ("alive" test).

## Facilities owned by this player. Resizable container — not threadsafe!
var facilities: Array[Proxy] = []

var operations := OperationsNet.new(true, true)  ## Aggregate [OperationsNet] component.
var financials := FinancialsNet.new(true)  ## Aggregate [FinancialsNet] component.
var population := PopulationNet.new(true)  ## Aggregate [PopulationNet] component.
var biome := BiomeNet.new(true)  ## Aggregate [BiomeNet] component.
var cyberspace := CyberspaceNet.new(true)  ## Aggregate [CyberspaceNet] component.

# inited identifiers resolved later
var _polity_id := -1



func _init() -> void:
	const ENTITY_PLAYER := Proxy.EntityType.ENTITY_PLAYER
	super()
	entity_type = ENTITY_PLAYER


func _clear_for_destruction() -> void:
	polity = null
	facilities.clear()


# ********************************* PROXY API *********************************

func has_development() -> bool:
	return true


func has_markets() -> bool:
	return false


func get_player_name() -> StringName:
	return name


func get_player_class() -> int:
	return player_class


func get_polity_name() -> StringName:
	return polity.name


## Returns this player's [member facilities]. proxy thread only!
func get_facilities() -> Array[Proxy]:
	return facilities


func get_development_population(population_type := -1) -> float:
	return population.get_number(population_type) + operations.get_crew(population_type)


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
	return operations.get_nominal_information() + cyberspace.get_information()


func get_development_bioproductivity() -> float:
	return biome.get_bioproductivity()


func get_development_biomass() -> float:
	return operations.get_nominal_biomass() + biome.get_biomass()


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



# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	player_id = data[2]
	name = data[3]
	gui_name = data[4]
	player_class = data[5]
	_polity_id = data[6]
	homeworld = data[7]

	var operations_data: Array = data[8]
	var financials_data: Array = data[9]
	var population_data: Array = data[10]
	var biome_data: Array = data[11]
	var cyberspace_data: Array = data[12]

	operations.set_network_init(operations_data)
	financials.set_network_init(financials_data)
	population.set_network_init(population_data)
	biome.set_network_init(biome_data)
	cyberspace.set_network_init(cyberspace_data)


func process_ai_init() -> void:
	polity = proxy_bus.player_proxies[_polity_id]
	assert(polity)


func _sync_server_dirty(data: Array) -> void:
	const DIRTY_PLAYER := Proxy.DirtyFlags.DIRTY_PLAYER
	const DIRTY_OPERATIONS := Proxy.DirtyFlags.DIRTY_OPERATIONS
	const DIRTY_FINANCIALS := Proxy.DirtyFlags.DIRTY_FINANCIALS
	const DIRTY_POPULATION := Proxy.DirtyFlags.DIRTY_POPULATION
	const DIRTY_BIOME := Proxy.DirtyFlags.DIRTY_BIOME
	const DIRTY_CYBERSPACE := Proxy.DirtyFlags.DIRTY_CYBERSPACE
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset

	#if dirty & DIRTY_QUARTER:
		#prints("NET", self)

	if dirty & DIRTY_PLAYER:
		var string_data: PackedStringArray = data[3]
		gui_name = string_data[0]
		player_class = int_data[1]
		polity = proxy_bus.player_proxies[int_data[2]]
		homeworld = string_data[1]

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

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated



## Registers [param facility] under this player. Marks the player "alive".
func add_facility(facility: Proxy) -> void:
	assert(!facilities.has(facility))
	facilities.append(facility)
	is_facilities = true


## Removes [param facility] from this player. Updates [member is_facilities]
## to reflect whether the player still owns any facilities.
func remove_facility(facility: Proxy) -> void:
	facilities.erase(facility)
	is_facilities = !facilities.is_empty()
