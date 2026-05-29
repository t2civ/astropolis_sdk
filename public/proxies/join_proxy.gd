# join_proxy.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
@abstract
class_name JoinProxy
extends Proxy

## Read-only data proxy for a server-side Join, which joins component data
## from Facilities, Bodies, and other Joins.
##
## Joins aggregate 5 components (Operations, Financials, Population, Biome
## and Cyberspace) that derive from Facilities. Body and Player objects also
## act as Joins.[br][br]
##
## There are two hard-coded Joins; the rest are procedural. They form
## tree structures with Facilities, Bodies, and Players:
##
## [codeblock]
## JOIN_OFFWORLD (<-data from all non-homeworld Bodies)
##
## JOIN_ALL (<-data from the next 4 Join types)
## JOIN_<star>_PLANETS (<-data from planet Bodies)
## JOIN_<star>_MOONS (<-data from JOIN_<planet>_MOONS below)
## JOIN_<star>_SPACE (<-data from JOIN_<planet>_SPACE below & non-planet spacecraft)
## JOIN_<star>_PLANETOIDS (<-data from planetoid Bodies)
##
## <body> (<-data from self Facilities)
## JOIN_<planet>_MOONS (<-data from all moon Bodies of a planet)
## JOIN_<planet>_SPACE (<-data from all spacecraft Bodies of a planet)
##
## JOIN_<star>_PLANETS_<player> (<-data from planet Facilities for Player)
## JOIN_<star>_MOONS_<player> (<-data from JOIN_<planet>_MOONS_<player> below)
## JOIN_<star>_SPACE_<player> (<-data from JOIN_<planet>_SPACE_<player>)
## JOIN_<star>_PLANETOIDS_<player> (<-data from planetoid Facilities for Player)
##
## JOIN_<planet>_MOONS_<player> (<-data from all moon Facilities of a planet)
## JOIN_<planet>_SPACE_<player> (<-data from all spacecraft Facilities)
## [/codeblock]
##
## Procedural joins are created only when needed. Financials is only present
## on player-specific joins. Not all joined data is a simple sum (e.g.,
## information and biodiversity account for mutual information).
##
## To modify AI, see [BaseAI] and the [code]*_base_ai.gd[/code] files.
##
## WARNING: Lives on the proxy thread. Containers and many methods are not
## threadsafe; accessing non-container properties is safe.


# read-only!
var join_id := -1  ## Index into [member ProxyBus.join_proxies].
## Depth in the aggregation DAG: 0 for a sink (e.g. [code]JOIN_ALL[/code]).
var join_depth := 0


# ************************* VIRTUAL & IMPLEMENTATION **************************

func _init() -> void:
	const ENTITY_JOIN := Proxy.EntityType.ENTITY_JOIN
	super()
	entity_type = ENTITY_JOIN


# ********************************* PROXY API *********************************

func has_development() -> bool:
	return true
