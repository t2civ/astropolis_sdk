# body_interface.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
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
# To get the SceenTree "body" node (class IVBody) use IVGlobal.bodies[body_name].
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
var compositions: Array[Composition] = [] # resizable container - not threadsafe!
var operations: Operations # when/if needed
var population: Population # when/if needed
var biome: Biome # when/if needed
var metaverse: Metaverse # when/if needed



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
		return operations.lfq_gross_output
	return 0.0


func get_development_energy() -> float:
	if operations:
		return operations.get_development_energy()
	return 0.0


func get_development_manufacturing() -> float:
	if operations:
		return operations.get_development_manufacturing()
	return 0.0


func get_development_constructions() -> float:
	if operations:
		return operations.constructions
	return 0.0


func get_development_computations() -> float:
	if metaverse:
		return metaverse.computations
	return 0.0


func get_development_information() -> float:
	if metaverse:
		return metaverse.get_development_information()
	return 0.0


func get_development_bioproductivity() -> float:
	if biome:
		return biome.bioproductivity
	return 0.0


func get_development_biomass() -> float:
	if biome:
		return biome.biomass
	return 0.0


func get_development_biodiversity() -> float:
	if biome:
		return biome.get_development_biodiversity()
	return 0.0


# Body specific

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


func get_composition_heterogeneities(index: int) -> Array[float]:
	return compositions[index].heterogeneities


func get_composition_survey_type(index: int) -> int:
	return compositions[index].survey_type


func get_composition_fractional_mass_uncertainty(index: int, resource_type: int) -> float:
	return compositions[index].get_fractional_mass_uncertainty(resource_type)


func get_composition_fractional_heterogeneity(index: int, resource_type: int) -> float:
	return compositions[index].get_fractional_heterogeneity(resource_type)


func get_composition_fractional_deposits(index: int, resource_type: int, zero_if_no_boost := false
		) -> float:
	return compositions[index].get_fractional_deposits(resource_type, zero_if_no_boost)


# *****************************************************************************
# sync - DON'T MODIFY!

func set_server_init(data: Array) -> void:
	body_id = data[2]
	name = data[3]
	gui_name = data[4]
	body_flags = data[5]
	solar_occlusion = data[6]
	var parent_name: String = data[7]
	if parent_name:
		parent = interfaces_by_name[parent_name]
		parent.add_satellite(self)
	var compositions_data: Array = data[8]
	var operations_data: Array = data[9]
	var population_data: Array = data[10]
	var biome_data: Array = data[11]
	var metaverse_data: Array = data[12]
	
	if compositions_data:
		var n_compositions := compositions_data.size()
		compositions.resize(n_compositions)
		var i := 0
		while i < n_compositions:
			var composition_data: Array = compositions_data[i]
			var composition := Composition.new(true)
			composition.set_server_init(composition_data)
			compositions[i] = composition
			i += 1
	if operations_data:
		operations = Operations.new(true)
		operations.set_server_init(operations_data)
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
	var dirty: int = data[0]
	var k := 1
	if dirty & DIRTY_BASE:
		gui_name = data[k]
		solar_occlusion = data[k + 1]
		k += 2
	if dirty & DIRTY_COMPOSITIONS:
		var n_compositions: int = data[k]
		k += 1
		while n_compositions > compositions.size(): # server added a Composition
			var composition := Composition.new(true)
			compositions.append(composition)
		var i := 0
		while i < n_compositions:
			var composition: Composition = compositions[i]
			k = composition.sync_server_dirty(data, k)
			i += 1


func propagate_server_delta(data: Array) -> void:
	var int_data: Array[int] = data[0]
	var dirty: int = int_data[1]
	if dirty & DIRTY_OPERATIONS:
		if !operations:
			operations = Operations.new(true)
		operations.add_server_delta(data)
	# no inventory or financials
	if dirty & DIRTY_POPULATION:
		if !population:
			population = Population.new(true)
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

