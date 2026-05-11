# threadsafe_global.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends Node

## Singleton [ThreadsafeGlobal] holds data accessible from any thread.



# settings
var total_biodiversity_pool := 25336.0 * IVUnits.SPP  ## Global biodiversity pool (species count units).
var total_information_pool := 6.4e22 * IVUnits.BIT  ## Global information pool (bit units).
## Body whose prices seed startup pricing. TODO: replace with
## [code]bodies_resources_prices.tsv[/code].
var start_prices_body := &"PLANET_EARTH"

# game
var local_player_name := &"PLAYER_NASA"  ## Name of the local player at game start.
var home_facility_name := &"FACILITY_PLANET_EARTH_PLAYER_NASA"  ## Name of the local player's home facility.

# *****************************************************************************
