# facility_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name FacilityInterface
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
# Facilities are where most of the important activity happens in Astropolis. 
# A server-side Facility object pushes changes to FacilityInterface and its
# components.

static var facility_interfaces: Array[FacilityInterface] = [] # indexed by facility_id

var facility_id := -1
var facility_class := -1
var public_sector: float # often 0.0 or 1.0, sometimes mixed
var is_unitary: bool # is small focused activity for stats & tax treatment
var solar_occlusion: float # TODO: calculate from body atmosphere, body shading, etc.
var polity_name: StringName

var body: BodyInterface
var player: PlayerInterface
var joins: Array[JoinInterface] = []

var operations := OperationsNet.new(true, true, true)
var inventory := InventoryNet.new(true)
var financials := FinancialsNet.new(true)
var population: PopulationNet # when/if needed
var biome: BiomeNet # when/if needed
var cyberspace: CyberspaceNet # when/if needed



func _init() -> void:
	super()
	entity_type = ENTITY_FACILITY


#func process_ai_interval(_delta: float) -> void:
#	prints(name, operations.capacities[0])



# *****************************************************************************
# interface API

func remove() -> void:
	body.remove_facility(self)
	player.remove_facility(self)


func set_gui_name(new_gui_name: String) -> void:
	_dirty |= DIRTY_BASE
	gui_name = new_gui_name


func has_development() -> bool:
	return true


func has_markets() -> bool:
	return true


func get_body_name() -> StringName:
	return body.name


func get_body_flags() -> int:
	return body.body_flags


func get_player_name() -> StringName:
	return player.name


func get_player_class() -> int:
	return player.player_class


func get_polity_name() -> StringName:
	return polity_name


func get_development_population(population_type := -1) -> float:
	var total := operations.get_crew(population_type)
	if population:
		total += population.get_number(population_type)
	return total


func get_development_economy() -> float:
	return operations.get_gross_output_lfq()


func get_development_energy() -> float:
	return operations.get_energy_rate()


func get_development_manufacturing() -> float:
	return operations.get_manufacturing_rate()


func get_development_construction() -> float:
	return operations.get_construction_mass()


func get_development_computation() -> float:
	return operations.get_total_computation()


func get_development_information() -> float:
	if cyberspace:
		return cyberspace.get_information()
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
		var biodiversity := biome.get_biodiversity()
		if biodiversity == 1.0 and get_development_population() == 0.0:
			return 0.0 
		return biodiversity
	return 0.0


# Components

func get_operations() -> OperationsNet:
	return operations


func get_inventory() -> InventoryNet:
	return inventory


func get_financials() -> FinancialsNet:
	return financials


func get_population() -> PopulationNet:
	return population # possible null


func get_biome() -> BiomeNet:
	return biome # possible null


func get_cyberspace() -> CyberspaceNet:
	return cyberspace # possible null


func get_marketplace(player_id: int) -> MarketplaceNet:
	return body.get_marketplace(player_id) # possible null


# *****************************************************************************
# sync

func set_network_init(data: Array) -> void:
	facility_id = data[2]
	name = data[3]
	gui_name = data[4]
	facility_class = data[5]
	public_sector = data[6]
	is_unitary = data[7]
	solar_occlusion = data[8]
	polity_name = data[9]
	player = interfaces_by_name[data[10]]
	player.add_facility(self)
	body = interfaces_by_name[data[11]]
	body.add_facility(self)
	var join_names: Array = data[12]
	for join_name: StringName in join_names:
		var join: JoinInterface = get_interface_by_name(join_name)
		assert(!joins.has(join))
		joins.append(join)
	
	var operations_data: Array = data[13]
	var inventory_data: Array = data[14]
	var financials_data: Array = data[15]
	var population_data: Array = data[16]
	var biome_data: Array = data[17]
	var cyberspace_data: Array = data[18]
	
	operations.set_network_init(operations_data)
	inventory.set_network_init(inventory_data)
	financials.set_network_init(financials_data)
	
	if population_data:
		population = PopulationNet.new(true, true)
		population.set_network_init(population_data)
	if biome_data:
		biome = BiomeNet.new(true)
		biome.set_network_init(biome_data)
	if cyberspace_data:
		cyberspace = CyberspaceNet.new(true)
		cyberspace.set_network_init(cyberspace_data)


func sync_server_dirty(data: Array) -> void:
	
	var offsets: Array[int] = data[0]
	var int_data: Array[int] = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset
	
	if dirty & DIRTY_BASE:
		var float_data: Array[float] = data[2]
		var string_data: Array[String] = data[3]
		facility_class = int_data[1]
		is_unitary = bool(int_data[2])
		public_sector = float_data[0]
		solar_occlusion = float_data[1]
		gui_name = string_data[0]
		polity_name = string_data[1]
	
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
		if !population:
			population = PopulationNet.new(true, true)
		population.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_BIOME:
		if !biome:
			biome = BiomeNet.new(true)
		biome.add_dirty(data, offsets[k], offsets[k + 1])
		k += 3
	if dirty & DIRTY_CYBERSPACE:
		if !cyberspace:
			cyberspace = CyberspaceNet.new(true)
		cyberspace.add_dirty(data, offsets[k], offsets[k + 1])
	
	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated



func _sync_ai_changes() -> void:
	# FIXME: update data pattern
	var data := [_dirty]
	if _dirty & DIRTY_BASE:
		data.append(gui_name)
	if _dirty & DIRTY_OPERATIONS:
		data.append(operations.get_interface_dirty())
	_dirty = 0
	AIGlobal.emit_signal("interface_changed", entity_type, facility_id, data)

