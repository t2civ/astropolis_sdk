# Schema for storage_classes.tsv

Storage classes are described in `storage_classes.descriptive.md`.


## Fields

- name (1st column) — Storage class name per data table instructions. Represents the physical infrastructure category required to store and transport a resource.


## Notes

1. Storage classes are referenced by the `storage_class` field in `resources.tsv`.
2. Unlike `trade_class` (which governs trading economics and transport cost), `storage_class` describes the physical containment and handling infrastructure. The two often coincide but diverge for resources like nuclear fuels (trade_class=BULK, storage_class=RADIOACTIVE) and high-value items (trade_class=PRECIOUS, storage_class=SPECIAL_HANDLING).
3. Service resources and non-commodity resources have no storage class.
