# Schema for facilities_operations.tsv

This Entity x Entity table defines the state of operations at facilities at simulation start in 2025. Facilities are described in `facilities.descriptive.md`. Operations are described in `operations.descriptive.md`.


## Table Data

The data type is ARRAY[INT]. Each cell contains the following 3 integer values delimited by semicolons:

- rate_ppt — Average current run rate in parts-per-thousand of total operation capacity (i.e., capacity factor). Operation capacity is the sum of capacities provided by modules in `facilities_modules.tsv`.
- flags — Operation flags (as int); use 0 for now.
- commands — Operation commands (as int); use 0 for now.

Data cell should be empty if `rate_ppt` is 0.


## Notes

1. For renewable power generation, `rate_ppt` is a simplified abstraction of real-world operations: approximately the real-world capacity factor at the facility's location, including environmental effects (e.g., `solar_occlusion` for solar, tidal amplitude for tidal, regional wind / hydrological / geothermal regimes) and normal maintenance downtime. The one real-world effect excluded is output curtailment due to insufficient power storage. Set >0 even for operations not currently present at the facility but that the local environment could support if modules were added later (e.g., tidal power for polities without existing tidal plants). Note that solar module capacity is defined at 1-AU direct sunlight (see `facilities_modules.schema.md` note 1), so for SOLAR_POWER on Earth, `rate_ppt ≈ 1000 × (1 − solar_occlusion)`.
2. Note how capacity is defined in `facilities_modules.schema.md` note 1; this is usually but not always nameplate capacity.
