# Schema for resources.tsv

Resources are described in `resources.descriptive.md`.


## Fields

- name (1st column) — Resource name per data table instructions.
- resource_class — For GUI only; one of ENERGY, ORES, VOLATILES, MATERIALS, MANUFACTURED, BIOLOGICAL, or SERVICES, corresponding to groupings in `resources.descriptive.md`.
- commodity — BOOL value (default TRUE); specifies whether the resource is traded as a commodity.
- trade_class — DEPRECATE.
- storage_class — One of storage classes defined in storage_classes.tsv. Describes the physical storage and transport infrastructure required for the resource. Empty for service resources.
- trade_unit — Resource unit for trade and price display.
- start_price — This column is duplicated from #2025.
- #2015 (non-imported column) — Estimated price of the resource in 2015.
- #2025 (non-imported column) — Estimated price of the resource in 2025.
- #2035 (non-imported column) — Projected price of the resource in 2035.
- is_extraction — TRUE ("x") for extractable resources.
- is_volatile — TRUE ("x") for volatile resources.
