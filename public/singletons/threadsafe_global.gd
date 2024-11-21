# threadsafe_global.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
extends Node

# Singleton "ThreadsafeGlobal".
#
# This global provides access to threadsafe data. Note that most items here are
# localized to base classes (Interface, NetRef, etc.) for quicker access.


static var tables_aux := {} # derived tables & indexing; see public_preinitializer.gd

# settings
var total_biodiversity_pool := 1.3e6 * IVUnits.SPP
var total_information_pool := 1.3e21 * IVUnits.BIT
var start_prices_body := &"PLANET_EARTH" # TODO: bodies_resources_prices.tsv


# game
var local_player_name := &"PLAYER_NASA"
var home_facility_name := &"FACILITY_PLANET_EARTH_PLAYER_NASA"
