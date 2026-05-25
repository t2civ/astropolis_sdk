# facility_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name FacilityProxy
extends Proxy

## [FacilityProxy] represents a Player's development at a Body (see
## [PlayerProxy] and [BodyProxy]).
##
## A Facility runs operations enabled by modules (see corresponding data
## tables). A [FacilityProxy] has required components [OperationsNet],
## [InventoryNet] and [FinancialsNet], and optional components [PopulationNet],
## [BiomeNet], and [CyberspaceNet].
##
## Server-side Facility pushes changes to [FacilityProxy] and its components.
## A few "player control" properties have reverse proxy -> server data flow.
##
## SDK Note: This class will be ported to C++ becoming a GDExtension class. You
## will have access to API (just like any Godot class) but the GDScript class
## will be removed.
##
## To modify AI, see comments in '_base_ai.gd' files.
##
## Warning! This object lives and dies on the proxy thread! Containers and many
## methods are not threadsafe. Accessing non-container properties is safe.

var facility_id := -1  ## Index into [member ProxyBus.facility_proxies].
var facility_class := -1  ## Facility class index. Not implemented yet.
var trader_id := -1  ## [member TraderProxy.trader_id] of this facility's paired trader.
## Public-sector share of this facility, often 0.0 or 1.0, sometimes mixed.
var public_sector: float
## True if this is a small focused activity (affects stats and tax treatment).
var is_unitary: bool
## True if all resource streams flow from/to inventory (no atmosphere/surface
## market).
var closed_cycle_ops: bool
## Fraction of solar irradiance occluded at this site (0.0–1.0).
var solar_occlusion: float
## Time horizon used by AI and automations (inventory reserves, resupply, etc.).
var time_horizon: float
var polity_name: StringName  ## Name of the polity this facility belongs to.

var player: PlayerProxy  ## Owning [PlayerProxy].
var body: BodyProxy  ## Hosting [BodyProxy].
var trader: TraderProxy  ## Paired [TraderProxy]; set when TraderProxy registers.
var joins: Array[JoinProxy] = []  ## [JoinProxy] aggregates this facility belongs to.
var market: MarketProxy  ## Set after init. Lives on markets thread!

var operations := OperationsNet.new(true, true, true)  ## [OperationsNet] component.
var inventory := InventoryNet.new(true)  ## [InventoryNet] component.
var financials := FinancialsNet.new(true)  ## [FinancialsNet] component.
var population: PopulationNet  ## Optional [PopulationNet] component (null when absent).
var biome: BiomeNet  ## Optional [BiomeNet] component (null when absent).
var cyberspace: CyberspaceNet  ## Optional [CyberspaceNet] component (null when absent).

## Body texture cached for [code]IVSelectionManager[/code] (currently the
## hosting body's [code]IVBody.texture_2d[/code]).
var texture_2d: Texture2D

# inited identifiers resolved later
var _player_id := -1
var _body_id := -1
var _join_ids: PackedInt32Array
var _market_id := -1


func _init() -> void:
	const ENTITY_FACILITY := Proxy.EntityType.ENTITY_FACILITY
	super()
	entity_type = ENTITY_FACILITY


func _clear_for_destruction() -> void:
	body = null
	player = null
	trader = null
	joins.clear()
	market = null
	texture_2d = null


#func process_ai_interval(_delta: float) -> void:
#	prints(name, operations.capacities[0])



# ********************************* PROXY API *********************************

## Detaches this facility from its body and player, then breaks its outgoing
## refs via [method super.remove]. Called by the server side at runtime when a
## facility is removed mid-game.
func remove() -> void:
	body.remove_facility(self)
	player.remove_facility(self)
	super.remove()


## Sets [member gui_name] and marks the proxy dirty. Reverse-flow:
## proxy -> server.
func set_gui_name(new_gui_name: String) -> void:
	const DIRTY_FACILITY := Proxy.DirtyFlags.DIRTY_FACILITY
	_dirty |= DIRTY_FACILITY
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


# Operations (proxy-authoritative; reverse data flow proxy -> server)

## Sets the op command for [param type]. Proxy-authoritative: this change
## flows proxy -> server.
func set_operations_op_command(type: int, command: int) -> void:
	const DIRTY_OPERATIONS := Proxy.DirtyFlags.DIRTY_OPERATIONS
	if operations.set_op_command(type, command):
		_dirty |= DIRTY_OPERATIONS


