# Schema for modules.tsv

Modules are described in `modules.descriptive.md`.


## Fields

- name (1st column) — Module name per data table instructions. For extraction modules, the name is constructed with the `stratum_group` value as a prefix, e.g., `CONT_SURFACE_MINES`, `OCEAN_DESALINATION_PLANTS`, `ATMOSPHERE_PROCESSORS`.
- op_class — GUI only category for operations display.
- storage — Quantifies associated resource storage capacities, both on- and off-site. Array elements correspond to classes in `storage_classes.tsv` (array size must equal number of classes).
- reconfig_time — Required time in days (d) to fully reconfigure a module from one operation (100%) to another (100%).
- reconfig_cost — Required cost in USD millions ($M) to fully reconfigure a module from one operation (100%) to another (100%).
- biological_crew — The module provides life support for this number of human personnel (CREW_SYSTEMS only). 
- carrying_capacity — The module can support a "population" (as opposed to crew only) of this size. Populations are more permanent than crews and have intrinsic growth dynamics.
- carrying_capacity_group — Leave as HUMAN.
- operations — Operations that the module provides capacity for. Each operation belongs to exactly one module (one-to-many relationship from modules to operations).


## Notes

1. A module's size is defined by its supported operation(s). One module provides capacity for one operation at 100% run rate, or multiple operations at fractional run rates that add to 100%.
2. A module's capacity can be shifted among its enabled operations (i.e., "reconfigured"). The time and cost of this reconfiguration (`reconfig_time` and `reconfig_cost`) are fixed properties of each module and can represent anything from a minor operational adjustment to a major refitting. In some cases, the reconfiguration might represent relocation (e.g., mining) or infrastructure turnover.
3. When implementing modules that support multiple operations, it may be necessary to re-normalize operation rows in `operations.tsv`. Specifically, each operation must be normalized so that exactly 1 module provides 1x operation capacity (if configured for only that operation). Prefer to keep one row (the "best") as currently normalized.
4. Storage capacities should be set generously, and unrealistically high in the case of electricity. See class descriptions and notes in `storage_classes.descriptive.md`.
5. For setting `carrying_capacity` for farms and similar, consider the number of people (and their families) typically involved in these activities on Earth, where 1 module provides 1 unit of the respective operation(s).
