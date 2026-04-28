# enums.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name Enums
extends Object

## Astropolis-wide enums shared across server, interface, and table-driven code.


## Generic 'type' enums may be used and re-used in different contexts.
enum Types {
	ALL,
	ELECTRICITY,
	EX_PLANET_SPACE,
	MOONS,
	OFF_HOMEWORLD,
	PLANETOIDS,
	PLANETS,
}

## Trade classes group resources by handling (electricity, bulk, cryogenic,
## etc.) for trade and storage logic.
enum TradeClasses {
	TRADE_CLASS_ELECTRICITY,
	TRADE_CLASS_BULK,
	TRADE_CLASS_ICE,
	TRADE_CLASS_LIQUID,
	TRADE_CLASS_CRYOGENIC,
	TRADE_CLASS_PRECIOUS,
	TRADE_CLASS_SERVICES,
}

## Top-level kind of a [PlayerInterface] (state polity, space agency, or
## private company).
enum PlayerClasses {
	PLAYER_CLASS_POLITY,
	PLAYER_CLASS_AGENCY,
	PLAYER_CLASS_COMPANY,
}

## Process category that determines how an operation runs (renewable,
## conversion, extraction, or dev/debug).
enum ProcessGroup {
	PROCESS_GROUP_RENEWABLE,
	PROCESS_GROUP_CONVERSION,
	PROCESS_GROUP_EXTRACTION,
	PROCESS_GROUP_DONT_PROCESS, # dev/debug
}

## Random-player selection options for game start.
enum RandomPlayer {
	RANDOM,
#	RANDOM_SPACE_AGENCY,
#	RANDOM_SPACE_COMPANY,
}

## Astropolis additions to ivoyager [code]IVBody.BodyFlags[/code]. Bits 40+
## (ivoyager reserves the lower bits).
enum BodyFlags2 {
	BODYFLAGS_STATION = 1 << 40,
	BODYFLAGS_GUI_HAS_MOONS = 1 << 41,
	BODYFLAGS_GUI_HAS_ONE_MOON = 1 << 42, # Earth
	BODYFLAGS_GUI_CLOUDS = 1 << 43, # Gas Giants; for Development "surface" replacement
	BODYFLAGS_GUI_CLOUDS_SURFACE = 1 << 44, # Venus only; for Development "surface" replacement
}


# accounting

## Per-line items used in financial statements (income, cash flow, balance
## sheet) and their corresponding [enum AccountClass] groupings.
enum AccountItem {
	REVENUE,
	INC_STMT_GROSS,
	INC_STMT_OPEX,
	INC_STMT_NONOP,
	CF_STMT_OPERATING,
	CF_STMT_INVESTING,
	CF_STMT_FINANCING,
	BAL_SHT_SHORT_TERM,
	BAL_SHT_LONG_TERM,
	INCOME_SALES,
	INCOME_COST_OF_SALES,
	INCOME_TAXES_COLLECTED,
	INCOME_AGENCY_FUNDING,
	INCOME_SELLING_GEN_ADMIN,
	INCOME_RES_AND_DEV,
	INCOME_DEPRECIATION,
	INCOME_INTEREST_EXPENSE,
	INCOME_NONOP_OTHER,
	INCOME_TAXES_PAID,
	CASH_FLOW_EARNINGS,
	CASH_FLOW_INVENTORY,
	CASH_FLOW_CAPEX,
	CASH_FLOW_EQUIP_SOLD,
	CASH_FLOW_NEW_FINANCING,
	CASH_FLOW_INTEREST,
	BALANCE_CASH,
	BALANCE_INVENTORY,
	BALANCE_SHORT_TERM_DEBT,
	BALANCE_CAPITAL_ASSETS,
	BALANCE_INTANGIBLE,
	BALANCE_LONG_TERM_DEBT,
}

## High-level financial-statement category for an [enum AccountItem].
enum AccountClass {
	ACCOUNT_INCOME,
	ACCOUNT_CASH_FLOW,
	ACCOUNT_BALANCE,
}

## Per-project offset added to [enum AccountItem] codes when accounting
## entries are scoped to a specific project.
const ACCOUNTING_PROJECT_OFFSET := 10000
