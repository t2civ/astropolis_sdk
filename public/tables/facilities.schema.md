# Schema for facilities.tsv

Facilities are described in `facilities.descriptive.md`. Content of this table is at simulation start in 2025.


## Fields

- name (1st column) — Constructed by joining body name (with type prefix) and player name (without type prefix). Examples: PLANET_EARTH_CHINA, PLANET_EARTH_EU, SPACECRAFT_ISS_NASA.
- is_start — Always TRUE (by default).
- body — Simulation body.
- player — Owning or controlling player.
- exchanges — Exchanges where this Facility expects to buy or sell resources. Each value is an Exchange name of the form `EXCHANGE_<body_name>`. An Exchange exists for each Body that has more than one Facility.
- is_unitary — True ("x") if the facility can be treated as one activity for economic accounting. If false, each operation is treated as a separate activity for internal mechanics like taxation and gross product calculation.
- closed_cycle_ops — True ("x") if the facility runs operations in a "closed cycle"; i.e., resource streams are entirely from and to inventory.
- public_sector — Fraction of economic activity that is public sector. For unitary facilities, this is usually 1 (agencies) or 0 (companies).
- population — Population or personnel count in 2025. For national polities, this is total national population. For agencies, this includes direct employees and the contractor/support workforce.
- #2025 — Population or personnel count in 2025 (for sim calibration, not imported).
- #2035 — Projected population or personnel count in 2035 (for sim calibration, not imported).
- constructions — Total mass of all existing buildings, infrastructure, and manufactured items. Includes "active" monuments (e.g., tourist destinations such as the Pyramids) but not inactive ruins or rubbish.
- biomass — Total dry-weight mass (not carbon weight).
- bioproductivity — Production rate of biomass as measured above.
- biodiversity_fraction — See Information & Biodiversity below.
- information_fraction — See Information & Biodiversity below.
- nominal_information — For small facilities with relatively little computer capacity, assign a nominal Shannon information content in Terrabits (Tbit). Use this field instead of `information_fraction` if unique information content is too small to significantly affect the global information model.
- solar_occlusion — Average solar occlusion in a player's territory. This is 1.0 minus solar insolation as a fraction of total possible at a distance from the sun without any blockage. Agencies on a planet should have the same value as their owning polity. Leave empty for spacecraft.
- time_horizon — Planning horizon used by AI and automations (inventory reserves, resupply, etc.). Shorter for facilities with frequent resupply (e.g., Earth), longer for facilities with infrequent resupply (e.g., LEO).


## Information & Biodiversity 

"Information" here refers to the Shannon information content (or "Shannon entropy") represented in all computer systems. This is a measure of unique knowledge and unpredictable state, not physical hardware bits. "Biodiversity" is measured in effective species of macroscopic organisms (equal to the number of species if all were equally represented), which is the exponential of the Shannon index. These concepts are mathematically related and modeled internally as Shannon entropy with shared content (mutual information) among facilities.

See `misc/global_information.md` and `misc/global_biodiversity.md` for derivations of global values in 2015, 2025 and 2035 (projected). The simulation uses these global values for 2025:

- information — 6.4e22 bits (Shannon index 52.50)
- biodiversity — 25,336 effective species (Shannon index 10.14)

Table parameters `information_fraction` and `biodiversity_fraction` are fractions of the respective information (in bits) or biodiversity (in effective species) represented in the "facility" relative to global values (e.g., in all USA territory relative to all Earth). These values sum to >1 due to shared content. 
