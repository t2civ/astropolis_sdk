# body_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
@abstract
class_name BodyProxy
extends Proxy

## [BodyProxy] corresponds to an [IVBody] in the simulation, hosting
## facilities and aggregating their stats.
##
## Server-side Body aggregates component data from its facilities and exposes
## stratum composition (atmosphere, surface, subsurface). It gains a
## [BrokerProxy] when at least one facility is present; the broker gains a
## spot [MarketProxy] when 2+ facilities are present.
##
## To get the corresponding scene-tree [code]IVBody[/code] node use
## [code]IVBody.bodies[body_name][/code]. Be aware that the SceneTree runs
## on the main thread!
##
## To modify AI, see [BaseAI] and the [code]*_base_ai.gd[/code] files.
##
## WARNING: Lives on the proxy thread. Containers and many methods are not
## threadsafe; accessing non-container properties is safe.


var body_id := -1  ## Index into [member ProxyBus.body_proxies].
var body_flags := 0  ## Body flags from [enum IVBody.BodyFlags].
var solar_occlusion: float  ## Average solar irradiance occlusion at this body.
var is_satellites := false  ## True while this body has at least one satellite.
var is_facilities := false  ## True while this body hosts at least one facility.

## Parent body, or null for the top body only.
var parent: BodyProxy
## Direct satellite bodies, keyed by name. Resizable container — not threadsafe!
var satellites: Dictionary[StringName, BodyProxy]
## Facilities at this body. Resizable container — not threadsafe!
var facilities: Array[Proxy] = []
## Null until first facility added.
var broker: BrokerProxy


# ************************* VIRTUAL & IMPLEMENTATION **************************

func _init() -> void:
	const ENTITY_BODY := Proxy.EntityType.ENTITY_BODY
	super()
	entity_type = ENTITY_BODY


func _clear_for_destruction() -> void:
	parent = null
	satellites.clear()
	facilities.clear()
	broker = null


# ********************************* PROXY API *********************************

func has_development() -> bool:
	return is_facilities


func get_body_name() -> StringName:
	return name


func get_body_flags() -> int:
	return body_flags


## Returns this body's [member facilities]. proxy thread only!
func get_facilities() -> Array[Proxy]:
	return facilities


func get_market(player_id: int) -> MarketProxy:
	return broker.get_market(player_id) if broker else null


# Strata. The composition layers live on BodySvrProxy; these read-only
# accessors are implemented there.

## Returns true if this body has any stratum composition layers.
@abstract func has_strata() -> bool


## Returns the number of stratum composition layers on this body.
@abstract func get_n_strata() -> int


## Returns the name of the stratum at [param index].
@abstract func get_stratum_name(index: int) -> StringName


## Returns the polity name of the stratum at [param index] ([code]&""[/code]
## for commons strata).
@abstract func get_stratum_polity(index: int) -> StringName


## Returns the density of the stratum at [param index].
@abstract func get_stratum_density(index: int) -> float


## Returns the stratum-group index of the stratum at [param index].
@abstract func get_stratum_stratum_type(index: int) -> int


## Returns the thickness of the stratum at [param index].
@abstract func get_compostion_thickness(index: int) -> float


## Returns the volume of the stratum at [param index].
@abstract func get_stratum_volume(index: int) -> float


## Returns the total mass of the stratum at [param index].
@abstract func get_stratum_total_mass(index: int) -> float


## Returns the body radius cached on the stratum at [param index].
@abstract func get_compostion_body_radius(index: int) -> float


## Returns the per-resource mass array for the stratum at [param index].
@abstract func get_stratum_masses(index: int) -> PackedFloat64Array


## Returns the per-resource dispersion array for the stratum at [param index].
@abstract func get_stratum_dispersions(index: int) -> PackedFloat64Array


## Returns the survey-type index for the stratum at [param index].
@abstract func get_stratum_survey_type(index: int) -> int


## Returns survey/discovery data for [param resource_type] in the stratum at
## [param index].
@abstract func get_stratum_resource_data(index: int, resource_type: int) -> PackedFloat64Array


## Registers [param satellite] under this body. Updates [member is_satellites].
func add_satellite(satellite: BodyProxy) -> void:
	assert(!satellites.has(satellite.name))
	satellites[satellite.name] = satellite
	is_satellites = true


## Removes [param satellite] from this body. Updates [member is_satellites].
func remove_satellite(satellite: BodyProxy) -> void:
	satellites.erase(satellite.name)
	is_satellites = !satellites.is_empty()


## Registers [param facility] at this body. Updates [member is_facilities].
func add_facility(facility: Proxy) -> void:
	assert(!facilities.has(facility))
	facilities.append(facility)
	is_facilities = true


## Removes [param facility] from this body. Updates [member is_facilities].
func remove_facility(facility: Proxy) -> void:
	facilities.erase(facility)
	is_facilities = !facilities.is_empty()
