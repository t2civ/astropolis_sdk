# Resources (Descriptive)

Resources are items that are extracted, converted, consumed, stored, transported, and/or traded in the simulation, including tangibles and intangibles. Many are abstracted categories that represent a basket of different items in the real world.

Notes:

1. Listed elemental compositions are weight percent (summing to 100) followed by valuable co- or by-products in ppm (mainly for the extractable subset).
2. **Important:** For compositionally complex or abstract category resources, elemental compositions are for reference only. Individual cases differ from these references. Examples: different strata necessarily have different Industrial Minerals; different construction locations produce and use compositionally different Concrete; different technologies result in chemically different Batteries; etc. The simulation simplifies by treating composition within an abstract resource as fungible.
3. Natural strata are composed entirely by weight of "extractable" resources. In this context, Stone and Regolith are the main fillers for solid rocky strata. Ores represent total concentrated mass (usually much greater than what could be extracted economically) and volatiles represent what might be separated from solids in the extraction operation. Distribution of each resource within a stratum is modeled by abundance and dispersion (each having epistemic uncertainty error), where high dispersion is the most important factor for economical extraction in heterogeneous strata (e.g., for mining or drilling).
4. Most resources are traded as commodities. Many are inputs to downstream industrial processes or economic activities. A few are final products that are "absorbed" into the simulation's infrastructure or population mechanics.


## Energy

*Electricity, primary inputs to power and/or propulsion systems (excluding oxygen and non-energetic propellants), and spent nuclear fuel assemblies.*

