# itab_budget.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name ITabBudget
extends MarginContainer

## "Budget" tab subpanel for [InfoPanel]. Shows the selected entity's income
## statement, cash flow, and balance sheet. Currently a stub.

const SCENE := "res://public/ui/itab_budget.tscn"  ## Scene file for instancing.


const PERSIST_MODE := IVGlobal.PERSIST_PROCEDURAL  ## Save/load mode (procedural node).
const PERSIST_PROPERTIES: Array[StringName] = []  ## Member names persisted by save/load.


## Refreshes the budget tab. Wired to [InfoTabContainer]'s shared 1 s timer.
## Currently a stub.
func timer_update() -> void:
	pass
