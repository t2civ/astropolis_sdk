# player_base_ai.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2025 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name PlayerBaseAI
extends PlayerInterface

# DO NOT MODIFY THIS CLASS! You can extend this base AI class or replace it (by
# extending the base Interface class). The base Interface class is shared by
# all non-owner network peers. Only the owning player has the extended AI
# class. To override the base AI locally, create a new class file that extends
# this class or the Interface class and add line: "const OVERRIDE_AI := true".
