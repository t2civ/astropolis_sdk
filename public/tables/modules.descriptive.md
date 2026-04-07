# Modules

Modules are the physical infrastructure that implement operations.

Notes:

1. Modules have a one-to-many relationship with operations. Each module provides capacity for one or more operations, and each operation belongs to exactly one module.
2. Although described here in terms of individual units, modules are implemented as a continuous "capacity" value.
3. A module's capacity can be shifted ("reconfigured") among its enabled operations. E.g., Combustion Power Plants (which really represents a capacity of combustion plants) could be shifted from 70% Coal Power / 30% Methane Power to 40/60 over time. Speed and cost of reconfiguration are fixed properties of each module. This could represent anything from a major refitting/retooling/relocation to a minor operational adjustment, depending on the module.


## Energy

- **Solar Arrays** — Photovoltaic and concentrated solar thermal installations at all scales, from utility-scale solar farms to rooftop and building-integrated deployments. Primary power sources across the inner solar system. Concentrated solar thermal variants may provide facility or district heat.
- **Geothermal Plants** — Power stations extracting heat from planetary interiors via hydrothermal wells or engineered hot-rock systems. Applicable on Earth and tidally heated bodies. May provide facility or district heat.
- **Hydroelectric Dams** — River impoundment or run-of-river hydropower installations.
- **Wind Farms** — Utility-scale wind turbine arrays, onshore or offshore. Applicable on Earth, Mars, Venus upper atmosphere, and Titan.
- **Tidal Power Stations** — Tidal barrage or tidal stream turbine installations exploiting gravitational tidal forcing. Earth-only under foreseeable conditions.
- **Combustion Power Plants** — Utility-scale thermal power stations with boilers and gas turbines for burning hydrogen, methane, methanol, ethanol, liquid hydrocarbons, oil, or coal to generate electricity. May provide facility or district heat.
- **Fuel Cells** — Stationary fuel cell installations at all scales, from centralized grid-scale plants to small units for buildings, vehicles, and remote installations, operating on hydrogen, methane, or methanol. May provide facility or district heat.
- **LEU Nuclear Plants** — Light-water or heavy-water reactor power stations operating on low-enriched uranium fuel. May provide facility or district heat.
- **HEU Nuclear Reactors** — Compact high-enrichment uranium reactors for naval propulsion, space power, and other applications requiring high power density at small scale. May provide facility heat.
- **Thorium Nuclear Plants** — Thermal-breeder reactor power stations operating on thorium-cycle fuel with in-situ breeding of fissile uranium-233. May provide facility or district heat.
- **D-T Fusion Plants** — Deuterium–tritium fusion power stations with lithium tritium-breeding blankets. May provide facility or district heat.
- **D-³He Fusion Plants** — Deuterium–helium-3 fusion power stations producing substantially fewer neutrons than D-T designs. May provide facility or district heat.
- **³He-³He Fusion Plants** — Helium-3 fusion power stations producing no neutrons but requiring the highest ignition temperature of practical fusion cycles. May provide facility or district heat.
- **Radioisotope Generators** — Radioisotope thermoelectric or Stirling generator units using plutonium-238 or strontium-90. Low power density but extreme reliability and longevity; critical for deep outer solar system installations. May provide facility heat.


## Extraction

