# trader_base_ai.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name TraderBaseAI
extends TraderInterface

## Default AI for traders the local player owns. Subclass to write custom
## trader AI; the base [TraderInterface] is used for all non-owner peers.
##
## Do not modify this class directly. To override the base AI locally, create
## a new class that extends this class (or [TraderInterface]) and add
## [code]const OVERRIDE_AI := true[/code]. Only the owning player runs the
## extended AI; non-owner peers use the base [TraderInterface].
