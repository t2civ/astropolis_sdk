# facility_base_ai.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name FacilityBaseAI
extends FacilityInterface

## Default AI for facilities the local player owns. Subclass to write custom
## facility AI; the base [FacilityInterface] is used for all non-owner peers.
##
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [FacilityInterface]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [FacilityInterface].
