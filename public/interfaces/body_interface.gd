# body_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name BodyInterface
extends Interface

## [BodyInterface] represents a celestial body in the simulation, hosting
## facilities and aggregating their stats.
##
## A [BodyInterface] aggregates component data ([OperationsNet],
## [PopulationNet], [BiomeNet], [CyberspaceNet]) propagated from its
## facilities, and exposes its [StratumNet] composition (atmosphere,
## surface, subsurface). It owns an [ExchangeInterface] when there are 2+
## facilities at this body.
##
## Server-side Body pushes changes to [BodyInterface] and its components.
##
## To get the corresponding scene-tree [code]IVBody[/code] node use
## [code]IVBody.bodies[body_name][/code]. Be aware that the SceneTree runs
## on the main thread!
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## To modify AI, see comments in '_base_ai.gd' files.
##
## Warning! This object lives and dies on the AI thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.


## All [BodyInterface] instances, indexed by [member body_id].
static var body_interfaces: Array[BodyInterface] = []

var body_id := -1  ## Index into [member body_interfaces].
var body_flags := 0  ## Body flags from [code]IVBody.BodyFlags[/code].
var solar_occlusion: float  ## Average solar irradiance occlusion at this body.
var is_satellites := false  ## True while this body has at least one satellite.
var is_facilities := false  ## True while this body hosts at least one facility.

var parent: BodyInterface  ## Parent body, or null for the top body.

## Direct satellites of this body, keyed by name. Resizable container — not
## threadsafe!
var satellites: Dictionary[StringName, BodyInterface]
## Facilities at this body. Resizable container — not threadsafe!
var facilities: Array[Interface] = []

var operations: OperationsNet  ## Aggregate [OperationsNet] (null when absent).
var population: PopulationNet  ## Aggregate [PopulationNet] (null when absent).
var biome: BiomeNet  ## Aggregate [BiomeNet] (null when absent).
var cyberspace: CyberspaceNet  ## Aggregate [CyberspaceNet] (null when absent).
## [ExchangeInterface] for this body. Null unless this body has 2+ facilities.
var exchange: ExchangeInterface
## [StratumNet] composition layers (atmosphere, surface, subsurface).
## Resizable container — not threadsafe!
var strata: Array[StratumNet] = []



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


## Returns this body's [member facilities]. AI thread only!
func get_facilities() -> Array[Interface]:
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


func get_development_power() -> float:
	if operations:
		return operations.get_power()
	return 0.0


func get_development_manufacturing() -> float:
	if operations:
		return operations.get_total_manufacturing()
	return 0.0


func get_development_constructions() -> float:
	if operations:
		return operations.get_constructions()
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


func get_exchange() -> ExchangeInterface:
	return exchange # possible null


# Strata

## Returns true if this body has any [StratumNet] composition layers.
func has_strata() -> bool:
	return !strata.is_empty()


## Returns the number of [StratumNet] composition layers on this body.
func get_n_strata() -> int:
	return strata.size()


## Returns the name of the [StratumNet] at [param index].
func get_stratum_name(index: int) -> StringName:
	return strata[index].name


## Returns the polity name of the [StratumNet] at [param index]
## ([code]&""[/code] for commons strata).
func get_stratum_polity(index: int) -> StringName:
	return strata[index].polity_name


## Returns the density of the [StratumNet] at [param index].
func get_stratum_density(index: int) -> float:
	return strata[index].density


## Returns the stratum-group index of the [StratumNet] at [param index].
func get_stratum_stratum_type(index: int) -> int:
	return strata[index].stratum_group


## Returns the thickness of the [StratumNet] at [param index].
func get_compostion_thickness(index: int) -> float:
	return strata[index].thickness


## Returns the volume of the [StratumNet] at [param index].
func get_stratum_volume(index: int) -> float:
	return strata[index].get_volume()


## Returns the total mass of the [StratumNet] at [param index].
func get_stratum_total_mass(index: int) -> float:
	return strata[index].get_total_mass()


## Returns the body radius cached on the [StratumNet] at [param index].
func get_compostion_body_radius(index: int) -> float:
	return strata[index].body_radius


## Returns the per-resource mass array for the [StratumNet] at [param index].
func get_stratum_masses(index: int) -> Array[float]:
	return strata[index].masses


## Returns the per-resource dispersion array for the [StratumNet] at
## [param index].
func get_stratum_dispersions(index: int) -> Array[float]:
	return strata[index].dispersions


## Returns the survey-type index for the [StratumNet] at [param index].
func get_stratum_survey_type(index: int) -> int:
	return strata[index].survey_type


## Returns survey/discovery data for [param resource_type] in the
## [StratumNet] at [param index].
func get_stratum_resource_data(index: int, resource_type: int) -> Array[float]:
	return strata[index].get_resource_data(resource_type)


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
	var strata_data: Array = data[12]

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
	if strata_data:
		var n_strata := strata_data.size()
		strata.resize(n_strata)
		var i := 0
		while i < n_strata:
			var stratum_data: Array = strata_data[i]
			var stratum := StratumNet.new(true)
			stratum.set_network_init(stratum_data)
			strata[i] = stratum
			i += 1
	

func sync_server_dirty(data: Array) -> void:
	const SIGN_BIT := 1 << 63
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
	if dirty & DIRTY_STRATA:
		var flag_index := 0
		var more_dirty := 1
		while more_dirty:
			var dirty_strata := offsets[k]
			k += 1
			more_dirty = dirty_strata & SIGN_BIT
			dirty_strata &= ~SIGN_BIT
			var i := flag_index * 63
			while dirty_strata:
				if dirty_strata & 1:
					var stratum := strata[i]
					stratum.add_dirty(data, offsets[k], offsets[k + 1])
					k += 2
				i += 1
				dirty_strata >>= 1
			flag_index += 1
		
		
		
		
		
		#var dirty_strata_1 := offsets[k]
		#k += 1
		#var i := 0
		#while dirty_strata_1:
			#if dirty_strata_1 & 1:
				#var stratum := strata[i]
				#stratum.add_dirty(data, offsets[k], offsets[k + 1])
				#k += 2
			#i += 1
			#dirty_strata_1 >>= 1
		#var dirty_strata_2 := offsets[k]
		#k += 1
		#i = 63
		#while dirty_strata_2:
			#if dirty_strata_2 & 1:
				#var stratum := strata[i]
				#stratum.add_dirty(data, offsets[k], offsets[k + 1])
				#k += 2
			#i += 1
			#dirty_strata_2 >>= 1
	
	
	assert(int_data[0] >= run_qtr)
	if int_data[0] > run_qtr:
		if run_qtr == -1:
			run_qtr = int_data[0]
		else:
			run_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated


## Registers [param satellite] under this body. Updates [member is_satellites].
func add_satellite(satellite: BodyInterface) -> void:
	assert(!satellites.has(satellite.name))
	satellites[satellite.name] = satellite
	is_satellites = true


## Removes [param satellite] from this body. Updates [member is_satellites].
func remove_satellite(satellite: BodyInterface) -> void:
	satellites.erase(satellite.name)
	is_satellites = !satellites.is_empty()


## Registers [param facility] at this body. Updates [member is_facilities].
func add_facility(facility: Interface) -> void:
	assert(!facilities.has(facility))
	facilities.append(facility)
	is_facilities = true


## Removes [param facility] from this body. Updates [member is_facilities].
func remove_facility(facility: Interface) -> void:
	facilities.erase(facility)
	is_facilities = !facilities.is_empty()
