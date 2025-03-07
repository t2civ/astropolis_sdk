# market_interface.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name MarketInterface
extends Interface

# DO NOT MODIFY THIS CLASS! This class has no AI, but you can make one if you
# like. See comments in "Base AI" classes to override AI.



func _init() -> void:
	super()
	entity_type = ENTITY_MARKET
