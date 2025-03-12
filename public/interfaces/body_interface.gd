# body_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name BodyInterface
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
# To get the SceenTree "body" node (class IVBody) use IVBody.bodies[body_name].
# Be aware that SceenTree works on the Main thread!

static var body_interfaces: Array[BodyInterface] = [] # indexed by body_id

var body_id := -1
var body_flags := 0
var solar_occlusion: float # TODO: replace w/ atmospheric condition
var is_satellites := false
var is_facilities := false

var parent: BodyInterface # null for top body

var satellites: Array[BodyInterface] = [] # resizable container - not threadsafe!
var facilities: Array[Interface] = [] # resizable container - not threadsafe!

var operations: OperationsNet # when/if needed
var population: PopulationNet # when/if needed
var biome: BiomeNet # when/if needed
var cyberspace: CyberspaceNet # when/if needed
var marketplace: MarketplaceNet # when/if needed
var compositions: Array[CompositionNet] = [] # resizable container - not threadsafe!



func _init() -> void:
	super()
	entity_type = ENTITY_BODY


func _clear_circular_references() -> void:
	# down hierarchy only
	satellites.clear()
	facilities.clear()


# *****************************************************************************
# interface API


func has_development() -> bool:
	return is_facilities


func has_markets() -> bool:
	return false


func get_body_name() -> StringName:
	return name


func get_body_flags() -> int:
	return body_flags


func get_facilities() -> Array[Interface]:
	# AI thread only!
	return facilities


func get_development_population(population_type := -1) -> float:
	var total := 0.0
	if population:
		total = population.get_number(population_type)
	if operations:
		total += operations.get_crew(population_type)
	return total


func get_development_economy() -> float:
	if operations:
		return operations.get_gross_output_lfq()
	return 0.0


func get_development_energy_use() -> float:
	if operations:
		return operations.get_energy_use()
	return 0.0


func get_development_construction() -> float:
	if operations:
		return operations.get_construction()
	return 0.0


func get_development_built_mass() -> float:
	if operations:
		return operations.get_built_mass()
	return 0.0


func get_development_computation() -> float:
	if operations:
		return operations.get_total_computation()
	return 0.0


func get_development_information() -> float:
	var total := 0.0
	if operations:
		total += operations.get_nominal_information()
	if cyberspace:
		total += cyberspace.get_information()
	return total


func get_development_bioproductivity() -> float:
	if biome:
		return biome.get_bioproductivity()
	return 0.0


func get_development_biomass() -> float:
	var total := 0.0
	if operations:
		total += operations.get_nominal_biomass()
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
	return operations # possible null


func get_population() -> PopulationNet:
	return population # possible null


func get_biome() -> BiomeNet:
	return biome # possible null


func get_cyberspace() -> CyberspaceNet:
	return cyberspace # possible null


func get_marketplace(_player_id: int) -> MarketplaceNet:
	# TODO: alt_market for blockaded player
	return marketplace # possible null


# Marketplace

func get_marketplace_price(type: int) -> float:
	return marketplace.get_price(type)


# Compositions

func has_compositions() -> bool:
	return !compositions.is_empty()


func get_n_compositions() -> int:
	return compositions.size()


func get_composition_name(index: int) -> StringName:
	return compositions[index].name


func get_composition_polity(index: int) -> StringName:
	return compositions[index].polity_name


func get_composition_density(index: int) -> float:
	return compositions[index].density


func get_composition_stratum_type(index: int) -> int:
	return compositions[index].stratum_type


func get_compostion_thickness(index: int) -> float:
	return compositions[index].thickness


func get_composition_volume(index: int) -> float:
	return compositions[index].get_volume()


func get_composition_total_mass(index: int) -> float:
	return compositions[index].get_total_mass()


func get_compostion_body_radius(index: int) -> float:
	# TODO: depreciate this after we have access to IVBody properties
	return compositions[index].body_radius


func get_composition_masses(index: int) -> Array[float]:
	return compositions[index].masses