- **Mines (surface)** — Open-pit, strip, and placer mining capacity for solid resource extraction from surface strata to approximately 100 m depth. Target ore proportions adjustable over time.
- **Mines (near-surface)** — Underground and deep open-pit mining capacity for strata at approximately 0.1–0.5 km depth, including sub-seafloor operations on continental shelves.
- **Mines (subsurface)** — Underground mining capacity for strata at approximately 0.5–2.0 km depth.
- **Mines (deep subsurface)** — Underground mining capacity for deep strata at approximately 2.0–5.0 km depth.
- **Wells (surface)** — Well drilling and completion equipment for gaseous and liquid hydrocarbon extraction from surface-accessible formations to approximately 100 m depth on land.
- **Wells (near-surface)** — Well drilling and completion equipment for hydrocarbon extraction from formations at approximately 0.1–0.5 km depth, including offshore continental shelf.
- **Wells (subsurface)** — Well drilling and completion equipment for hydrocarbon extraction from formations at approximately 0.5–2.0 km depth.
- **Wells (deep subsurface)** — Well drilling and completion equipment for hydrocarbon extraction from formations at approximately 2.0–5.0 km depth.
- **Wells (extreme subsurface)** — Well drilling and completion equipment for hydrocarbon extraction from formations at approximately 5.0–12.0 km depth.
- **Quarries** — Surface extraction operations for bulk stone and loose regolith, producing construction aggregate, dimension stone, and industrial or ISRU feedstock.
- **Atmosphere Processors** — Cryogenic distillation, pressure-swing adsorption, membrane separation, or centrifugal processing plants for separating target gases from planetary atmospheres. On gas giants, represent atmospheric skimming or balloon-based harvesting systems.
- **Volatiles Extraction Plants** — Thermal processing, sublimation trapping, and mechanical extraction facilities for recovering water, carbon dioxide, ammonia, and other volatile species from ice deposits, permafrost, regolith, and brine reservoirs.
- **Hydrocarbon Processors** — Surface collection and primary separation infrastructure for liquid hydrocarbon bodies, principally Titan's methane–ethane seas.
- **Desalination Plants** — Reverse osmosis, multi-stage flash distillation, or electrodialysis facilities producing fresh water from seawater, brackish water, or brine, with integrated mineral recovery from concentrated reject brine. On ocean worlds, applicable to melt-probe or plume-sourced water.
- **Brine Processing Plants** — Selective ion exchange, fractional crystallization, solvent extraction, and evaporation facilities for recovering dissolved minerals and salts from subsurface brines and inland saline water bodies.


## Refining

- **Oil Refineries** — Fractional distillation, catalytic cracking, and hydroprocessing facilities for crude oil. Produce liquid fuels, petrochemical naphtha, and industrial solvents with elemental sulfur recovery.
- **Iron-Nickel Refineries** — Pyrometallurgical and hydrometallurgical facilities for processing native iron–nickel alloy from asteroidal and other metallic sources, with recovery of cobalt, platinum-group metals, and other by-products.
- **Steel Mills** — Integrated iron and steel production facilities encompassing blast furnaces, direct-reduction units, basic oxygen furnaces, and electric arc furnaces. Capacity adjustable among ore-reduction and steelmaking methods over time.
- **Solar Furnaces** — Concentrated-sunlight thermal processing facilities for direct solar reduction and melting of metals. Sited at high-insolation locations such as lunar or Mercurian polar crater rims, or on solar-tracking platforms on slowly rotating bodies.
- **Aluminium Smelters** — Electrolytic smelting facilities for aluminium production, covering Hall–Héroult, carbothermal reduction, and molten-salt electrolysis processes. Off-Earth variants processing anorthositic feedstock co-produce oxygen.
- **Industrial Metals Smelters** — Smelting, solvent extraction, and electrorefining facilities for base metals including copper, nickel, zinc, chromium, manganese, titanium, and others. Sulfide smelting generates sulfuric acid as a co-product.
- **Precious Metals Refineries** — Fire assay, chlorination, solvent extraction, and electrorefining facilities for gold, silver, and platinum-group metals from ores, concentrates, and intermediate feeds such as anode slimes.
- **Rare Earths Refineries** — Acid or alkali digestion and multi-stage solvent extraction facilities for separating rare-earth concentrates into individual oxide and metal products.
- **Uranium Processing Plants** — Leaching, solvent extraction, and fluorination facilities for converting uranium ore through yellowcake to purified uranium hexafluoride at natural isotopic assay.
- **Regolith Processing Plants** — Bulk electrochemical or carbothermic reduction facilities for extracting oxygen and metal–metalloid separates from unsorted regolith without prior ore beneficiation. Key early-stage ISRU installations on airless bodies and Mars.
- **Isotope Separation Plants** — Cryogenic distillation and electrolysis cascade facilities for separating deuterium from natural-abundance hydrogen or water to produce fusion-grade fuel.
- **Recycling Centers** — Municipal waste collection, mechanical and optical sorting, and material recovery facilities with waste-to-energy incineration or plasma gasification for non-recyclable residual. Essential for mass-closure in space habitats.
- **Industrial Recycling Facilities** — Mechanical shredding, pyrometallurgical smelting, and hydrometallurgical processing facilities for end-of-life equipment, manufacturing scrap, spent catalysts, and mixed industrial waste. Essential for mass-closure in space habitats.
- **Nuclear Fuel Reprocessing Plants** — Aqueous or pyrochemical separation facilities for recovering fissile material from irradiated uranium and thorium fuel assemblies and concentrating fission products into vitrified high-level waste.


## Conversions/Synthesis

