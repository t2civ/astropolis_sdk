# enums.gd
# This file is part of Astropolis
# https://t2civ.com
# *****************************************************************************
# Copyright 2019-2024 Charlie Whitfield; ALL RIGHTS RESERVED
# Astropolis is a registered trademark of Charlie Whitfield in the US
# *****************************************************************************
class_name Enums
extends Object


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

enum TradeClasses {
	TRADE_CLASS_ELECTRICITY,
	TRADE_CLASS_BULK,
	TRADE_CLASS_ICE,
	TRADE_CLASS_LIQUID,
	TRADE_CLASS_CRYOGENIC,
	TRADE_CLASS_PRECIOUS,
	TRADE_CLASS_CYBER,
}

enum PlayerClasses {
	PLAYER_CLASS_POLITY,
	PLAYER_CLASS_AGENCY,
	PLAYER_CLASS_COMPANY,
}

enum ProcessGroup {
	PROCESS_GROUP_RENEWABLE,
	PROCESS_GROUP_CONVERSION,
	PROCESS_GROUP_EXTRACTION,
}

enum RandomPlayer {
	RANDOM,
#	RANDOM_SPACE_AGENCY,
#	RANDOM_SPACE_COMPANY,
}

enum BodyFlags2 {
	IS_STATION = 1 << 40,
	GUI_HAS_MOONS = 1 << 41,
	GUI_HAS_ONE_MOON = 1 << 42, # Earth
	GUI_CLOUDS = 1 << 43, # Gas Giants; for Development "surface" replacement
	GUI_CLOUDS_SURFACE = 1 << 44, # Venus only; for Development "surface" replacement
}


# accounting

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

enum AccountClass {
	ACCOUNT_INCOME,
	ACCOUNT_CASH_FLOW,
	ACCOUNT_BALANCE,
}

const ACCOUNTING_PROJECT_OFFSET := 10000

