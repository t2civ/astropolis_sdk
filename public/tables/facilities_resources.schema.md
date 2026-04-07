# Schema for facilities_resources.tsv

This Entity x Entity table defines resource quantities at facilities at simulation start in 2025. Facilities are described in `facilities.descriptive.md`. Resources are described in `resources.descriptive.md`.


## Table Data

The data type is VECTOR2; each cell contains the following 2 float values delimited by a comma:
- reserve — Inventory reserved for future use by the facility.
- for_sale — Excess inventory available for sale. Usually 0 if facility is net consumer and >0 if net producer.

Table default is "0,0"; leave cell empty if `reserve` and `for_sale` are zero.


## Notes

1. All values are resource quantities with unit specified by `trade_unit` in `resources.tsv` .
2. The two values sum to total present inventory.
