# market_interface.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name MarketInterface
extends Interface

# DO NOT MODIFY THIS CLASS! This class has no AI, but you can make one if you
# like. See comments in "Base AI" classes to override AI.



func _init() -> void:
	super()
	entity_type = ENTITY_MARKET