- **Electrolysis Plants** — Electrochemical facilities for splitting water into hydrogen and oxygen or reducing carbon dioxide to carbon monoxide and oxygen. PEM, alkaline, and solid-oxide cell types. Fundamental ISRU installations throughout the solar system.
- **Catalytic Reactor Plants** — Catalytic reactor facilities for gas-phase chemical conversions including Sabatier methanation, methane reforming, water-gas shift, methanol synthesis from carbon monoxide or carbon dioxide, Fischer–Tropsch hydrocarbon synthesis, and high-pressure Haber–Bosch catalytic synthesis of ammonia from hydrogen and nitrogen.
- **Gasification Plants** — Thermal gasification facilities converting coal, biomass, and other solid carbonaceous feedstocks to synthesis gas under controlled oxygen and steam injection.
- **Pyrolysis Plants** — Thermal decomposition facilities operating under oxygen-excluded or oxygen-limited conditions. Produce coke, biochar, solid carbon, and co-product gases and liquids from coal, biomass, or methane.
- **Polymer Plants** — Polymerization reactor facilities producing thermoplastics, thermosets, elastomers, and synthetic fibers from petrochemical, Fischer–Tropsch, or methanol-to-olefins feedstocks.
- **Chemical Plants** — Large-scale process facilities for commodity chemical production including chlor-alkali electrolysis, sulfuric acid contact process, nitric acid oxidation, phosphoric acid digestion, and downstream inorganic intermediates.
- **Fine Chemicals Plants** — Controlled-environment process facilities for specialty chemicals, catalysts, coatings, adhesives, electronic-grade reagents, and pharmaceutical intermediates requiring high-purity inputs and precise reaction control.
- **Concrete Plants** — Calcination kilns, clinker grinding mills, and batching facilities for cement and concrete production. Off-Earth variants include sintered-regolith binder and sulfur-concrete processing.
- **Glass/Ceramics Plants** — Melting furnaces and forming facilities for flat glass, fiber glass, technical ceramics, and refractory products. Off-Earth, basaltic regolith serves as a near-complete feedstock.
- **Semiconductor Materials Fabs** — Ultra-clean crystal growth, wafer fabrication, and epitaxial deposition facilities for silicon, gallium arsenide, silicon carbide, and compound semiconductor materials.
- **Propellant Plants** — Energetic materials mixing, casting, and curing facilities for solid rocket propellant production with grain geometry design for thrust profiling.
- **Fertilizer Plants** — Compounding and granulation facilities blending ammonia, phosphate, potash, sulfur-derived acids, and micronutrients into NPK and specialty fertilizer products.


## Manufacturing

- **Construction Yards** — On-site assembly, civil engineering, and installation capacity for fixed infrastructure including buildings, roads, tunnels, landing pads, launch facilities, power distribution networks, pipelines, pressurized habitats, and radiation shielding.
- **Space Yards** — Dedicated yard facilities for fabrication and final assembly of heavy-lift launch vehicles and large interplanetary transports, analogous to naval shipyards. Encompasses heavy tooling, large-bay construction halls, and orbital or surface assembly infrastructure.
- **Transport Factories** — Large-scale fabrication and final assembly facilities for ground vehicles, aircraft, marine vessels, small-to-medium spacecraft, EVA mobility units, and spacesuits, integrating structural, propulsion, avionics, and life-support subsystems.
- **Metal Fabrication Works** — Cutting, welding, forming, machining, galvanizing, and assembly facilities for steel and aluminium structural products including beams, plate, pipe, pressure vessels, extrusions, and prefabricated modules.
- **Composites Facilities** — Fiber-reinforced polymer and metal-matrix composite fabrication and assembly facilities for layup, filament winding, pultrusion, curing, and integration of composite materials into panels, overwrapped pressure vessels, fairings, and inflatable habitat shells.
- **Textiles Mills** — Weaving, knitting, and coating facilities for high-performance fabrics including aramid, UHMWPE, carbon-fiber cloth, PTFE membranes, multilayer insulation blankets, filtration media, and spacesuit soft goods.
- **Heavy Manufacturing Plants** — Casting, forging, machining, winding, and assembly facilities for turbines, engines, pumps, compressors, heat exchangers, generators, transformers, electric motors, and other heavy mechanical and electrical equipment.
- **Precision Manufacturing Plants** — Controlled-environment fabrication and assembly facilities for scientific instruments, medical devices, CNC machine tools, lithography systems, optical systems, and navigation hardware requiring tight tolerances and specialty materials.
- **Electronics Factories** — Printed-circuit-board fabrication, semiconductor packaging, surface-mount assembly, display production, and system integration facilities for general-purpose computing, communications, and sensor hardware.
- **Advanced Processor Fabs** — Extreme-ultraviolet lithography, high-bandwidth memory stacking, and advanced-packaging facilities for fabrication of high-performance tensor processors and neuromorphic computing hardware.
- **Robotics Factories** — Fabrication and integration facilities for robotic manipulators, autonomous mobile platforms, and AI-hardware systems, combining structural, actuator, sensor, and advanced processor subsystems.
- **Solar Panel Factories** — Photovoltaic module production lines covering silicon ingot slicing, cell fabrication or thin-film deposition, glass encapsulation, aluminium framing, and copper interconnect wiring.
- **Battery Factories** — Electrode coating, cell stacking, electrolyte filling, formation cycling, and battery-pack assembly facilities for lithium-ion and successor solid-state chemistries.
- **Nuclear Fuel Fabrication Plants** — Uranium enrichment cascades, fuel pellet sintering, cladding tube loading, and fuel bundle assembly for low-enriched, high-enriched, and thorium-cycle reactor fuels. Produce depleted uranium hexafluoride tails as a by-product of enrichment.
- **Consumer Goods Factories** — Mass-production facilities for furniture, clothing, housewares, paper products, personal care items, building finishes, personal electronics, and other consumer and specialty goods.


