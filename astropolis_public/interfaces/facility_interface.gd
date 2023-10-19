# facility_interface.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name FacilityInterface
extends Interface

# DO NOT MODIFY THIS FILE! To modify AI, see comments in '_base_ai.gd' files.
#
# Warning! This object lives and dies on the AI thread! Containers and many
# methods are not threadsafe. Accessing non-container properties is safe.
#
# Facilities are where most of the important activity happens in Astropolis. 
# A server-side Facility object pushes changes to FacilityInterface and its
# components. FacilityInterface then propagates component changes to
# BodyInterface, PlayerInterface and any ProxyInterfaces held in 'propagations'
# array.

static var facility_interfaces: Array[FacilityInterface] = [] # indexed by facility_id

var facility_id := -1
var facility_class := -1
var public_sector: float # often 0.0 or 1.0, sometimes mixed
var has_economy: bool # ops treated as separate entities for economic measure & tax
var solar_occlusion: float # TODO: calculate from body atmosphere, body shading, etc.
var polity_name: StringName

var body: BodyInterface
var player: PlayerInterface
var proxies: Array[ProxyInterface] = []

var operations := Operations.new(true, true, true)
var inventory := Inventory.new(true)
var financials := Financials.new(true)
var population: Population # when/if needed
var biome: Biome # when/if needed
var metaverse: Metaverse # when/if needed



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


func get_total_population() -> float:
	var total_population := operations.get_crew_total()
	if population:
		total_population += population.get_number_total()
	return total_population


func get_total_population_by_type(population_type: int) -> float:
	var total_population := operations.get_crew(population_type)
	if population:
		total_population += population.get_number(population_type)
	return total_population


func get_lfq_gross_output() -> float:
	return operations.lfq_gross_output


func get_total_energy() -> float:
	return operations.get_total_energy()


func get_total_manufacturing() -> float:
	return operations.get_total_manufacturing()


func get_total_constructions() -> float:
	return operations.constructions


func get_total_computations() -> float:
	if metaverse:
		return metaverse.computations
	return 0.0


func get_information() -> float:
	if metaverse:
		return metaverse.get_information()
	return 0.0


func get_total_bioproductivity() -> float:
	if biome:
		return biome.bioproductivity
	return 0.0


func get_total_biomass() -> float:
	if biome:
		return biome.biomass
	return 0.0


func get_biodiversity() -> float:
	if biome:
		return biome.get_biodiversity()
	return 0.0



# *****************************************************************************
# sync

func set_server_init(data: Array) -> void:
	facility_id = data[2]
	name = data[3]
	gui_name = data[4]
	facility_class = data[5]
	public_sector = data[6]
	has_economy = data[7]
	solar_occlusion = data[8]
	polity_name = data[9]
	player = interfaces_by_name[data[10]]
	player.add_facility(self)
	body = interfaces_by_name[data[11]]
	body.add_facility(self)
	var proxy_names: Array = data[12]
	for proxy_name: StringName in proxy_names:
		var proxy: ProxyInterface = get_interface_by_name(proxy_name)
		assert(!proxies.has(proxy))
		proxies.append(proxy)
	
	var operations_data: Array = data[13]
	var inventory_data: Array = data[14]
	var financials_data: Array = data[15]
	var population_data: Array = data[16]
	var biome_data: Array = data[17]
	var metaverse_data: Array = data[18]
	
	operations.set_server_init(operations_data)
	inventory.set_server_init(inventory_data)
	financials.set_server_init(financials_data)
	
	if population_data:
		population = Population.new(true, true)
		population.set_server_init(population_data)
	if biome_data:
		biome = Biome.new(true)
		biome.set_server_init(biome_data)
	if metaverse_data:
		metaverse = Metaverse.new(true)
		metaverse.set_server_init(metaverse_data)


func sync_server_dirty(data: Array) -> void:
	
	var int_data: Array[int] = data[0]
	var float_data: Array[float] = data[1]
	var string_data: Array[String] = data[2]
	
	var int_offset := 14
	var float_offset := 0
	
	var dirty: int = int_data[1]
	if dirty & DIRTY_BASE:
		facility_class = data[int_offset]
		int_offset += 1
		public_sector = float_data[float_offset]
		solar_occlusion = float_data[float_offset + 1]
		float_offset += 2
		gui_name = string_data[0]
		polity_name = string_data[1]
	
	if dirty & DIRTY_OPERATIONS:
		operations.add_server_delta(data)
	if dirty & DIRTY_INVENTORY:
		inventory.add_server_delta(data)
	if dirty & DIRTY_FINANCIALS:
		financials.add_server_delta(data)
	if dirty & DIRTY_POPULATION:
		if !population:
			population = Population.new(true, true)
		population.add_server_delta(data)
	if dirty & DIRTY_BIOME:
		if !biome:
			biome = Biome.new(true)
		biome.add_server_delta(data)
	if dirty & DIRTY_METAVERSE:
		if !metaverse:
			metaverse = Metaverse.new(true)
		metaverse.add_server_delta(data)
	
	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated
	
	body.propagate_server_delta(data)
	player.propagate_server_delta(data)
	for proxy in proxies:
		proxy.propagate_server_delta(data)


func _sync_ai_changes() -> void:
	# FIXME: update data pattern
	var data := [_dirty]
	if _dirty & DIRTY_BASE:
		data.append(gui_name)
	if _dirty & DIRTY_OPERATIONS:
		data.append(operations.get_interface_dirty())
	_dirty = 0
	AIGlobal.emit_signal("interface_changed", entity_type, facility_id, data)

