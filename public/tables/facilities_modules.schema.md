# Schema for facilities_modules.tsv

This Entity x Entity table defines module quantities and configurations at facilities at simulation start in 2025. Facilities are described in `facilities.descriptive.md`. Modules are described in `modules.descriptive.md`.


## Table Data

The data type is ARRAY[FLOAT]; each cell contains float values delimited by semicolons. Values are the current installed and configured capacity for each supported operation specified by `operations` in `modules.schema.md`. The cell should be empty if all capacities are 0. Otherwise, number of float values must correspond to number of supported operations in `modules.schema.md`.


## Notes

1. Capacity should usually be "nameplate capacity". For solar power, use peak capacity assuming direct sunlight in space at 1 AU (this will be more consistent with off-Earth usage).
2. The unit of capacity follows from the operation's normalization in `operations.tsv`. For Energy group modules, one unit of capacity corresponds to 1 MW of electricity output. For other modules, see `operations.schema.md` for the applicable normalization.
3. An empty cell means the module is not present at the facility (zero capacity for all of its operations).