func get_composition_variances(index: int) -> Array[float]:
	return compositions[index].variances


func get_composition_survey_type(index: int) -> int:
	return compositions[index].survey_type


func get_composition_mass_error_fraction(index: int, resource_type: int) -> float:
	return compositions[index].get_mass_error_fraction(resource_type)


func get_composition_variance(index: int, resource_type: int) -> float:
	return compositions[index].get_variance(resource_type)


func get_composition_variance_fraction(index: int, resource_type: int) -> float:
	return compositions[index].get_variance_fraction(resource_type)


func get_composition_deposit_fraction(index: int, resource_type: int, zero_if_no_boost := false
		) -> float:
	return compositions[index].get_deposit_fraction(resource_type, zero_if_no_boost)


# *****************************************************************************
# sync - DON'T MODIFY!

func set_network_init(data: Array) -> void:
	body_id = data[2]
	name = data[3]
	gui_name = data[4]
	body_flags = data[5]
	solar_occlusion = data[6]
	var parent_name: String = data[7]
	if parent_name:
		parent = interfaces_by_name[parent_name]
		parent.add_satellite(self)
	var operations_data: Array = data[8]
	var population_data: Array = data[9]
	var biome_data: Array = data[10]
	var cyberspace_data: Array = data[11]
	var marketplace_data: Array = data[12]
	var compositions_data: Array = data[13]
	
	if operations_data:
		operations = OperationsNet.new(true)
		operations.set_network_init(operations_data)
	if population_data:
		population = PopulationNet.new(true)
		population.set_network_init(population_data)
	if biome_data:
		biome = BiomeNet.new(true)
		biome.set_network_init(biome_data)
	if cyberspace_data:
		cyberspace = CyberspaceNet.new(true)
		cyberspace.set_network_init(cyberspace_data)
	if marketplace_data:
		marketplace = MarketplaceNet.new(true)
		marketplace.set_network_init(marketplace_data)
	if compositions_data:
		var n_compositions := compositions_data.size()
		compositions.resize(n_compositions)
		var i := 0
		while i < n_compositions:
			var composition_data: Array = compositions_data[i]
			var composition := CompositionNet.new(true)
			composition.set_network_init(composition_data)
			compositions[i] = composition
			i += 1
	

func sync_server_dirty(data: Array) -> void:
	
	var offsets: Array[int] = data[0]
	var int_data: Array[int] = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset
	
	if dirty & DIRTY_BASE:
		var float_data: Array[float] = data[2]
		var string_data: Array[String] = data[3]
		gui_name = string_data[0]
		solar_occlusion = float_data[0]
	
	if dirty & DIRTY_OPERATIONS:
		if !operations:
			operations = OperationsNet.new(true)
		operations.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_POPULATION:
		if !population:
			population = PopulationNet.new(true)
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
		k += 3
	if dirty & DIRTY_MARKETPLACE:
		if !marketplace:
			marketplace = MarketplaceNet.new(true)
		marketplace.add_dirty(data, offsets[k], offsets[k + 1])
		k += 2
	if dirty & DIRTY_COMPOSITIONS:
		var dirty_compositions := offsets[k]
		k += 1
		var i := 0
		while dirty_compositions:
			if dirty_compositions & 1:
				var composition: CompositionNet = compositions[i]
				composition.add_dirty(data, offsets[k], offsets[k + 1])
				k += 2
			i += 1
			dirty_compositions >>= 1
	
	
	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated


func add_satellite(satellite: BodyInterface) -> void:
	assert(!satellites.has(satellite))
	satellites.append(satellite)
	is_satellites = true


func remove_satellite(satellite: BodyInterface) -> void:
	satellites.erase(satellite)
	is_satellites = !satellites.is_empty()


func add_facility(facility: Interface) -> void:
	assert(!facilities.has(facility))
	facilities.append(facility)
	is_facilities = true


func remove_facility(facility: Interface) -> void:
	facilities.erase(facility)
	is_facilities = !facilities.is_empty()