- **Electricity** — Locally generated, stored, or transmitted electrical energy; the common output of all power-generation operations and primary energy input for industrial, residential, and life-support activities. (Special handling in the simulation; don't list as input or output resource.)
- **Hydrogen** — H₂. H 100. Extractable.
- **Methane** — CH₄. C 74.9, H 25.1. Extractable.
- **Methanol** — CH₃OH. C 38.7, O 48.3, H 13.0. Extractable.
- **Ethanol** — C₂H₅OH. C 46.1, O 30.9, H 13.1.
- **Liquid Hydrocarbons** — Liquid petroleum fuels; ref. production-weighted blend of gasoline, diesel, jet fuel, and naphtha. C 85.5, H 14, S 0.15, N 0.05, O 0.1, other 0.2.
- **Solid Fuels** — Solid rocket propellant; ref. HTPB-based ammonium perchlorate composite propellant (APCP) with aluminium powder (68/18/14 AP/Al/binder). O 37, Cl 21, Al 18, C 12, N 8, H 4.
- **Coal** — Earth only; ref. washed, air-dried thermal coal, production-weighted global blend (dominated by bituminous and sub-bituminous). C 66, O 18, H 5.5, Si 2.3, S 1.5, N 1.4, Al 1.3, Fe 0.7, Ca 0.35, K 0.17, Mg 0.12, Na 0.07, Ti 0.06, P 0.02, other 2.51. Byproducts (ppm): total REE 50 (concentrated 5–10× in coal ash — some coal ashes exceed 1000 ppm total REE; Ce 22.5, La 10, Nd 7, Y 4, Pr 2.5, Sm 1.5, Gd 1, Dy 0.5, Er 0.3, Yb 0.3, Eu 0.2, Tb 0.1, Ho 0.05, Tm 0.03, Lu 0.02), Ge 10, Ga 10, Se 3, U 3. Extractable.
- **Oil** — Earth only; ref. desalted, dewatered crude, production-weighted global average. Co-product: recovered elemental sulfur. C 84.5, H 12, S 1.5, N 0.4, O 0.6, other 1.0. Byproducts (ppm): V 150, Ni 50. Extractable.
- **LE Uranium Fuel** — Assembled LWR fuel; UO₂ pellets enriched to 4.5% ²³⁵U (95.5% ²³⁸U) in Zircaloy-4 cladding with Inconel/SS structural components; ref. Westinghouse 17×17 PWR fuel assembly (~660 kg, 80/17.5/2.5 UO₂/Zircaloy/SS by mass). U 70.5 (isotopic: 4.5% U-235, 95.5% U-238), Zr 17.2, O 9.5, Fe 1.6, Cr 0.45, Sn 0.26, Ni 0.25, other 0.24.
- **HE Uranium Fuel** — Naval reactor fuel element (representative); HEU-Zr alloy fuel meat in Zircaloy cladding with SS structural grid; ref. estimated A4W/S6G-type plate fuel geometry. U 25 (isotopic: 93% U-235, 7% U-238), Zr 54, Fe 13.5, Cr 3.5, Ni 2, Sn 0.8, other (Mo, Mn, Si) 1.2.
- **Thorium Fuel** — Mixed-oxide fuel assembly (speculative); (Th,²³³U)O₂ pellets with ~3.5% ²³³U seed in Zircaloy-4 cladding; ref. Indian AHWR-type fuel bundle (80/17.5/2.5 fuel/Zircaloy/SS by mass). Th 67.8, Zr 17.2, O 9.8, U 2.5 (isotopic: 100% U-233), Fe 1.7, Cr 0.45, Sn 0.26, Ni 0.25, other 0.04.
- **Deuterium** — ²H₂ (D₂). Separable from hydrogen or water in refining processes. H 100.
- **Helium-3** — ³He extracted as a trace component of He from natural gas (Earth), solar-wind-implanted regolith (Moon, asteroids), or gas giant atmospheres. ³He/⁴He by number: protosolar, ~1.66 × 10⁻⁴; lunar regolith (solar wind), ~4.6 × 10⁻⁴; Earth atmospheric, 1.384 × 10⁻⁶; Earth crustal, ~0.01–0.1 of Earth atmospheric. He 100. Extractable. (Simulation note: Helium-3 is extractable, unlike Deuterium, because it has a much higher fractional variation relative to its bulk isotope.)
- **Spent Uranium Fuel** — Irradiated LWR and naval reactor fuel assemblies after discharge; ref. PWR spent fuel at ~50 GWd/tHM burnup, cooled ≥5 years, in original Zircaloy cladding. Approximately 96% of initial uranium remains and is recoverable via reprocessing. U 65.9 (isotopic: ~0.8% U-235, ~0.5% U-236, ~98.7% U-238), Zr 17.2, O 9.5, FP 3.6, Fe 1.6, Pu 0.85, Cr 0.45, Sn 0.26, Ni 0.25, minor actinides (Np, Am, Cm) 0.15, other 0.24.
- **Spent Thorium Fuel** — Irradiated thorium-cycle fuel assemblies after discharge; ref. AHWR-type fuel at ~40 GWd/tHM burnup, in original Zircaloy cladding. Contains bred ²³³U recoverable via reprocessing; ²³²U trace contamination drives hard-gamma dose requiring remote handling. Th 65.5, Zr 17.2, O 9.8, FP 2.5, U 2.2 (primarily ²³³U), Fe 1.7, Cr 0.45, Sn 0.26, Ni 0.25, Pa 0.1, other 0.04.


## Ores

*Ores and other solid extractable resources.*

- **Iron-Nickel** — Native Fe-Ni metal; ref. M-type asteroid alloy (Psyche-class). Fe 91, Ni 8, Co 0.5, P 0.2, S 0.15, C 0.1, Cr 0.05. Byproducts (ppm): Ge 150, Cu 150, Ga 20, Pt 15, Ru 5, Pd 3, Os 3, Ir 2, Au 1.5, Rh 1.5, W 1.5. Extractable.
- **Iron Ores** — Fe oxide/hydroxide; ref. blend of Earth magnetite-hematite concentrate and lunar ilmenite + Martian hematite. Grade: 55% Fe. Fe 55, O 29, Ti 7, Si 2.5, Mg 1.1, Al 1.1, S 0.6, Ca 0.6, Mn 0.5, Cr 0.2, Cl 0.15, P 0.05, other 2.2. Byproducts (ppm): V 300, Zr 100, Ni 50, Co 20, Sc 15, Hf 2. Extractable.
- **Aluminium Ores** — Ref. blend of Earth beneficiated bauxite and lunar highland anorthosite concentrate. Grade: 41.6% Al₂O₃ (22% Al). Al 22, O 50.5, Si 11.5, Ca 6.5, Fe 5.5, H 1.5, Ti 1, Mg 1, Na 0.2, other 0.3. Byproducts (ppm): Sr 100 (off-Earth fraction), Ga 30 (Earth fraction), Eu 8 (off-Earth fraction). Extractable.
- **Industrial Metal Ores** — Ref. blend of Earth production-weighted Cu-Mn-Cr-Zn-Ni-Li sulfide-oxide-silicate concentrates (Li pegmatite fraction forward-weighted for projected demand growth; Li from brines enters via water/brine processing) and asteroidal chromite-sulfide + Martian Mn-oxide + lunar chromite-spinel. Grade: 27.2% combined payable base metals (Cu 4.1, Mn 8.9, Cr 8.5, Zn 3.4, Ni 1.8, Co 0.3, Li 0.2). Fe 17.5, O 19.8, S 12.2, Mn 8.9, Cr 8.5, Si 5.8, Cu 4.1, Al 4.1, Mg 3.8, Zn 3.4, Ti 2.4, Ni 1.8, Ca 1.15, Co 0.3, Ba 0.25, Li 0.2, Pb 0.2, other 5.6. Byproducts (ppm): V 350, Mo 75, Sn 60, Rb 30, W 30, Ag 25, Se 18, Ta 9, Cd 9, Nb 6, In 6, Cs 6, Ge 3, Bi 3, Be 2.5, Te 2, Re 1.2, Au 1, Pt 1, Pd 0.7, Ru 0.3, Rh 0.2, Ir 0.1, Os 0.1. Extractable.
- **Precious Metal Ores** — Rare outside of Earth's crust; ref. production-weighted blend of gold sulfide concentrate (78%), PGM chromite-sulfide concentrate (16%), and primary silver sulfide concentrate (6%). Grade: 65 g/t Au, 760 g/t Ag, 47 g/t total PGM. Fe 36, S 30, O 12, Si 5, Cr 3, As 2.3, Pb 2, Cu 1.4, Mg 1, Al 1, Zn 0.6, Ni 0.3, Sb 0.2, other 5.2. Precious metal content (ppm): Ag 760, Au 65, Pt 18, Pd 15, Rh 5, Ru 5, Ir 2, Os 2. Byproducts (ppm): Se 150, Co 100, Te 20, Bi 10. Extractable.
- **Rare Earth Ores** — Ref. blend of Earth bastnäsite-monazite flotation concentrate and lunar KREEP merrillite-apatite mineral separate. Grade: 33.3% TREO (28.5% total REE). Total REE 28.5 (Ce 12.5, La 7, Nd 3.8, Pr 1.5, Y 1.25, Sm 0.55, Yb 0.50, Gd 0.4, Dy 0.25, Tb 0.20, Ho 0.18, Er 0.17, Tm 0.08, Lu 0.07, Eu 0.05), O 31.5, Ca 15, P 9, F 3.9, C 2.5, Si 2, Fe 1.25, Mg 1.25, Al 0.75, Ba 0.5, Na 0.5, Th 0.35, K 0.1, other 2.9. Byproducts (ppm): Nb 500, U 175, Zr 150, Sc 25, Ta 13. Extractable.
- **Uranium Ores** — Rare outside of Earth's crust; ref. gravity-flotation pre-concentrate from unconformity-type and IOCG deposits, beneficiated but not yet leached. Grade: 7.1% U₃O₈ (6% U). U 6, O 38, Si 20, Fe 17, S 3.5, Al 3, Ca 3, Mg 2, K 0.5, Ti 0.5, Na 0.5, V 0.3, Cu 0.3, H 0.3, C 0.3, Th 0.2, Pb 0.2, Ni 0.1, total REE 0.1 (Ce 0.044, La 0.025, Nd 0.013, Y 0.005, Pr 0.005, Sm 0.002, Gd 0.001, Dy 0.001, Eu 0.001, Er 0.001, Yb 0.001, Tb 0.001), other 4.2. Co-product elements at percent scale (in main composition): V 0.3, Cu 0.3, Th 0.2, total REE 0.1. Byproducts (ppm): Mo 100, Se 20, Sc 20, Ra 10, Au <1 (some deposits). Extractable.
- **Sulfur** — Ref. blend of Earth recovered elemental sulfur (from hydrocarbon desulfurization) and elemental sulfur from asteroidal troilite thermal decomposition + Martian anhydrite concentrate. S 91, O 4.7, Ca 2.5, Fe 0.55, Si 0.4, Mg 0.15, C 0.08, H 0.03, other 0.59. Byproducts (ppm): Se 200 (primarily from off-Earth troilite), Te 25. Extractable.
- **Organics/Tholins** — Ref. blend of Earth kerogen concentrate (Type I/II, demineralized from oil shale and organic-rich marine mudstone; excludes coal, petroleum, gas, and biomass) and off-Earth carbonaceous chondrite insoluble organic matter (IOM), Titan tholins, and cometary CHON particles. C 73.4, H 7.4, N 4.5, O 10.5, S 3.6, other 0.6. Byproducts (ppm): V 150 (Earth kerogen porphyrins), Ni 50 (Earth kerogen porphyrins), Mo 15 (Earth kerogen, chelated in organic matrix). Extractable.
- **Industrial Minerals** — Ref. blend of Earth production-weighted construction, agricultural, and chemical minerals and off-Earth devolatilized regolith-phosphate-salt (water, nitrogen compounds, and organics removed and tracked separately). O 44.5, Si 18, Ca 13.5, Fe 5.2, Al 4.2, Mg 2.8, P 2.1, Na 2.1, Cl 2.1, C 2, K 0.95, S 0.5, Ti 0.5, total REE 0.35 (Ce 0.154, La 0.086, Nd 0.047, Pr 0.018, Y 0.015, Sm 0.007, Gd 0.005, Yb 0.006, Dy 0.003, Tb 0.002, Ho 0.002, Er 0.002, Eu 0.001, Lu 0.001, Tm 0.001), F 0.2, H 0.05, Mn 0.05, other 0.9. Note: total REE 0.35 in main composition is primarily from off-Earth KREEP fraction and may be a co-product. Byproducts (ppm): B 500 (Earth borate/evaporite fraction), Th 400 (off-Earth KREEP fraction), Br 100 (Earth evaporite/brine fraction). He-3 at ppb level in lunar regolith fraction (potential fusion fuel). Extractable.
- **Stone** — Bulk silicate rock, natural or as dimension stone; ref. primitive mantle pyrolite. O 44, Mg 23, Si 21, Fe 6, Ca 2.5, Al 2.3, Na 0.3, Cr 0.3, Ni 0.2, other (Ti, Mn, K, P) 0.4. Extractable.
- **Regolith** — Surface fines and debris (includes overburden and gangue from mining operations); ref. generic basalt (Moon/Mars/MORB average). O 44, Si 22, Fe 11, Ca 7, Al 7, Mg 5, Na 1.5, Ti 1.5, other (K, Mn, Cr, P) 1. Extractable.


## Volatiles

*Extractable, purified, and/or synthesized volatiles.*

- **Water** — H₂O. H 11.2, O 88.8. Extractable.
- **Oxygen** — O₂. O 100. Extractable.
- **Nitrogen** — N₂. N 100. Extractable.
- **Carbon Dioxide** — CO₂. C 27.3, O 72.7. Extractable.
- **Carbon Monoxide** — CO. C 42.9, O 57.1. Extractable.
- **Ammonia** — NH₃. N 82.2, H 17.8. Extractable.
- **Ethane** — C₂H₆. C 79.9, H 20.1. Extractable.
- **Sulfur Dioxide** — SO₂. S 50.1, O 49.9. Extractable.
- **Helium** — He (considered as the ⁴He fraction). He 100. Extractable.
- **Argon** — Ar. Ar 100. Extractable.
- **Heavy Noble Gases** — Kr, Xe, and Ne as co-product. Ref. Earth atmospheric mass ratio. Ne 77, Kr 20, Xe 3. Extractable.
- **Industrial Chemicals** — Commodity chemicals: acids, bases, oxidizers, solvents, industrial gases (Cl₂, HF, etc.); ref. production-weighted blend of H₂SO₄, NaOH, Cl₂, Na₂CO₃, methanol, HNO₃, HCl, H₃PO₄, and other commodity intermediates. O 45, C 18, Cl 10, S 9.5, Na 8, H 5, N 2, P 1.7, other (F, Fe, Ca, K, B) 0.8.
- **Fine Chemicals** — Specialty chemicals, catalysts, coatings, adhesives, electronic-grade reagents; ref. production-weighted blend of specialty coatings, agrochemicals, surfactants, catalysts, adhesives, and electronic chemicals. C 40, O 22, H 6, Ti 5, N 3, Cl 3, Si 3, S 3, F 2, Na 2, Al 1, P 1, Fe 1, other (Co, Pt, Pd, Rh, Zr, B, Ce) 8.


## Materials

*Solid refined materials, industrial feedstocks, and waste products.*

- **Iron** — Industrial pig iron; ref. blast-furnace pig iron, global production-weighted. Fe 93.5, C 4, Si 1, Mn 0.7, P 0.15, S 0.05, other (Cr, Ti, V, Cu) 0.6.
- **Steel** — Carbon steel, alloy steel, stainless steel; ref. production-weighted global blend (~85% carbon, ~10% alloy, ~5% stainless). Fe 96.5, Cr 1, Mn 0.8, Ni 0.5, Si 0.3, C 0.3, Mo 0.1, other (V, W, Cu, N, S, P) 0.5.
- **Aluminium** — Refined Al metal and alloys; ref. production-weighted blend of wrought (1xxx, 3xxx, 5xxx, 6xxx, 7xxx) and cast alloys. Al 97, Si 1, Cu 0.5, Mg 0.4, Fe 0.4, other (Mn, Zn, Cr, Ti, Ni) 0.7.
- **Industrial Metals** — Cu, Ti, Zn, Ni, Sn, Pb, W, Mo, Co, Mn, Cr, etc.; also includes Ag. Ref. production-weighted basket of refined industrial metals (metal content basis). Cu 29, Mn 23, Zn 16, Cr 13.5, Pb 13.5, Ni 3.75, Sn 0.4, Mo 0.35, Ti 0.3, Co 0.24, W 0.1, Ag 0.03, other 0.03. (Simulation note: Ag is treated as an industrial rather than precious metal to be less distortional on commodity pricing.)
- **Precious Metals** — Au, Pt, Pd, Rh, Ru, Ir, Os (excludes Ag). Ref. production-weighted basket of refined precious metals. Au 87.5, Pd 5.5, Pt 5, Ru 0.9, Rh 0.8, Ir 0.2, Os 0.03, other 0.07.
- **Rare Earths** — REE oxides, metals, alloys, permanent-magnet stock; ref. production-weighted blend of separated REE oxides (~50%), NdFeB magnet stock (~30%), RE metals/alloys (~10%), and other RE compounds (~10%). Total REE 67 (Ce 18, Nd 16, La 12, Pr 6, Y 5, Dy 2.5, Sm 2, Tb 1, Gd 1, other REE 3.5), Fe 18, O 8.5, B 0.3, Co 0.6, other (Cu, Al, Ni, Mg, F, Cl, Si) 5.6.
- **Uranium** — Purified, unenriched uranium hexafluoride (UF₆) at natural isotopic assay (0.711% ²³⁵U); ref. conversion-plant product meeting ASTM C787 specification. U 67.6 (isotopic: 0.711% U-235, 99.289% U-238), F 32.4.
- **Depleted Uranium** — Depleted uranium hexafluoride (UF₆) tails from isotope enrichment, containing ~0.25% ²³⁵U (balance ²³⁸U). U 67.6 (isotopic: ~0.25% U-235, ~99.75% U-238), F 32.4. Primary by-product of LEU and HEU fuel manufacturing. Uses include re-enrichment feedstock, fast-breeder reactor blanket material, radiation shielding, and high-density counterweights.
- **Thorium** — Nuclear-grade thorium dioxide (ThO₂) powder; ref. purified thoria separated from monazite-process residues, meeting nuclear-purity specifications. Th 87.9, O 12.1.
- **Carbon** — Solid carbon: metallurgical coke, carbon black, biochar, graphite, activated carbon, and pyrolysis carbon; ref. forward-weighted blend of metallurgical coke (~50%), carbon black (~20%), and pyrolysis/graphite/activated carbon (~30%). C 95, S 0.6, O 1, Si 0.7, H 0.4, Fe 0.4, Al 0.4, Ca 0.3, N 0.3, Mg 0.15, other (K, Na, Ti, Mn, P) 0.75.
- **Concrete** — Portland cement, geopolymer, sintered-regolith binder; ref. ready-mix concrete with blended siliceous/calcareous aggregate. O 49.5, Si 20, Ca 17, C 3, Al 2, Fe 1.5, Mg 1.5, H 1, Na 0.5, K 0.5, S 0.3, other (Ti, Mn, Cl) 2.7.
- **Glass/Ceramics** — Flat glass, fiber glass, refractory and technical ceramics; ref. production-weighted blend dominated by soda-lime glass (~80%). O 46, Si 33, Na 8, Ca 6, Al 3, Mg 2, B 0.5, K 0.3, Fe 0.3, other (Ba, Ti, Zr, Pb, F) 0.9.
- **Semiconductor Materials** — High-purity Si, GaAs, SiC, compound semiconductors; ref. production-weighted blend dominated by electronic/solar-grade silicon (~95% by mass). Si 96, As 1.6, Ga 1.4, C 0.5, other (In, P, N, Ge, O) 0.5.
- **Polymers** — Thermoplastics, thermosets, elastomers, synthetic fibers; ref. production-weighted blend (PE ~30%, PP ~20%, PVC ~15%, PET ~8%, PS ~7%, PUR ~7%, other ~13%). C 73, H 10, Cl 8.5, O 5.5, N 1.2, S 0.5, F 0.5, other 0.8.
- **Composites** — CFRP, GFRP, metal-matrix composites, aramid laminates; ref. production-weighted blend (GFRP ~70%, CFRP ~20%, aramid ~5%, MMC ~5%). C 39, O 31, Si 11, Ca 6.5, Al 4, H 2.5, N 1.5, Mg 1.5, B 0.7, Fe 0.3, other (Cr, F, Ti) 2.
- **Technical Textiles** — High-performance fabrics; aramid, UHMWPE, carbon fiber cloth, PTFE membranes, glass fiber textiles, multilayer insulation, filtration media, spacesuit materials; ref. production-weighted blend. C 65, O 21, H 7, N 3, F 1.5, Si 1, other (Ca, Al, B, Mg, Fe, Na, S, Cl) 1.5.
- **Municipal Waste** — Post-consumer mixed solid waste from households, commercial establishments, and service sectors: discarded packaging, waste paper and cardboard, worn textiles, broken housewares, spent small consumer items, food-contaminated non-recyclable materials, and miscellaneous refuse. Distinct from Industrial Waste (manufacturing and process origin) and Biowaste (biological and organic origin). Ref. production-weighted blend of developed-nation MSW composition after food-waste diversion (~30% paper/cardboard, ~20% plastics, ~7% glass, ~7% ferrous metals, ~7% textiles, ~6% wood, ~3% non-ferrous metals, ~3% rubber/leather, ~17% other composites, ceramics, and miscellaneous). C 39, O 29, H 6, Fe 6.5, Si 4, Al 3, Cl 2, Ca 1.5, Na 1, N 0.5, Cu 0.3, other (Mg, Zn, Cr, Mn, S, K, Ti, Sn, Ni, Pb) 7.2.
- **Industrial Waste** — Scrap metal, slag, fly ash, spent catalysts, recyclable mixed waste; ref. production-weighted blend (~40% fly ash, ~30% slag, ~20% scrap metal, ~10% other). O 32, Fe 20.5, Si 15.5, Ca 10, Al 7.5, Mg 2, C 1, Cu 0.7, other (Na, K, Ti, Mn, S, Cl, Zn, Cr) 10.8.
- **Radioactive Waste** — Vitrified high-level waste from fuel reprocessing, cemented intermediate-level waste (activated structural materials, process residues, decommissioning waste), and conditioned operational waste; excludes intact spent fuel assemblies (tracked separately as Spent Uranium Fuel and Spent Thorium Fuel). Ref. blend of cemented ILW (~80%) and vitrified HLW (~20%). O 41, Si 13, Fe 12.5, Ca 11.5, Al 3.7, C 2.4, Na 2.2, Mg 1.6, B 0.9, H 0.8, K 0.4, actinides/FP 3.5, other (Li, S, Ti, Mn, Zr) 6.5.


## Manufactured

*Fabricated end products or inputs to further assembly, construction, or operations.*

- **Infrastructure** — Fixed structures and installations: buildings, roads, bridges, tunnels, landing pads, launch complexes, power distribution networks, pipelines, pressurized habitats, radiation shielding, and life-support systems; ref. sector-averaged blend of civil and industrial infrastructure (~65% concrete/masonry/aggregate, ~20% structural steel, ~4% aluminium, ~3% polymers/organics, ~2% glass, ~2% copper/electrical, ~4% other). O 34, Fe 20, Si 14, Ca 11, C 5, Al 4, Cu 2, H 1, Mg 1, Na 0.5, K 0.3, Cr 0.3, Mn 0.2, Ni 0.15, Cl 0.2, S 0.2, other (Zn, Ti, N, Mo, W, Sn, P) 6.15. (Special handling in the simulation; not a commodity resource.)
- **Heavy Rockets/Transports** — Heavy-lift launch vehicles and large interplanetary transports; ref. production-weighted blend of reusable heavy-lift rockets (~50%) and large interplanetary vehicle structures (~50%), including primary structure, tankage, main propulsion, power systems, avionics, thermal protection, and life-support outfitting. Fe 32, Al 20, C 8, Cu 5, O 5, Cr 4, Ni 3.5, Si 3, Ti 2.5, H 2, N 1.5, Co 0.5, Mn 0.5, Mg 0.5, Sn 0.4, Mo 0.3, other (W, Zn, Cl, Na, Ca, Ta, Nb, B, S, P, F) 10.8. (Special handling in the simulation; not a commodity resource.)
- **Transport Systems** — Ground, rail, marine, air, and space vehicles and systems; includes propulsion assemblies, EVA systems, and spacesuits; excludes Heavy Rockets/Transports (handled individually). ref. production-weighted blend (~80% ground vehicles, ~10% aircraft, ~10% marine/rail). Fe 53, Al 11, C 9, O 4, Si 2.5, Cu 2, Cr 2, H 2, Cl 1.5, Ni 1, Zn 0.8, Ti 0.8, Mn 0.5, Mg 0.4, other (Sn, Mo, Na, Ca, N, S, P, W, V) 9.5.
- **Robotics** — Robotic manipulators, autonomous systems, AI-hardware platforms; ref. sector-averaged blend of industrial arms, autonomous vehicles, and compute hardware. Fe 25, Al 15, Cu 10, C 10, O 8, Si 7, Cr 3, Ni 2, H 2, N 1.5, Sn 1.5, Ti 1, Mg 1, other (Zn, Mo, W, Ag, Au, Co, Mn, Ba, F, Cl, Na) 13.
- **Batteries** — Batteries, fuel cells, supercapacitors, other energy storage; ref. production-weighted blend of Li-ion cells (NMC ~45%, LFP ~45%, NCA/other ~10%) including cell casing and electrode assemblies. C 25, O 16, Al 10, Cu 9, Fe 8, Ni 6, P 4, F 3, Li 2, Co 2, Mn 2, H 1.5, other (Sn, Si, Ti, Zr, Na) 11.5.
- **Solar Panels** — Photovoltaic modules; ref. crystalline silicon module (~95 % c-Si market share) with tempered glass front, aluminium frame, EVA encapsulant, polymer backsheet, and copper interconnects. O 36, Si 26, Al 10, C 8, Na 7, Ca 5, Cu 3, H 1, Mg 1, other (Ag, Sn, Fe, F, N, B, Cl, Pb) 3.
- **Steel Structures** — Beams, plates, pressure vessels, pipe, prefab modules; ref. fabricated structural steel with galvanized and coated fractions. Fe 95, Cr 1, Mn 0.8, C 0.5, Ni 0.5, Zn 0.5, Si 0.3, other (Mo, V, Cu, W, N, S, P) 1.4.
- **Aluminium Structures** — Sheet, extrusions, pressure shells, lightweight frames; ref. fabricated wrought aluminium assemblies with fasteners and sealants. Al 93, Si 1.5, Cu 1, Mg 1, Fe 0.5, Zn 0.3, Cr 0.3, Ti 0.2, Mn 0.2, other (Ni, polymer sealants) 2.
- **Composite Structures** — CFRP/GFRP panels, overwrapped tanks, fairings, inflatable habitats; ref. high-performance composite assemblies (more CFRP-weighted than base composites). C 50, O 22, Si 5, Al 4, Fe 3, H 3, N 3, Ca 2, Ti 1.5, Mg 1, Cr 1, B 0.5, other (Zn, Cu, Sn, Ni, S, F, Cl) 4.
- **Heavy Machinery** — Turbines, engines, pumps, compressors, heat exchangers, mining/construction equipment, cranes, pressure vessels, industrial furnaces; ref. sector-averaged bill of materials. Fe 80, Al 2, Cu 3, Cr 2, C 2, O 2, Ni 1, Mn 1, Si 1, H 0.5, Zn 0.5, other (Mo, W, Ti, Co, Sn, V, N, S, P, Cl, Ca) 5.
- **Electrical Equipment** — Generators, transformers, electric motors, power cables, switchgear, power distribution panels, lighting, power electronics, fuel cells; ref. sector-averaged bill of materials. Fe 45, Cu 24, Al 6, C 6, O 3.5, Cl 2, Cr 1.5, Si 1.5, H 1, Ni 1, Mn 0.5, Zn 0.5, Sn 0.5, other (Mo, N, S, P, Na, Mg, Ca, Ba, Ti, W) 7.
- **Precision Equipment** — Scientific instruments, medical devices, CNC machines, lithography systems, optical systems, laboratory equipment, navigation/guidance systems; ref. sector-averaged bill of materials. Fe 23, Al 20, C 16, O 9, Cu 8, Cr 5, Si 4, Ni 3, H 2, Ti 1.5, N 1, Cl 1, other (Co, W, Na, Ca, Mn, Sn, Mg, Mo, Zn, B, Ba, S, P, F, Au, Ag) 6.5.
- **Electronics** — General-use semiconductors including "scalar" processors (CPUs, microcontrollers, etc.), computing hardware, communication equipment, displays, sensors, circuit boards; ref. production-weighted blend of consumer and industrial electronics. O 20, Cu 15, C 14, Si 12, Fe 7, Al 7, Sn 3, H 3, N 2, Na 2, Ca 2, Ni 1.5, Ba 1, Cl 1, other (Ag, Au, Mg, Cr, Zn, Ti, In, Ga, Ta, F, S, P, K, Mn, W, Pb) 9.5.
- **Tensor Processors** — Premium-tier semiconductors for accelerated computing and early AI (GPUs, TPUs, etc.); ref. logic + HBM die on advanced-packaging substrate (CoWoS-type) with heat spreader, underfill, and organic interposer; ref. estimated GPU-class accelerator module bill of materials. Cu 25, C 16, O 14, Si 12, Fe 8, Sn 4, Ni 3, Al 2.5, H 2, N 1.5, other (Ag, Au, Ba, Ca, Na, Cr, Ti, W, Ta, F, Cl, In) 12.
- **Neuromorphic Processors** — Programmable neuromorphic processor units (PNPUs) for ultra-efficient, advanced AI (fictional); ref. same as Tensor Processors. Cu 25, C 16, O 14, Si 12, Fe 8, Sn 4, Ni 3, Al 2.5, H 2, N 1.5, other (Ag, Au, Ba, Ca, Na, Cr, Ti, W, Ta, F, Cl, In) 12.
- **Consumer Goods** — Mass-produced everyday goods; furniture, clothing, housewares, paper products, personal care products, building finishes; ref. production-weighted blend. C 44, O 23, Fe 10, H 6, Si 3, Cl 3, Al 1.5, Na 1, Ca 1, Cu 1, N 0.5, Zn 0.5, other (Cr, Ni, Mn, Mg, Ti, S, P, K, Sn) 5.5.
- **Specialty Goods** — High-value, low-mass luxury and specialty items; premium personal electronics, jewelry, art, premium fashion, recreational equipment; ref. estimated blend. C 30, O 18, Fe 10, Al 7, Cu 6, Si 6, H 4, Cr 2, Ni 2, N 1.5, Na 1.5, Cl 1, Ca 1, Zn 1, other (Sn, Ag, Au, Ti, Mo, Mg, S, P, F, Co, Mn, K, Pt, Pd) 9.


## Biological

*Products of, or primary inputs to, agriculture, aquaculture, forestry, and other biological processes.*

- **Crop Products** — Wholesale and retail plant-based food products; ref. production-weighted blend of cereals, fruits and vegetables, oilseeds, sugar crops, and pulses, including retail-ready fresh and processed produce, at typical trading or retail moisture; ~2% light packaging (polymer film, bags) by mass. C 39, O 46, H 7, N 1.5, K 0.9, other (Si, P, S, Ca, Mg, Cl, Na, Fe, Mn) 5.6.
- **Animal Products** — Wholesale and retail animal-based food products; ref. production-weighted blend of milk (~60% by mass), meat/carcass (~25%), eggs (~6%), retail-ready dairy and delicatessen (~5%), and other (hides, tallow) (~4%); ~2% light packaging (polymer film, vacuum bags) by mass. C 14, O 67, H 10.5, N 1.5, other (Ca, K, Na, P, S, Cl, Mg, Fe, Zn) 7.
- **Packaged Meals** — Ready-to-eat and easily prepared meals with primary packaging; includes retort-pouch entrees, freeze-dried meals, thermostabilized pouches, frozen entrees, instant meals, and shelf-stable ration packs; ref. production-weighted blend (~40% thermostabilized/retort pouch, ~30% frozen entrees, ~15% freeze-dried/dehydrated, ~15% instant/shelf-stable/bars); ~88% food content, ~12% packaging by mass; packaging ref. flexible polymer–aluminium-foil laminate pouches and polymer film bags (minimal cans, glass, or cardboard). O 59, C 26, H 9, Al 2, N 2, Na 0.4, Cl 0.4, K 0.2, other (S, Ca, P, Fe, Mg, Sn, Si) 1.
- **Artisanal Foods** — Handcraft and family-farm food products; artisan cheeses, charcuterie, preserves, craft beverages, baked goods; ref. estimated blend. O 60, C 22, H 8, N 2, other (Na, K, Ca, P, S, Cl, Mg, Fe) 8.
- **Artisanal Goods** — Handcraft non-food items; pottery, handmade textiles, woodcraft, leatherwork, artisanal soap, candles; ref. estimated blend. C 30, O 35, Si 8, H 5, Fe 4, Ca 4, Al 2, Na 1.5, N 1, other (K, Mg, S, Cl, Ti) 9.5.
- **Biofibers** — Cotton, hemp, jute, wool, silk, etc.; ref. production-weighted blend dominated by cotton (~75%). C 44, O 47, H 6, N 1, S 0.2, other (K, Ca, Mg, Na, Si, Fe, P) 1.8.
- **Lumber/Wood Products** — Sawn timber, engineered wood products, wood pulp, paper; ref. production-weighted blend of sawn timber, engineered wood, and pulp/paper at typical trading moisture. C 44, O 44, H 6, other (N, Ca, K, Mg, Na, Si, S) 6.
- **Algal/Microbial Products** — Ref. production-weighted blend of microalgal biomass (Spirulina, Chlorella), bacterial fermentation products (amino acids, organic acids), and yeast extracts; dried/concentrated. C 48, O 28, N 8, H 7, S 1, P 1, other (K, Ca, Mg, Na, Fe) 7.
- **Biofeedstock** — Raw plant/microbial mass used as industrial feedstock; ref. woody and herbaceous biomass, air-dried. C 47, O 42, H 6, other (N, K, Ca, Si, Mg, Na, Fe, S, P, Cl) 5.
- **Biochemicals** — Industrial enzymes, amino acids, biopolymers, fermentation products (excluding ethanol and methanol); ref. production-weighted blend of PLA/PHB biopolymers, citric/lactic acid, amino acids, and industrial enzymes. C 42, O 30, N 8, H 6.5, Na 2, S 1.5, P 1.5, K 1, Cl 1, Ca 0.5, other (Mg, Fe, Zn, Cu) 6.
- **Pharmaceuticals** — Drugs, vaccines, biologics, medical compounds; ref. production-weighted blend including active ingredients, excipients (cellulose, lactose, starch), and primary packaging (glass, plastic, foil). C 30, O 50, H 6, Si 2, N 1, Na 1, Al 1, Ca 0.5, Fe 0.5, Cl 0.5, other (K, Mg, S, P, Ti, F) 7.5.
- **Fertilizers** — NPK compounds, micronutrient mixes, soil amendments; ref. production-weighted blend of urea (~35%), DAP/MAP (~15%), potash KCl (~15%), ammonium nitrate (~15%), superphosphates (~5%), and other amendments (~15%). O 33, N 25.5, K 8, Cl 7, C 7, P 5.5, H 4.5, Ca 2, S 1, other (Mg, Na, Fe, Mn, Zn, B, Cu) 6.5.
- **Soil/Growth Media** — Terrestrial soil, compost, hydroponic substrates, amended regolith; ref. enriched loamy topsoil with organic matter and amendments. O 47.5, Si 21.5, Al 6, C 6, Fe 3.5, Ca 3, H 2.5, Mg 2, K 2, Na 0.8, Ti 0.7, N 0.4, other (Mn, P, S, Cl) 4.1.
- **Biowaste** — Organic waste, sewage sludge, food waste, human and animal metabolic waste, and crop residue; ref. blend of municipal organic waste, agricultural residue, and sewage sludge. O 48, C 30, H 7, Si 2.5, N 1.5, Ca 1.5, K 1, Fe 1, Al 0.8, P 0.5, S 0.5, Na 0.3, Mg 0.3, Cl 0.2, other (Mn, Ti, Zn) 4.4.
- **Wild Fisheries** — Earth only; ref. production-weighted global marine and freshwater catch (whole organism, live weight). O 72, C 13, H 10.5, N 2.5, Ca 0.4, P 0.3, K 0.3, S 0.3, Na 0.2, Cl 0.15, Mg 0.03, Fe 0.01, other 0.31. Extractable. (Special handling in the simulation; converted at harvest, not a commodity resource.)
- **Timber** — Earth only; ref. production-weighted global industrial roundwood (standing green wood, ~50% moisture). O 65.5, C 24.5, H 8.5, Ca 0.3, K 0.25, N 0.05, Mg 0.05, S 0.02, P 0.02, other 0.81. Extractable. (Special handling in the simulation; converted at harvest, not a commodity resource.)


## Services

*Intangibles.*

- **Scalar Compute** — 
- **Tensor Compute** — 
- **Neuromorphic Compute** — 
- **Research & Development** — 
- **Transport Services** — 
- **Wholesale/Logistics** — 
- **Maintenance** — 
- **Retail Services** — 
- **Entertainment** — 
- **Hospitality** — 
- **Healthcare** — 
- **Education** — 
- **Consulting** — 
- **Marketing/Advertising** — 
- **Financial Services** — 
- **Real Estate Services** — 
- **Accounting Services** — 
- **Legal Services** — 

