# Schema for facilities_operations.tsv

This Entity x Entity table defines the state of operations at facilities at simulation start in 2025. Facilities are described in `facilities.descriptive.md`. Operations are described in `operations.descriptive.md`.


## Table Data

The data type is ARRAY[INT]. Each cell contains the following 3 integer values delimited by semicolons:

- rate_ppt — Current run rate in parts-per-thousand of total operation capacity. Operation capacity is the sum of capacities provided by modules in `facilities_modules.tsv` (capacity may be provided by >1 module).
- flags — Operation flags (as int); use 0 for now.
- commands — Operation commands (as int); use 0 for now.

Data cell should be empty if `rate_ppt` is 0.


## Notes

1. Rate is an average for variable operations. Note how capacity is defined in `facilities_modules.schema.md`; `rate_ppt` is expected to be small for solar power in northern territories.
