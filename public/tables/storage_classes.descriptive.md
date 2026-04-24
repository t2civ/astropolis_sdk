# Storage Classes (Descriptive)

Storage classes categorize the physical infrastructure required to store and transport resources, whether in facility inventory, warehousing, or transport vessel holds.

- **Electricity** — Power storage infrastructure including battery banks, capacitor arrays, flywheels, gravity reservoirs, and other energy storage systems.
- **Bulk** — General-purpose warehouses, bins, silos, open storage yards, and standard freight containers for solid materials that do not require special environmental controls. The default storage class for ores, structural materials, and most basic manufactured goods.
- **Ice/Volatile** — Sealed, insulated containment for substances that sublimate or evaporate readily in the local environment. On Earth this means refrigerated or pressurized tanks; in space it means insulated bins or ice blocks in shaded storage.
- **Liquid** — Standard tanks, drums, bladders, and pipelines for liquids stored at or near ambient temperature and moderate pressure. Includes both inert and hazardous liquid containment.
- **Cryogenic** — Insulated, pressurized vessels designed to maintain liquefied gases at cryogenic temperatures. Includes dewars, cryotanks, and associated boil-off management systems.
- **Radioactive** — Heavily shielded containment for highly radioactive materials such as spent nuclear fuel and high-level radioactive waste. Includes spent fuel pools, dry cask storage, and hot cells with remote handling systems.
- **Special Handling** — Controlled-environment storage for resources that require temperature regulation, vibration isolation, electrostatic discharge protection, cleanroom conditions, security vaults, or other specialized handling not covered by other storage classes. A catchall for high-value, fragile, perishable, hazardous, or precision items.

Notes:

1. Simulation mechanics require unrealistically large capacities, particularly for electricity. When setting module capacities, provide storage capacity to cover at least ~2 weeks of facility activity (we may be able to tune this down later).
2. Even after minimum consideration above, capacities should be generous: bulk capacity is provided by almost any unused space; ice/volatiles capacity is cheap and must allow for large quantities of water; etc. 