## Sets the target utilization for [param type]. Proxy-authoritative:
## this change flows proxy -> server.
func set_operations_target_utilization(type: int, value: float) -> void:
	const DIRTY_OPERATIONS := Proxy.DirtyFlags.DIRTY_OPERATIONS
	if operations.set_target_utilization(type, value):
		_dirty |= DIRTY_OPERATIONS


# Components

func get_operations() -> OperationsNet:
	return operations


func get_inventory() -> InventoryNet:
	return inventory


func get_financials() -> FinancialsNet:
	return financials


func get_population() -> PopulationNet:
	return population


func get_biome() -> BiomeNet:
	return biome


func get_cyberspace() -> CyberspaceNet:
	return cyberspace


## Returns this facility's spot [MarketProxy], or null if not yet set.
## [param _player_id] is unused for direct-routed facilities; the per-player
## sanctions routing happens at the Broker layer.
@warning_ignore("shadowed_variable")
func get_market(_player_id: int) -> MarketProxy:
	return market


# ********************************** SYNC *************************************

func set_network_init(data: Array) -> void:
	facility_id = data[2]
	name = data[3]
	gui_name = data[4]
	facility_class = data[5]
	public_sector = data[6]
	is_unitary = data[7]
	closed_cycle_ops = data[8]
	solar_occlusion = data[9]
	time_horizon = data[10]
	polity_name = data[11]
	_player_id = data[12]
	_body_id = data[13]
	_join_ids = data[14]
	_market_id = data[15]

	var operations_data: Array = data[16]
	var inventory_data: Array = data[17]
	var financials_data: Array = data[18]
	var population_data: Array = data[19]
	var biome_data: Array = data[20]
	var cyberspace_data: Array = data[21]

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


func process_ai_init() -> void:
	player = proxy_bus.player_proxies[_player_id]
	assert(player)
	player.add_facility(self)
	body = proxy_bus.body_proxies[_body_id]
	assert(body)
	body.add_facility(self)
	for join_id in _join_ids:
		var join: JoinProxy = proxy_bus.join_proxies[join_id]
		assert(join)
		assert(!joins.has(join))
		joins.append(join)
	if _market_id != -1:
		market = proxy_bus.market_proxies[_market_id]
		assert(market)
	# IVSelectionManager
	var ivbody := IVBody.bodies[body.name]
	texture_2d = ivbody.texture_2d


func _sync_server_dirty(data: Array) -> void:
	const DIRTY_FACILITY := Proxy.DirtyFlags.DIRTY_FACILITY
	const DIRTY_OPERATIONS := Proxy.DirtyFlags.DIRTY_OPERATIONS
	const DIRTY_INVENTORY := Proxy.DirtyFlags.DIRTY_INVENTORY
	const DIRTY_FINANCIALS := Proxy.DirtyFlags.DIRTY_FINANCIALS
	const DIRTY_POPULATION := Proxy.DirtyFlags.DIRTY_POPULATION
	const DIRTY_BIOME := Proxy.DirtyFlags.DIRTY_BIOME
	const DIRTY_CYBERSPACE := Proxy.DirtyFlags.DIRTY_CYBERSPACE
	var offsets: PackedInt64Array = data[0]
	var int_data: PackedInt64Array = data[1]
	var dirty: int = offsets[0]
	var k := 1 # offsets offset

	if dirty & DIRTY_FACILITY:
		var float_data: PackedFloat64Array = data[2]
		var string_data: PackedStringArray = data[3]
		facility_class = int_data[1]
		is_unitary = bool(int_data[2])
		closed_cycle_ops = bool(int_data[3])
		var market_id: int = int_data[4]
		market = proxy_bus.market_proxies[market_id] if market_id != -1 else null
		public_sector = float_data[0]
		solar_occlusion = float_data[1]
		time_horizon = float_data[2]
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

	assert(int_data[0] >= ordinal_qtr)
	if int_data[0] > ordinal_qtr:
		if ordinal_qtr == -1:
			ordinal_qtr = int_data[0]
		else:
			ordinal_qtr = int_data[0]
			process_ai_new_quarter() # after component histories have updated


func _sync_ai_changes() -> void:
	# Only here if _dirty != 0.
	const DIRTY_FACILITY := Proxy.DirtyFlags.DIRTY_FACILITY
	const DIRTY_OPERATIONS := Proxy.DirtyFlags.DIRTY_OPERATIONS
	var data := [_dirty]
	if _dirty & DIRTY_FACILITY:
		data.append(gui_name)
	if _dirty & DIRTY_OPERATIONS:
		data.append(operations.get_proxy_dirty())
	_dirty = 0
	proxy_bus.emit_signal("proxy_changed", entity_type, facility_id, data)
