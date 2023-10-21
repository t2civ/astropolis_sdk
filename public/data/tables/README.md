# Notes on table meanings & derivations

## Contents:

[Notes](#notes)   
[asset_adjustments_mod.tsv](#asset_adjustments_modtsv)   
[carrying_capacity_groups.tsv](#carrying_capacity_groupstsv)   
[compositions.tsv](#compositionstsv)  
[compositions_resources_heterogeneities.tsv](#compositions_resources_heterogeneitiestsv)   
[compositions_resources_percents.tsv](#compositions_resources_percentstsv)   
[facilities.tsv](#facilitiestsv)  
[facilities_operations_capacities.tsv](#facilities_operations_capacitiestsv)  
[facilities_operations_utilizations.tsv](#facilities_operations_utilizationstsv)  
[facilities_populations.tsv](#facilities_populationstsv)  
[facilities_resources.tsv](#facilities_resourcestsv)  
[major_strata.tsv](#major_stratatsv)   
[mod_classes.tsv](#mod_classestsv)   
[modules.tsv](#modulestsv)   
[moons_mod.tsv](#moons_modtsv)   
[op_classes.tsv](#op_classestsv)   
[op_groups.tsv](#op_groupstsv)   
[operations.tsv](#operationstsv)  
[planets_mod.tsv](#planets_modtsv)   
[players.tsv](#playerstsv)   
[populations.tsv](#populationstsv)   
[resource_classes.tsv](#resource_classestsv)   
[resources.tsv](#resourcestsv)   
[spacecrafts.tsv](#spacecraftstsv)   
[strata.tsv](#stratatsv)   
[surveys.tsv](#surveystsv)   
[technologies.tsv](#technologiestsv)   

## Notes

Data Quality Ranking (WIP):

    +    Placeholder, just some value to get the sim running.   
    ++   Guess, probably at least gave it some individual thought.   
    +++  Some referencing, possibly dubious or mixed quality.   
    ++++ Referenced and production ready.   

Suggested fixes with references are welcome!

For data related to Earth's nations and populations our target year is ~2010. We'll run the sim for ~15 years to have actual game start around ~2025. This will fill our simulation history (graphs, last-four-quarters financials, etc.) for GUI display. It will also help us tune our simulation parameters to roughly approximate more contemporary data.

Incomplete list of abstrations (i.e., intentionally unrealistic elements):

* ESA is treated as a space agency of the EU.
* "CNSA" is a conflation of CNSA and CASC; NASA is in some places conflated with its contractors; etc.
* Resource groupings "Industrial Metals", "Xenon/Krypton", etc. Substances of unique importance in the simulation are singular. (We do have conservation of mass, very roughly speaking.)
* Ores always have the same percent target metal or mineral. E.g., Iron ores are 70%  iron; precious metal ores are 1% precious metals, etc. We assume benification occurs at the mine to produce exactly consistent "ore" commodities.

## asset_adjustments_mod.tsv
Modifies ivoyager/data/solar_system/asset_adjustments.tsv.

## carrying_capacity_groups.tsv
Enumeration table that defines different population categories for carrying capacity.

## compositions.tsv

Compositions define all of the extractable resources in solar system bodies. Internally, 'Composition' is a data structure attached to a Body that defines resources for one 'stratum'. Strata correspond to both physical/geophysical structures and also practictical accessibility (on Earth this includes political boundaries). 

Composition names are constructed:
`COMPOSITION_<body_name or generic body_class>_<stratum_name>[_<owner_name>]`

Field comments:
\#volume, #mass: for info/QA only; internal values are calculated.
thickness: if blank, imputed to be Body.m_radius.
area: if blank, imputed to be 4 * PI * (Body.m_radius - outer_depth)^2.

#### COMPOSITION_PLANET_EARTH_STRATUM_ATMOSPHERE

Mass 5.15e18 kg. 3/4 mass under 11 km. https://en.wikipedia.org/wiki/Atmosphere_of_Earth.  
Surface area of Earth: 5.10e8 km\^2.  
We arbitrarily set thickness to include mesosphere at 82 km, then calculate:  
Volume 5.10e8 km\^2 x 82 km = 4.18e10 km\^3  
Density 5.15e18 kg / (4.18e10 km\^3 x 1e9 km\^3/m\^3)  
   =0.123 kg/m\^3 = 1.23e-4 g/cm\^3

#### COMPOSITION_PLANET_EARTH_STRATUM_OCEAN
Mass of hydrosphere 1.386e18 t, of which 97.5% (=1.351e18 t) is ocean. Area is 3.61e8 km^2. Density of seawater 1020 to >1050 kg/m^3 (=1.02 to >1.05 g/cm^3).   
https://en.wikipedia.org/wiki/Hydrosphere   
https://en.wikipedia.org/wiki/Seawater   
We use 1.03 g/cm^3 density. We calculate average depth:   
1.351e21 kg / (1030 kg/m^3 * 1e9 m^3/km^3 * 3.61e8 km^2) = 3.633 km   
Volume 3.61e8 km^2 * 3.633 km = 1.31e9 km^3   
Content:   
We consider 3.5% salt as "Industrial Minerals".   
Disolved gasses: (https://en.wikipedia.org/wiki/Ocean)   
Carbon dioxide: 14 mL/kg; x1.977 kg/m3 / (1e6  mL/m3) -> 2.8e-3%   
Nitrogen: 9 mL/kg; x1.25 kg/m3 / (1e6  mL/m3) -> 1.1e-3%   
Oxygen: 5 mL/kg; x1.429 kg/m3 / (1e6  mL/m3  -> 7.1e-4%   

96.5% Water   
3.5 Industrial Minerals (salt)   

#### COMPOSITION_PLANET_EARTH_STRATUM_OCEAN_FLOOR
Arbitrarily set at 100m depth for mining potential (aka Hoover it up!):   
https://oceanminingintel.com/insights/ocean-mining-the-5-minute-what-why-where-how-and-who

#### COMPOSITION_PLANET_EARTH_STRATUM_\<crust layers>
Layers arbitrarily defined for extraction potential, considering deepest:   
- pit mining: 1.2 km, but usually < 1 km. Conveniently, average continental altitude is 800 m. So we use that for "surface".
- mining: ~4 km. Gets really tough below, but maybe we could go to 8 km with some wild engineering.
- drilling: ~7.5 km (? check wiki).

So we have strata for player exploitation as:
 - CONT_SURFACE: -0.8 - 0 km (pit mining)
 - CONT_SUBSURF: 0 - 4 km (mining)
 - CONT_4KM_8KM: 4 - 8 km (drilling, but maybe mining with tech)
And deeper strata not currently accessible:
 - CONT_8KM_28KM: 8 - 28 km
 - LOWER_CONT_CRUST: 28 - 40 km
 
Our simplified Earth structure model:
 - Ocean Crust: 7.5 km (real world 5-10 km)
 - Upper Continental Crust: Surface - 28 km
 - Lower Continental Crust: 28-40 km
 (that's all we need for now...)

Notes on upper/lower continental crust: There is a Conrad
discontinuity at 15-20 km and "sima starts about 11 km below the Conrad
discontinuity". The sial/sima transition is all about chemistry and
density, so that is where we define the upper/lower transition.

https://en.wikipedia.org/wiki/Earth%27s_crust   
https://en.wikipedia.org/wiki/Continental_crust   
https://en.wikipedia.org/wiki/Structure_of_Earth   
https://en.wikipedia.org/wiki/Sial   
https://en.wikipedia.org/wiki/Sima_(geology)   
https://en.wikipedia.org/wiki/Structure_of_Earth#/media/File:RadialDensityPREM.jpg   

Unowned part of continental surface is Antarctica (area 1.42e7 km^2). Subract
Antarctica and 6 major players from total land area (1.49e8 km^2) gets us area
of PLAYER_OTHER at 9.03e7 km^2.

## compositions_resources_heterogeneities.tsv

Row prefix: `COMPOSITION_`  
Column prefix: `RESOURCE_` (is_extraction subset)  
Table access: `table[composition_type][resource_type]`

Defines heterogeneity of resources in each composition. Values are coefficient of variation of mass. Heterogeneity causes "deposits". Fully "mixed" strata (such as atmosphere) are omitted from table and have default heterogeneity = 0.0. 

## compositions_resources_percents.tsv

Row prefix: `COMPOSITION_`  
Column prefix: `RESOURCE_` (is_extraction subset)  
Table access: `table[composition_type][resource_type]`

Defines mass percent for all resources in each composition. (Each row is summed and normalized to 100% internally, so its not necessary to add to exactly 100%.)

## facilities.tsv

Name construction: `FACILITY_<body_name>_<player_name>`

There is at most one "facility" for each player at each body, which combines all of that player's activity. 

The table has game start only. We have one "homeworld" facility for each player on Earth, plus four at SPACECRAFT_ISS (one each for NASA, Roscosmos, ESA & JAXA) and one at SPACECRAFT_TIANGONG (CNSA).

#### public_portion
Fraction of facility that is public sector. For small facilities, generally 1.0 for space agencies and 0.0 for private companies. For Earth "homeworld" facilities representing polities, values follow roughly: https://en.wikipedia.org/wiki/List_of_countries_by_public_sector_size:


|             | 2010 (%)       | 2020 (%)       |
| ----------- | -------------- | -------------- |
| USA         | 13.3           | 13.3           |
| Russia      | 40.6           | 40.6           |
| China       | 30 (guess)     | 25             |
| EU          | 18 (see below) | 18 (see below) |
| India       | 3.8            | 3.8            |
| Japan       | 7.7            | 7.7            |
| Other       | 20 (guess)     | 20 (guess)     |


We mainly use ILO estimates, or best guess what it would be in ~2010 and ~2020. EU is set between Germany (12.9) & France (20.5), leaning to the latter. 

#### internal_market

If set, internal operations are treated as separate entities for taxation and economic activity measurement. I.e., all resources produced & used are sales & purchases. True for "ports" and larger facilities, false for smaller facilities. We assume the ISS's solar panels produce ecectricty for its own operation, while "USA" solar panels produce electricity sold to other domestic entities.

#### solar_occlusion

Overrides Body.solar_occlusion if specified. These are set to give observed (or guessed) solar power utilizations (="capacity factor") for polity "homeworld facilities". See facilities_operations_utilizations.tsv/SOLAR_POWER below.

## facilities_operations_capacities.tsv

Row prefix: `OPERATION_`  
Column prefix: `FACILITY_`  
Table is transposed internally, access: `table[facility_type][operation_type]`

Values are "operation rate units" defined in operations.tsv. In general, rate = 1.0 means:
* energy generation, 1.0 MW
* refining and manufacturing, 1.0 t/d total mass conversion
* extraction, ([deposits_percent or mass_percent]/100) t/d ore extraction
* others are more abstract

Capacity is "peak" operation potential. Capacity x utilization = operation_rate.

Note: This table is here for development convenience. Capacities are actually determined by modules. However, game start code will set appropriate module number in each game start facility to achieve capacities defined in this table.

#### SOLAR_POWER
World GWp (=capacity): ~40 in 2010, ~640 in 2019, ~1000 in 2022, roughly from charts at https://en.wikipedia.org/wiki/Solar_power.

2016 & 2020 from https://en.wikipedia.org/wiki/Solar_power_by_country:

|             | 2010 (MW) | 2016 (MW) | 2020 (MW) |
| ----------- | --------- | --------- | --------- |
| USA         | 5260      | 40,300    | 75,572    |
| Russia      | 10        | 77        | 1,428     |
| China       | 10,189    | 78,070    | 254,355   |
| EU          | 13,238    | 101,433   | 152,917   |
| India       | 1176      | 9,010     | 39,211    |
| Japan       | 5579      | 42,750    | 67,000    |
| Other       | 4549      | 34,860    | 123,487   |

2016 other is 306,500 minus listed polities; 2020 other is 713,970 minus listed polities.  
2010 "guesses" are proportionate to 2016 with total equal to ~40,000 for the world.


ISS solar power is 75-90 kw: https://www.nasa.gov/feature/facts-and-figures. Per wiki this is USOS segment. I'm assuming this is peak (not average) so we use high end (0.09 MW) for our capacity. Utilization is 50% for this orbit.  
Zvezda (Roscosmos segment) has its own power; ooma 0.03 MW.  
Tiangong ooma: 0.04 MW.

#### WIND_POWER

Peak installed capacity from https://en.wikipedia.org/wiki/Wind_power_by_country:

|             | 2010 (MW)                | 2020 (MW)                |
| ----------- | ------------------------ | ------------------------ |
| USA         | 40,180                   | 117,744                  |
| Russia      | 15.4                     | 945                      |
| China       | 44,733                   | 281,993                  |
| EU          | 84,000 (rough addition)  | 201,507                  |
| India       | 13,065                   | 38,559                   |
| Japan       | 2304                     | 4206                     |
| Other       | 196,630 - above = 12,333 | 733,276 - above = 88,322 |

## facilities_operations_utilizations.tsv

Row prefix: `OPERATION_`   
Column prefix: `FACILITY_`  
Table is transposed internally, access: `table[facility_type][operation_type]`

Internally, we convert utilization to rates (rate = capacity x utilization), then convert back to utilization(%) for GUI.

utilization = ["capacity factor"](https://en.wikipedia.org/wiki/Capacity_factor)

For renewables, utilization is environmentally determined. For solar, we calculate based on distance to sun and solar_occlusion (or really, solar_occlusion was back-calculated to give actual utilization). For other renewables, initial utilization set in table is maintained and never changes.

For most other operations, utilization can be changed by player or game AI, assuming no input shortages. Game AI automation attempts to deal with projected internal usage, shortages and commitments, or (otherwise) maximize profitable operations and minimize unprofitable.

https://en.wikipedia.org/wiki/List_of_renewable_energy_topics_by_country_and_territory

#### SOLAR_POWER

Can't find one source that gives estimations of solar power generation! (Or any source for some countries...)

From https://en.wikipedia.org/wiki/Capacity_factor:  
USA: 25.1 - 26.1% (for PV, the majority); ~22% for CSP  
UK : 5.1 - 11.8%, average ~9%

From https://en.wikipedia.org/wiki/Solar_power_in_the_United_States, PV (utility) 24.6%, PV (small scale) 17%, Thermal 20.5%.

From https://en.wikipedia.org/wiki/Solar_power_in_the_European_Union:  
"In 2011 the EU's solar electricity production is evaluated as ca 44.8 TWh in 2011 with 51.4 GW installed capacity." From this we get 9.94% utilization. It would be nice to have a more recent estimation...

From https://en.wikipedia.org/wiki/Solar_power_in_India, installed capacity was 39,083 MW as of Feb, 2021, and generation was 60.4 TWh from Apris 2020 to March 2021. From this we get 17.6% utilization.

Didn't find generation estimations for China or Japan.

Combining above with some guesses:

    USA    24%  
    Russia  8% (worse than EU I would think)  
    China  20% (mainly in west; I guess better than EU, but not quite US)  
    EU     10%  
    India  17.6%  
    Japan  14% (guess)  
    Other  30% (my guess for an average; should be quite good w/ Australia, Africa, Middle East, etc...)  

For spacecraft in low Earth orbit: 50%.

#### WIND_POWER

From https://en.wikipedia.org/wiki/Wind_power_by_country, we use 2020-2021 energy production and 2020/2021 (average) capacity to calculate utilization for listed nations. We assume 2010 utlization is the same.

| | production (TWh) / capacity (MW) | x 1e6 MW/TW / (8766 h/yr) = | 
| ------- | -------------------------- | ----------------------------------|
| USA     | 384  / 125,241             | 0.350 (USA has great wind!)       |
| China   | 656  / 305,483             | 0.245                             |
| India   | 68.1 / 38,559              | 0.197                             |
| Russia  | ?                          | 0.2  (guess)                      |
| EU      | ?                          | 0.2  (guess; Europe is wind-poor) |
| Japan   | ?                          | 0.28 (guess; good offshore?)      |
| Other   | ?                          | 0.25 (low/middle of range)        |

For reference, https://en.wikipedia.org/wiki/Capacity_factor lists values for:  
* USA: ~32-37%, average ~34%
* UK onshore: ~27-33%, average ~30%
* UK offshore: ~26-41%, average ~35%
(But continental Europe is less than UK, I believe...)

#### TIDAL_POWER, HYDROPOWER

From https://en.wikipedia.org/wiki/Capacity_factor, typical values: 
Wave & tidal in UK: ~0-9%, average ~5% (is it really this bad?!)   
Hydro (US & UK): ~33-43%, average ~38%

#### GEOTHERMAL_POWER (TODO)

From https://en.wikipedia.org/wiki/Capacity_factor, USA ~73-77%, average ~75%.

## facilities_resources.tsv

Ooma numbers. Just gave everyone something...

Electricity: ~1 day of their total production.

## facilities_populations.tsv

Polity (non-playable) players: 

|           | 2010               | 2020           |
| --------- | ------------------ | -------------- |
| USA       | 309,349,689        | 331,449,281    |
| Russia    | 142,849,472        | 143,054,637    |
| China     | 1,339,724,852      | 1,412,600,000  |
| EU        | 501,098,000        | 447,207,489    |
| India     | 1,182,105,564      | 1,407,563,842  |
| Japan     | 128,056,000        | 126,226,568    |
| Other     | 3,240,339,134      | 3,926,898,183  |

Other 2010 = 6,843,522,711 (world) - 3,603,183,577 (6 listed)  
Other 2020 = 7,795,000,000 (world) - 3,868,101,817 (6 listed)

https://en.wikipedia.org/wiki/List_of_countries_by_population_in_2010   
https://en.wikipedia.org/wiki/Demographics_of_the_European_Union

"Population" of space agency players on Earth is employees. Wiki plus guesswork:

|           | ~2010      | ~2020 (or 22ish) |
| --------- | ---------- | ---------------- |
| NASA      | 18,291     | 16,981  |
| Roscosmos | 170,500(?) | 170,500 | trend?
| CNSA      | 174,000(?) | 174,000 | CASC numbers (can't find CNSA); trend?
| ESA       | 2200(?)    | 2200    | trend?
| ISRO      | 16,786(?)  | 16,786  | trend?
| JAXA      | 1635       | 1525    | as best I can understand from jaxa.jp

Note: we are mixing CNSA and CASC, which are really two different entities.  
NASA actual numbers for fy 2010, 2020: https://en.wikipedia.org/wiki/NASA#cite_note-3

## major_strata.tsv

Enumeration table for names of physical strata that may occur in any body.

## mod_classes.tsv

Enumeration table for module classes.

## modules.tsv

Modules usually represent real physical components (e.g., a nuclear plant) and
(mostly) have integral quantities. But we can have different modules that allow
the same Operation in different contexts, each with its own 'op_quantity'. So,
for example, we can have small portable nuclear reactors appropriate for small
space facilities. (But some of this gets a little weird with service economy
and intangible resources.)

See "one operation unit" as defined for different op classes (above).



For power generators, 1 module -> 1 GJ/d at 100% capacity. For most others,
1 module -> 1 t/d of mass converted at 100% capacity.


FIXME: Changed power from GJ/d -> MW

MODULE_SOLAR_ARRAYS
Surface power density (SPD) 6.63 W/m^2 on Earth;
https://en.wikipedia.org/wiki/Surface_power_density
1 m^2/6.63e-6 MW x 1 MWh/3.6 GJ x 1d/24h -> 1746 m^2 for 1 GJ/d on Earth.
This is obviously different in space depending on distance to sun and orbit
body blocking. We set 'area' at 1/4 this amount for the general case of space,
full-sun at 1 AU.

MODULE_COMBUSTION_GENERATORS
SPD = solar x 6.63/482 -> 24 m^2

MODULE_FISSION_REACTORS
SPD = solar x 6.63/241 -> 48 m^2

MODULE_DT_FUSION_REACTORS
ooma same as fission

MODULE_DD_FUSION_REACTORS
ooma same as fission

MODULE_DHe3_FUSION_REACTORS
ooma same as fission

MODULE_He3He3_FUSION_REACTORS
ooma same as fission

MODULE_MINES
MODULE_AIR_CONDENSERS
MODULE_FARMS
MODULE_WATER_ELECTROLYZERS
MODULE_GASSIFIERS
MODULE_GAS_CONVERTERS
MODULE_REFINERIES
MODULE_FERMENTERS
MODULE_ISOTOPE_SEPARATORS
MODULE_SMELTERS
MODULE_CEMENT_KILNS
MODULE_GLASS_KILNS
MODULE_RECYCLING_PLANTS
MODULE_CHIP_FABRICATORS
MODULE_FACTORIES
MODULE_CHEMICAL_PLANTS
MODULE_PHARMACEUTICAL_PLANTS
MODULE_SERVER_CLUSTERS
MODULE_URBAN_SURFACE
MODULE_CREW_FACILITIES
MODULE_HABITATS
MODULE_LAUNCH_FACILITIES




## moons_mod.tsv

Modifies ivoyager/data/solar_system/moons.tsv.

## op_classes.tsv

Op classes define GUI tab groups for operations: Energy, Extraction, etc.

## op_groups.tsv

Op groups define GUI '>' subgrouping for operations.

## operations.tsv

Operations define most of the things that "happen" on bodies with facilities, mainly involving resource extraction and conversion. Operations are allowed by Modules.
 
Internally in the 'Operations' object we have arrays 'capacities' and 'rates'. We are at 100% utilization when rate == capacity. 

"One unit of capacity" is defined by op_class:

    ENERGY        - 1 MW electrical output (ie, MWe)
    EXTRACTION    - 1 t/d extracted ore x (deposits/100 if deposits, or mass fraction)
    BIOME         - 1 km^2 equivilant Earth area
    REFINING      - 1 t/d total mass conversion (=input or output, always same)
    MANUFACTURING - 1 t/d total production (= mass conversion as above)
    SERVICES      - 1 unit/d of whatever intangible resource(s) is(are) produced

#### SOLAR_POWER, WIND_POWER, TIDAL_POWER, HYDROPOWER

Capacity unit is 1 GW by definition. Utilization is subject to the environment.   
See comments in facilities_operations_utilizations.tsv.   
For solar, utilization is a function of disance from sun and solar_occlusion (from bodies.tsv or override value from facilities.tsv).   
For other renewables, table value in facilities_operations_utilizations.tsv never changes.

#### COAL_COMBUSTION_POWER
Typical "bituminous" coal: 84.4% C, 5.4% H2, 6.7% O2, 1.8% S, 1.7% N2;   
Energy density 24 MJ/kg, for 40% efficiency, "325 kg will power 100 W for yr";   
https://en.wikipedia.org/wiki/Coal   
0.325t/100Wyr x 1yr/365.25d x 10^6W/MW x 1MWd/86.4GJ -> 103 t coal/1000 GJ   
Combustion:   
(84% C) C + O2 -> CO2; mws 12.011 + 31.998 -> 44.009   
(5.4% H2) 2 H2 + O2 -> 2 H2O; mws 4.032 + 31.998 -> 36.03   
(1.8% S) S + O2 -> SO2; mws 32.06 + 31.998 -> 64.058   
(1.7% N2) N2 -> N2 (ignoring NOx)   
(6.7% O2) Assume cobusted so deduct from O2 input   
Per 103 t coal,   
86.5 C (in coal) + 230.5 O2 -> 317 CO2   
5.56 H2 (in coal) + 44.1 O2 -> 49.7 H2O   
1.85 S (in coal) + 1.85 O2 -> 3.70 SO2   
6.90 O2 (in coal) - 6.90 O2 -> nothing   
	-> + 1000 GJ power   
t per 1000 GJ: 103 coal + 269 O2 -> 317 CO2 + 49.7 H2O + 3.70 SO2 + 1.75 N2   
We could balance mass with 'ash' product if we want to go there.   
This is close to wiki CO2 emmisions data: 1001 g CO2/kWh;   
https://en.wikipedia.org/wiki/Electricity_generation   
1001g/kWh x 10^-6t/g x 1e6kWh/3600 GJ -> 278 t CO2/1000 GJ   

#### OIL_COMBUSTION_POWER
We're simplifying and burning oil directly rather than processing to fuel oil.   
84% C, 12% H2, 3% S, 1% O2, 1% N2   
https://en.wikipedia.org/wiki/Petroleum   
Specific energy ~42 versus ~30 of Coal (1.4x)   
https://en.wikipedia.org/wiki/Energy_density   
Ajusting totals from Coal (in t),   
t per 1000 GJ: 73.6 oil + 197 O2 -> 226 CO2 + 78.9 H2O + 1.47 SO2 + 0.735 N2   
(Assuming 40% efficiency. Is this ok?)   

#### REFINED_FUELS_COMBUSTION_POWER
Specific energy gasoline 46.4, kerosene 43 MJ/kg;   
https://en.wikipedia.org/wiki/Energy_density   
For octane, 1kg C8H18 + 3.51kg O2 -> 3.09kg CO2 + 1.42kg H20   
https://en.wikipedia.org/wiki/Gasoline   
If we use S.E. 44 MJ/kg, we have (in t):   
t per 1000 GJ: 70.3 fuel + 247 O2 -> 217 CO2 + 99.8 H20   
(Assuming 40% efficiency. Is this ok?)   

#### ETHANOL_COMBUSTION_POWER
Specific energy 30 MJ/kg HHV   
https://en.wikipedia.org/wiki/Energy_density   
C2H5OH + 3 O2 -> 2 CO2 + 3 H2O; mws 46.069 + 95.994 -> 88.018 + 54.045   
t per 1000 GJ: 103 ethanol + 214 O2 -> 197 CO2 + 121 H2O   
(Assuming 40% efficiency. Is this ok?)   

#### METHANE_COMBUSTION_POWER
Specific energy 55.6 MJ/kg HHV (natural gas 53.6)   
https://en.wikipedia.org/wiki/Energy_density   
CH4 + 2 O2 -> CO2 + 2 H2O; mws 16.043 + 63.996 -> 44.009 + 36.03   
t per 1000 GJ: 55.6 methane + 222 O2 -> 153 CO2 + 125 H2O   
This is close to wiki CO2 emmisions data: natural gas 669 g CO2/kWh,   
-> 186 t CO2/1000 GJ   
https://en.wikipedia.org/wiki/Electricity_generation   

#### HYDROGEN_COMBUSTION_POWER
aka, fuel cells   
Specific energy 141.86 MJ/kg HHV   
2 H2 + O2 -> 2 H2O; mws 4.032 + 31.998 -> 36.03   
t per 1000 GJ: 21.8 H2 + 173 O2 -> 195 H2O   

#### PROCESS_FISSION_POWER
Our proxy "fission fuel" is yellowcake.   
Total yellowcake volume for 2020 was 92 million lb;   
https://www.yellowcakeplc.com/uranium-market/   
Total nuclear power supplied in 2019 was 2,586 TWh   
https://en.wikipedia.org/wiki/Nuclear_power   
96e6 lbs/2586 TWh x 1 TWh/3.6e6 GJ x 1kg/2.20462 lbs -> 0.00468 kg/GJ   
-> 4.68 kg / 1000 GJ   
Assume 90% used for power, so 5.20 kg yellowcake / 1000 GJ power.   

#### PROCESS_DT_FUSION_POWER
#### PROCESS_DHe3_FUSION_POWER

#### OIL_EXTRACTION

#### COAL_MINING
Coal Recovery ratio: 82%   
Coal Btu/Ton mined: 370,628   
Using this US study, 2000, mostly Exhibit 5 & 14:   
https://www.energy.gov/sites/default/files/2013/11/f4/mining_bandwidth.pdf   
Per t mined:   
370,628 Btu/Ton x 1.06 GJ/1e6 Btu x 1 ton/0.907 t -> 0.433 GJ/t   
0.82 t coal   
0.18 t regolith   


1e6 Btu = 1.06 GJ   
1 ton = 0.907 tonne (t)   

#### FISSILE_FUELS_MINING
#### HELIUM3_MINING

#### IRON_MINING_, INDUST_METALS_MINING, PRECIOUS_METALS_MINING_

Source for energy/t for gold, copper, nickle, iron (download pdf report): https://www.ceecthefuture.org/resources/mining-energy-consumption-2021.

* Iron magnetite: 0.3 GJ/t ore(!); 41% mining, 43% comminution, 16% other processing
* Iron hematite: 0.15 GJ/t ore(!); 90% mining, 10% processing
* Copper: 24 GJ/t final copper (average); 60% mining, 36% comminution (grinding/milling), 4% other processing (smelting???)
* Nickel (leach): 244 GJ/t final nickle (average); 59% mining, 29% comminution, 12% other processing
* Lithium: 15 GJ/t hydroxide (I think); 48% mining, 47% comminution, 5% other processing
* Gold (underground, higher grade): 130,000 GJ/t unrefined gold bars; 45% mining, 26% comminution, 29% other processing

The reason for the 6-orders-of-magnitude differences above is due mainly to differences in ore deposits. Rougly speaking, 500,000x more mining/comminution is needed to get a tonne of gold ore versus a tonne of iron ore. We simulate that by having extraction rate multiplied by "known deposits" level, with Earth deposits: ~33% (iron), 0.033% (indust metal), 1e-4% (precious metals).

Note: We tweeked compositions to give above deposits. If this gives us wrong total masses, we can re-adjust compositions and tweek energies here.

For all but iron, "other processing" is smelting (converting ore to metal). We use average of the two iron ores, and use nickle and gold as our proxies for industrical and precious metals.
  
1 MWh = 3.6 GJ.   
1 GJ/t at 1 t/d, x 1/3.6 MWh/GJ x 1/24 d/h = 1.157e-2 MW   
For ops power, multiply above by the ore's power consumption (above) and the ore's typical Earth deposits fraction (from Compositions values).   

For iron mining (1 t/d ore extraction):   
0.22 GJ/t x 0.33 -> 8.49e-4 MW   

For industrial metals mining (using 88% of Nickel power above):   
215 GJ/t -> 0.828 MW   

For precious metal ores (using 71% of Gold power above, x 1000 kg/t):   
102,700 GJ/t -> 396 MW   




#### URBAN_DEVELOPED
Allows 20000 humans / km^2, which is about the density of Paris proper:
https://en.wikipedia.org/wiki/List_of_cities_proper_by_population_density
In 2010 & 2020, 51% & 56% of humans were "urban":
https://en.wikipedia.org/wiki/World_population

For game start facility values, we assume urban capacity is 2x its present
inhabitants (which is ~50% of total population).
'rate' is n/a for this operation.
TODO: Mechanism to grow urban capacity.

#### SMALL_FOOD_FARMING
Allows 100 humans / km^2. Capacity is ~1x total population.
All private sector (is this way off for Russia, China?).




## planets_mod.tsv

Modifies ivoyager/data/solar_system/planets.tsv.


## players.tsv

Game start only.

## populations.tsv

Different kinds of humans or non-humans, corporeal or virtual, that we want to count in total Population. Mostly sentient but for game flavor we also have sub-sentient androids.

## resource_classes.tsv

Categories for GUI tabs: Energy, Ores, Volatiles, etc.

## resources.tsv

'trade_unit' is the quantity for 'price', the unit used for GUI display and the unit for internal representation in the Inventory object.   
'start_price' is on Earth only.


#### ELECTRICITY
Cannot be transported, but traded w/in a Body. Special storage.
LCOE on the order of $60/MWh (6 cents/kWh), say $100/MWh wholesale,
x 1 MWh/3.6 GJ -> $27.8/GJ
https://en.wikipedia.org/wiki/Cost_of_electricity_by_source

#### COAL
$189/t; 2/22

#### OIL
$70/barrel oil x 7.33 barrels/t = $513/t

#### REFINED_FUELS
$3.57/gallon for kerosine -> or $1180/t

#### ETHANOL
$849/t; 2/22 chemanalyst.com

#### METHANE
$4/MMBtu, ~$4/1000ft3, ~$4/GJ x 0.049 GJ/kg x 1000 kg/t = $196/t

#### HYDROGEN
$1390/t; https://en.wikipedia.org/wiki/Prices_of_chemical_elements

#### FISSILE_FUELS
Prices for uranium oxide "yellowcake" bottomed in 2001 at $7/lb and topped in
2007 at $137/lb;
https://en.wikipedia.org/wiki/Uranium_market
Found recent price $42.43/lb U3O8e (source?)
x 2.20462 lb/t -> $93.54/kg



#### DEUTERIUM
?

#### HELIUM3
Wiki - "historically about $100/liter" (gas?? Presure?) "59 gram per liter at 1 atm".
Assume price is at 1atm. Then, $100/59g.

#### IRON_ORES
Defined as 70% Fe by weight (e.g., magnatite). We assume benefacation to this
grade, with resource proportion being our abstraction for mine quality.
$150/t, typical market pr, 2/22; .

#### INDUSTRIAL_METAL_ORES
Defined as 1% Industrial Metals by weight (Ni ores typically ~1%). (See
_IRON_ORES note on grade and benefication.)
Represents Al, Cu, Ni, etc. Using Ni as proxy.
Nickle ore market pr $30 ("low grade") to $90, 2/22.

#### PRECIOUS_METAL_ORES
Defined as 0.003% Precious Metals by weight (the high end of Earth Au ores,
0.0001-0.0030%). (See _IRON_ORES note on grade and benefication.)
Au, Pl, etc., but we use Au as proxy.

#### RARE_EARTH_ORES
Defined as 1% Rare Earths by weight. (See _IRON_ORES note on grade and
benefication.)
ooma price

#### INDUSTRIAL_MINERAL_ORES
Defined as 30% Industrial Minerals by weight. (See '_IRON_ORES note on grade and
benefication.)
ooma price

#### FISSILE_FUEL_ORES
Defined as 1% Fissile Fuels by weight (Earth grades range from 0.1% up to 18%,
but 1% is typical). (See '_IRON_ORES note on grade and benefication.)   
https://en.wikipedia.org/wiki/Uranium_ore   
For price assume 1% grade and 10% price of yellowcake, giving $93/t.   
TODO: fix numbers given that we abstract away yellowcake, which is an intermediate
form customarily produced at the mine (but not in our simulation).

#### HELIUM3_REGOLITH
N/A Earth; no start price.

#### INDUSTRIAL_MINERALS
ooma price

#### THOLINS
N/A Earth; no start price.

#### ROCK_AGGREGATE
$20/t is low range of prices in Google search. Assume $5/t for industry.

#### LOW_GRADE_REGOLITH
Dirt; give it $2/t for transport.

#### WATER
Wide range of pricing; trucked values as low as $1/t.

#### OXYGEN
$154/t; https://en.wikipedia.org/wiki/Prices_of_chemical_elements

#### NITROGEN
$140/t; https://en.wikipedia.org/wiki/Prices_of_chemical_elements

#### CARBON_DIOXIDE
$182/t; chemanalyst.com

#### CARBON_MONOXIDE
$28700/t; chemanalyst.com

#### ETHANE
Couldn't find price but $600/t for methanol; chemanalyst.com

#### AMMONIA
$1000/t; chemanalyst.com

#### SULFER_DIOXIDE
Couldn't find but $312/t for sulfur

#### HELIUM
$24,000/t; https://en.wikipedia.org/wiki/Prices_of_chemical_elements

#### ARGON_NEON
$931/t; https://en.wikipedia.org/wiki/Prices_of_chemical_elements

#### KRYPTON_XENON
Kr & Xe; Kr is cheaper (by far) at $290/kg;
https://en.wikipedia.org/wiki/Prices_of_chemical_elements

#### STEEL
$1500/t; random news article, early 2022.

#### INDUSTRIAL_METALS
Al $1790/t, Ni $13900/t, Cu $6000/t; use Cu as proxy price.
https://en.wikipedia.org/wiki/Prices_of_chemical_elements

#### PRECIOUS_METALS
Use Au as proxy at $60000/kg, 2/22.

#### RARE_EARTHS
Light REs ~$41,000/kg; Heavy REs ~$21,0000/kg
We split the difference and call it $100,000/kg.

#### CONCRETE
random source?

#### GLASSES
ooma

#### PLASTICS_POLYMERS
$1200/t for styrene; chemanalyst.com

#### SYNTHETIC_FIBERS
Random source "average cost of non- aerospace grade is around $21.5/kg"

#### INDUSTRIAL_SCRAP
Steel scrap $0.23/lb x 2204 lbs/t = $506/t; random online source.

#### SLAG
$200/t; random online slag quote

#### BULK_FOODS
Grain, etc.; source?

#### CRAFT_FOODS
$20 bag of groceries. These are "luxury" in space.

#### WOOD
ooma

#### BIOFIBERS
ooma

#### BIOFEEDSTOCK
ooma

#### SEWAGE
ooma

#### FINISHED_STRUCTURES
ooma

#### HEAVY_MACHINERY
ooma

#### ROBOTICS
ooma

#### ELECTRONICS
ooma

#### BATTERIES
Tesla car battery on the order of ~$3-4k; call it $2000/t. 

#### ADVANCED_COMPOSITES
$85/kg; aerospace cabon fiber, 2022 news article

#### FERTILIZERS
$717/t; 2022 news article.

#### INDUSTRIAL_CHEMICALS
ooma; presumably more than kerosine

#### FINE_CHEMICALS
ooma

#### PHARMACEUTICALS
ooma

#### CONSUMER_GOODS
ooma

#### LUXURY_GOODS
ooma


## spacecrafts.tsv

Replaces ivoyager table of the same name. Game start only.

## strata.tsv

Specific geophysical layers for the purpose of defining Compositions (which define resources).

## surveys.tsv

Defines our knowledge about resources in a particular strata: both deposits (if applicable) and estimation errors.

## technologies.tsv



