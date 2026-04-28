# player_custom_ai.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name PlayerCustomAI
extends PlayerInterface

## Example custom player AI. Could extend either [PlayerBaseAI] or
## [PlayerInterface]; setting [constant OVERRIDE_AI] to [code]true[/code]
## makes this the selected AI for players locally.


## Marker constant: setting to [code]true[/code] elevates this class to the
## active player AI in place of [PlayerBaseAI].
const OVERRIDE_AI := true