## Biological

- **Crew Systems** — Integrated environmental control and life support hardware for crewed spacecraft, stations, and surface habitats, including atmosphere processors, water recovery units, thermal control systems, fire suppression, and radiation protection.
- **Cities & Towns** — Built environment of human settlements encompassing residential, commercial, transportation, utility, and public-service infrastructure from small outposts to major metropolitan areas.
- **Industrial Farms** — Large-scale mechanized farms for conventional crop cultivation and livestock raising on open land under ambient atmospheric conditions.
- **Controlled-Environment Farms** — Sealed pressurized greenhouses or habitat grow modules for crop cultivation and animal husbandry with artificial or filtered lighting, active atmosphere management, water recycling, and nutrient delivery.
- **Artisanal Farms** — Small-scale family farms for artisanal and specialty food production including cheeses, preserves, craft beverages, and baked goods.
- **Artisanal Workshops** — Small-scale handcraft workshops for pottery, handmade textiles, woodcraft, leatherwork, and other artisanal non-food goods.
- **Commercial Fishing Fleets** — Marine and freshwater wild-capture fishing vessels with shore-side landing and processing infrastructure.
- **Aquaculture Farms** — Open-water marine or freshwater farming installations for fish, shellfish, and seaweed using net pens, longlines, or pond systems.
- **Controlled-Environment Aquaculture Facilities** — Sealed recirculating aquaculture systems for fish, shellfish, and algae production in isolated or off-Earth installations where open-water farming is unavailable.
- **Forestry Operations** — Managed tree plantations and harvest operations producing timber, pulp, and biomass feedstock under open atmospheric conditions.
- **Algal Cultivation Facilities** — Photobioreactor and open-pond installations for microalgae and cyanobacteria cultivation. Produce food-grade biomass and industrial biofeedstock; co-produce oxygen via photosynthesis.
- **Bioreactor Facilities** — Industrial bioreactor installations for cellular agriculture, ethanol fermentation, and general-purpose fermentation of enzymes, amino acids, organic acids, and biopolymers.
- **Food Processing Plants** — Cooking, preservation, and packaging facilities for converting agricultural and aquacultural products into shelf-stable prepared meals and food products. Critical for space operations where fresh-food supply is intermittent.
- **Biogas Digesters** — Anaerobic digestion installations converting organic waste, crop residues, and sewage sludge to methane-rich biogas and nutrient-dense digestate.
- **Biomass Conversion Plants** — Hydrothermal liquefaction, catalytic pyrolysis-upgrading, and transesterification facilities converting biomass and biological lipids to liquid hydrocarbon fuels.
- **Pharmaceutical Plants** — Chemical synthesis, fermentation, purification, and formulation facilities for drugs, vaccines, biologics, and medical compounds.
- **Soil Conditioning Facilities** — Composting, amendment blending, pH adjustment, nutrient loading, and regolith remediation operations for preparing agricultural growth media. Critical ISRU step for establishing agriculture on extraterrestrial surfaces.
- **Wastewater Treatment Plants** — Biological, chemical, and membrane processing facilities for sewage, greywater, and mixed organic waste, with water reclamation and nutrient recovery. Critical water- and mass-closure infrastructure for off-Earth habitats.
