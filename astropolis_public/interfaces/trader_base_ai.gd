# trader_base_ai.gd
# This file is part of Astropolis
# Copyright 2019-2023 Charlie Whitfield, all rights reserved
# *****************************************************************************
class_name TraderBaseAI
extends TraderInterface

# DO NOT MODIFY THIS CLASS! You can extend this base AI class or replace it (by
# extending the base Interface class). The base Interface class is shared by
# all non-owner network peers. Only the owning player has the extended AI
# class. To override the base AI locally, create a new class file that extends
# this class or the Interface class and add line: "const OVERRIDE_AI := true".

