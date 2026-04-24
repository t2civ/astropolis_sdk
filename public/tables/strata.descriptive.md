# Strata

Strata correspond to different geological layers, physical features, and/or territorial or economic interest regions. In the simulation, they are present or potential extraction targets with distinct resource compositions.

## Notes

1. The simulation handles all non-generic strata as exclusive masses, each with its own composition.
2. Depths here are reference only. Strata volumes should be constructed as simplified spheres, sphere shells, or fractional sphere shells, using area-weighted radial boundaries when actual thickness varies (e.g., Earth's ocean). Calculated inner and outer radii won't exactly line up for adjacent strata using these simplified geometries, but this doesn't matter in the simulation. (Ring systems are handled separately.)
3. Some strata are "best guesses". This should be noted here but uncertainty is handled elsewhere in the model.
4. Earth "continental surface" and "continental shelf" encompass land area (including glacier and surface water body footprints) and shelf area, respectively. Continental strata below these (near-surface, subsurface, deep subsurface, etc.) encompass both land and shelf area (these should capture all offshore drilling operations). "Ocean" as a volume includes water over the continental shelf. Therefore, in area construction: total surface ≈ continental surface + continental shelf + ocean floor ≈ continental near-surface (or deeper "continental") + ocean crust; ocean = continental shelf + ocean floor; ocean ≠ ocean floor.
5. Earth continental strata are further subdivided into 7 "territorial" regions (corresponding to national polities in `players.tsv`) and 1 "commons" region (Antarctica). All continental surface and shelf (and continental crust layers below) is assigned into one of these 8 exclusive regions. Atmosphere, ocean (as a whole), ocean floor, ocean crust, mantle, and core are commons.
6. Generic strata are compositional templates only. Each body in the simulation has a unique composition.
7. Each stratum has a simplified composition defined by mean abundance and dispersion (each having uncertainty error terms) for each simulation resource. Large dispersion is the principal factor enabling economical extraction in mining/drilling operations.


---

## Mercury

*Mean radius 2,440 km. Surface gravity 3.7 m/s² (0.38 g). Tenuous exosphere only. Extreme thermal environment: ~430 °C dayside, ~−180 °C nightside. Solar flux ~6–10× Earth's. Enormous iron core.*

- **Polar Shaded Regolith** — Permanently shadowed craters near both poles, 0–10 m. H₂O ice and organics at ≲100 K. Strategic inner solar system volatile source.
- **Regolith** — 0–10 m. Silicate with elevated S and Mg. Extreme thermal cycling.
- **Near-Surface** — 10 m to ~1 km. Fractured bedrock (lunar megaregolith analog).
- **Crust** — ~1–35 km. Volcanic silicate plains and intercrater terrain.
- **Mantle** — ~35–420 km. Thin silicate mantle (~385 km thick).
- **Core** — ~420–2,440 km. Iron-rich, radius ~2,020 km (~83% of planet radius). Partially liquid outer, solid inner (~1,000 km radius). Largest proportional core of any terrestrial body. Speculative planet harvest.

## Venus

*Mean radius 6,052 km. Surface gravity 8.87 m/s² (0.90 g). Dense CO₂ atmosphere, ~9.2 MPa (~92 bar) mean surface pressure. Mean surface temperature ~465 °C. Sulfuric acid cloud deck at ~45–70 km altitude. No current surface exploration capability beyond short-lived landers. Key challenges: extreme temperature and pressure, corrosive atmosphere, slow rotation (243-day sidereal period, retrograde).*

- **Atmosphere** — Atmosphere defined as 250 km thick (~99.99% of mass). ~96.5% CO₂, ~3.5% N₂, traces SO₂, H₂O, Ar, CO. Dense H₂SO₄ cloud/haze layers at ~45–70 km altitude. Conditions at ~55 km altitude (~0.5 bar, ~20 °C) are the most accessible zone. Atmospheric mining for CO₂, N₂, SO₂, H₂SO₄.
- **Surface** — 0–100 m. Basaltic volcanic plains, shield volcanoes, highland tessera terrain. Chemically weathered in dense hot atmosphere but no impact-generated regolith layer (thick atmosphere screens impactors). Extreme conditions (~465 °C, ~92 bar).
- **Near-Surface** — 0.1–1 km. Basaltic bedrock. Extreme subsurface temperatures persist.
- **Subsurface** — 1–5 km. Intact basaltic rock.
- **Deep Crust** — 5–~30 km (average crustal thickness poorly constrained, estimated ~10–50 km). Speculative deep extraction.
- **Mantle** — ~30–~2,850 km. Silicate. Possibly vigorously convecting (extensive volcanism observed). Speculative planet harvest.
- **Core** — ~2,850–6,052 km. Iron-nickel, radius ~3,200 km. Possibly liquid but no dynamo observed. Speculative planet harvest.

## Earth

*Mean radius 6,371 km. Surface gravity 9.81 m/s² (1.0 g). N₂–O₂ atmosphere, 101.3 kPa mean surface pressure. Dense hydrosphere. Present-day extraction technology baseline. See notes 4 and 5, which apply to Earth "continental" strata specifically (including continental ice and water bodies).*

- **Atmosphere** — Atmosphere defined as 65 km thick (~99.99% of mass). Air separation for N₂, O₂, Ar, CO₂, noble gases.
- **Continental Ice Bodies** — Major ice sheets and glaciers for Antarctica and Greenland only; simplified geometry is ~12.3 million km² area at 2.14 km thickness (Antarctica) and ~2.24 million km² area at 1.15 km thickness (Greenland as part of "Other" territory). For all other territorial regions, glacier and ice mass is absorbed into Continental Surface.
- **Continental Surface** — All land area including areas covered by glaciers and surface water bodies, to 100 m depth (~152 million km²). Composition includes groundwater, permafrost, surface water bodies (lakes, rivers, reservoirs), and glaciers (for non-Antarctic/Greenland territories). Quarrying, strip mining, placer deposits, regolith extraction, shallow wells, freshwater extraction.
- **Continental Shelf** — Continental shelf seafloor to 100 m depth below seafloor (~25 million km²). Sand & gravel dredging, placer and phosphorite deposits, subsurface mineral deposits.
- **Continental Near-Surface** — 0.1–0.5 km depth (land & shelf; ~174 million km²). Open-pit mining, shallow underground mining, shallow drilling.
- **Continental Subsurface** — 0.5–2.0 km (land & shelf; ~174 million km²). Conventional underground mining, standard drilling.
- **Continental Deep Subsurface** — 2.0–5.0 km (land & shelf; ~174 million km²). Deep mining near current operational limits, routine deep drilling.
- **Continental Extreme Subsurface** — 5.0–12.0 km (land & shelf; ~174 million km²). Frontier drilling technology, speculative mining.
- **Continental Ultra Subsurface** — 12.0–20.0 km (land & shelf; ~174 million km²). Beyond all current extraction capability.
- **Continental Lower Crust** — 20–35 km (land & shelf; ~174 million km²). Speculative planet harvest.
- **Ocean** — Oceans and seas considering the salt water and ocean ice as a whole (including over continental shelf); simplified geometry is ~361 million km² (~70.8% of Earth surface) at 3.69 km thickness. For simplification, treat as homogeneous composition ignoring ocean ice. Desalination, dissolved mineral extraction, salt refining.
- **Ocean Floor** — All ocean depths excluding continental shelf to 100 m below seafloor (~336 million km²). Manganese nodules, polymetallic sulfides, cobalt-rich crusts, REE-bearing muds.
- **Ocean Crust** — 100 m below seafloor to Moho (~7 km sub-ocean). Deep sediment and basaltic crust. Speculative planet harvest.
- **Mantle** — Moho (~7 km sub-ocean, ~35 km sub-continent) to 2,890 km depth. Speculative planet harvest.
- **Core** — 2,890–6,371 km. Iron-nickel. Speculative planet harvest.

## Moon

*Mean radius 1,737 km. Surface gravity 1.62 m/s² (0.17 g). No atmosphere. Key challenges: vacuum, abrasive dust, thermal cycling (±150 °C).*

- **Polar Shaded Regolith** — Permanently shadowed craters near both poles, 0–10 m depth (same as regolith for model simplicity); roughly defined as ~33,000 km² (~0.09%). H₂O ice, CO₂, NH₃, organics cold-trapped at 40–100 K. Key cislunar volatile source. Extraction in permanent darkness.
- **Regolith** — 0–10 m (2–8 m in maria, 5–15 m in terrae); covers area not defined as polar shaded regolith. Impact-generated fines and breccias. O₂ from ilmenite, metals, ³He from solar-wind implantation, sintered construction feedstock.
- **Near-Surface** — ~10 m to ~1 km. Megaregolith: impact-fractured bedrock, more consolidated than regolith, less competent than intact crust.
- **Crust (terrae)** — ~1–60 km (thinner nearside, up to ~80 km farside). Anorthositic. Rich in Al, Ca, Si, O.
- **Crust (maria)** — ~1–25 km. Mixed basaltic-anorthositic composition. Rich in Fe, Ti, Mg, O (ilmenite, pyroxene, olivine). Lava tubes at km-scale widths.
- **Mantle** — ~60–1,400 km. Ultramafic (olivine, pyroxene, garnet). Speculative planet harvest.
- **Core** — ~1,400–1,737 km. Iron-nickel, radius ~330 km, partially molten. Speculative planet harvest.

## Mars

*Mean radius 3,390 km. Surface gravity 3.72 m/s² (0.38 g). Thin CO₂ atmosphere, ~0.6 kPa mean surface pressure. Mean surface temperature ~−60 °C. Key challenges: low pressure, cold, dust storms, perchlorates, communication delay.*

- **Atmosphere** — Atmosphere defined as 100 km thick (~99.99% of mass). ~95% CO₂, ~2.7% N₂, ~1.6% Ar, traces of O₂, CO, H₂O. ISRU feedstock for propellant (Sabatier, RWGS, electrolysis) and industrial gases.
- **North Polar Cap** — H₂O-ice-dominated, ~1,000 km diameter, ~2–3 km thick with interbedded dust. Ice mining for H₂O and CO₂.
- **South Polar Cap** — Permanent CO₂ cap over H₂O ice, ~1–1.5 km thick. Ice mining for H₂O and CO₂.
- **Regolith** — 0–5 m. Basaltic fines, aeolian dust, iron oxides, perchlorates, sulfates. Highly variable thickness.
- **Near-Surface** — 5 m to 0.5 km. Weathered bedrock, cemented regolith, ground ice at mid-to-high latitudes.
- **Subsurface** — 0.5–5 km. Intact basaltic and sedimentary rock, possible deep brines.
- **Deep Crust** — 5–50 km (average crustal thickness ~50 km; thicker south, thinner north). Speculative deep mining.
- **Mantle** — ~50–1,700 km. Silicate (olivine, pyroxene). Speculative planet harvest.
- **Core** — ~1,700–3,390 km. Liquid iron-sulfur alloy, radius ~1,700 km. Speculative planet harvest.

## Ceres

*Mean radius 473 km. Surface gravity 0.28 m/s² (0.03 g). No atmosphere. Partially differentiated ice-rock body; largest asteroid belt object. Abundant water ice and hydrated minerals.*

- **Regolith** — 0–5 m. Hydrated silicates, carbonates, ammoniated clays, organics, water ice. Low-gravity excavation.
- **Crust** — 5 m to ~40 km. Ice-rock mixture (~30–40 vol% H₂O ice), salts, possible clathrates and residual brines near base.
- **Interior** — ~40–473 km. Increasingly rock-dominated hydrated silicate, no distinct metallic core. Speculative deep extraction.

## Vesta

*Mean radius 263 km. Surface gravity 0.25 m/s² (0.025 g). No atmosphere. Fully differentiated with intact crust-mantle-core structure confirmed by Dawn. HED meteorite parent body. Second-largest asteroid.*

- **Regolith** — 0–few m. Howardite-dominated surface (mixed eucrite and diogenite fragments). Coarser than lunar regolith.
- **Crust** — ~few m to ~20 km. Basaltic (eucrite) upper crust over orthopyroxenite (diogenite) lower crust. Rich in pyroxene, plagioclase, Fe, Mg.
- **Mantle** — ~20–150 km. Olivine-dominated ultramafic. Possibly exposed in Rheasilvia basin.
- **Core** — ~150–263 km. Iron-nickel, radius ~110 km. Speculative extraction.

## Pallas

*Mean radius 256 km. Surface gravity ~0.21 m/s² (0.02 g). No atmosphere. B-type (carbonaceous). Density ~2.8 g/cm³ suggests partial differentiation. No spacecraft visit; internal structure poorly constrained. High orbital inclination (~34.8°) increases rendezvous ΔV.*

- **Regolith** — 0–few m. Hydrated silicates, possible organics. Inferred from B-type spectral class and meteorite analogs.
- **Crust/Mantle** — ~few m to ~200 km. Hydrated silicate or ice-rock. Internal layering unknown.
- **Interior** — ~200–256 km. Possibly rocky core, possibly undifferentiated. Highly uncertain.

## Jupiter

*Mean radius 69,911 km at 1-bar reference level. Surface gravity 24.8 m/s² (2.53 g) at 1-bar. No solid surface; H₂/He gas giant. Enormous magnetosphere with intense radiation belts. Key challenges: deep gravity well, extreme radiation environment (hazardous for inner moons), no solid surface, pressure increases rapidly with depth. Primary ³He extraction target in the solar system.*

- **Atmosphere** — Defined as extending from the upper atmosphere to ~1,000 km below the 1-bar reference level. Includes all major cloud decks: NH₃ ice (~0.7 bar), NH₄SH (~2 bar), H₂O (~5 bar). H₂ (~86% by volume), He (~14%), trace CH₄, NH₃, H₂O, H₂S, PH₃. ³He abundance ~15 ppm in H₂. Atmospheric skimming and balloon-based extraction.
- **Molecular Hydrogen Envelope** — ~1,000 to ~15,000 km below 1-bar. Molecular H₂/He compressed from supercritical fluid to dense liquid. Temperature and pressure increase continuously. Speculative deep extraction.
- **Metallic Hydrogen Envelope** — ~15,000 to ~60,000 km depth. Liquid metallic hydrogen and helium. Transition from molecular to metallic is gradual. Source of Jupiter's magnetic field. Speculative planet harvest.
- **Core** — Center, radius ~10,000 km. Dense concentration of rock, ice, and heavy elements (~10–20 Earth masses), likely dilute and mixed with metallic hydrogen rather than sharply bounded (Juno gravity results). Speculative planet harvest.

## Io

*Mean radius 1,822 km. Surface gravity 1.80 m/s² (0.18 g). Tenuous SO₂ atmosphere. Most volcanically active body in the solar system; tidally heated by Jupiter. Extreme radiation environment (innermost Galilean moon, deep in Jupiter's magnetosphere). Surface constantly resurfaced.*

- **Surface** — 0–few m. Sulfur, SO₂ frost, silicate volcanic deposits. Rapidly overturned by eruptions.
- **Crust** — ~few m to ~30 km. Basaltic silicate with interbedded sulfur and SO₂. Active volcanic conduits throughout.
- **Mantle** — ~30–1,200 km. Silicate, extensively partially molten. Global partial melt layer likely at ~30–50 km depth. Speculative extraction.
- **Core** — ~1,200–1,822 km. Iron or iron-sulfide, radius ~350–950 km (poorly constrained). Speculative planet harvest.

## Europa

*Mean radius 1,561 km. Surface gravity 1.31 m/s² (0.13 g). Thin O₂ exosphere. Global subsurface ocean beneath ice shell; strong astrobiological interest. Intense radiation environment. Key challenges: radiation shielding, ice penetration, planetary protection constraints.*

- **Ice Surface** — 0–few m. Radiation-processed water ice, hydrated salts (MgSO₄, NaCl), possible organics. Young, geologically active surface.
- **Ice Shell** — ~few m to ~15–25 km (estimates range 5–30 km). Water ice, fractures, possible brine pockets and sills. Convecting warm ice in lower portion.
- **Subsurface Ocean** — ~20 to ~100 km depth. Liquid saline water, ~60–150 km thick. Contact with rocky seafloor enables hydrothermal chemistry. Planetary protection concerns.
- **Mantle** — ~100 to ~1,000 km depth. Rocky, possibly hydrothermally active at ocean interface. Speculative extraction.
- **Core** — ~1,000–1,561 km. Iron or iron-sulfide, radius ~350–650 km. Speculative planet harvest.

## Ganymede

*Mean radius 2,634 km. Surface gravity 1.43 m/s² (0.15 g). Thin O₂ exosphere. Largest moon in the solar system. Fully differentiated with intrinsic magnetic field. Complex layered ice-ocean interior.*

- **Ice Surface** — 0–few m. Water ice with dark terrain (organic/mineral lag deposits) and bright grooved terrain.
- **Outer Ice Shell** — ~few m to ~150 km. Ice Ih, cold and rigid upper portion transitioning to convecting warm ice.
- **Subsurface Ocean** — ~150 to ~250 km depth. Liquid saline water sandwiched between ice Ih above and high-pressure ices below.
- **Inner Ice** — ~250 to ~800 km. High-pressure ice phases (III, V, VI). Barrier between ocean and rocky interior.
- **Mantle** — ~800 to ~1,930 km depth. Rocky, possibly hydrated at upper boundary. Speculative extraction.
- **Core** — ~1,930–2,634 km. Iron or iron-sulfide, radius ~700 km. Generates intrinsic magnetic field. Speculative planet harvest.

## Callisto

*Mean radius 2,410 km. Surface gravity 1.24 m/s² (0.13 g). Thin CO₂ exosphere. Mostly undifferentiated ice-rock body. Heavily cratered ancient surface. Lowest radiation of Galilean moons (outside main radiation belts); most favorable for human operations in the Jovian system.*

- **Surface** — 0–few m. Ancient, heavily cratered ice-rock. Dark non-ice lag deposit.
- **Outer Shell** — ~few m to ~100 km. Ice-rock mixture, cold and rigid.
- **Subsurface Ocean** — ~100 to ~200 km depth. Thin saline liquid water layer sustained by antifreeze solutes (NH₃, salts). Best guess (see note 3).
- **Interior** — ~200–2,410 km. Compressed ice-rock, gradual increase in rock fraction with depth. No distinct metallic core. Speculative extraction.

## Saturn

*Mean radius 58,232 km at 1-bar reference level. Surface gravity 10.4 m/s² (1.07 g) at 1-bar. No solid surface; H₂/He gas giant, lowest mean density of any planet (0.687 g/cm³). Prominent ring system (see Ring System stratum). Weaker radiation belts than Jupiter; more favorable for inner-moon operations. Lower gravity well than Jupiter improves atmospheric mining feasibility.*

- **Ring System** — Orbiting at ~67,000–137,000 km from Saturn's center (above the atmosphere). Primarily water ice (>95%) with minor silicate and organic tholins. Total mass ~1.5 × 10¹⁹ kg. Particle sizes from dust grains to ~10 m boulders. Low ΔV access from Saturn orbit. High-purity water ice source.
- **Atmosphere** — Defined as extending from the upper atmosphere to ~1,000 km below the 1-bar reference level. Includes cloud decks: NH₃ ice (~1 bar), NH₄SH (~5 bar), H₂O (~10 bar). H₂ (~96% by volume), He (~3%), trace CH₄, NH₃, H₂O, PH₃. ³He abundance ~15 ppm in H₂. Lower escape velocity than Jupiter favors atmospheric skimming.
- **Molecular Hydrogen Envelope** — ~1,000 to ~30,000 km below 1-bar. Molecular H₂/He compressed to supercritical fluid and liquid. Speculative deep extraction.
- **Metallic Hydrogen Envelope** — ~30,000 to ~43,000 km depth. Liquid metallic hydrogen. Transition deeper (as fraction of radius) than Jupiter due to lower internal pressure. Speculative planet harvest.
- **Core** — Center, radius ~15,000 km. Rock, ice, and heavy elements; possibly dilute. Speculative planet harvest.

## Titan

*Mean radius 2,575 km. Surface gravity 1.35 m/s² (0.14 g). Dense N₂–CH₄ atmosphere, ~147 kPa (~1.5 bar) surface pressure. Surface temperature ~94 K (−179 °C). Active methane-ethane hydrological cycle with lakes and seas concentrated near north pole. Subsurface water-ammonia ocean. Only moon with a dense atmosphere. Key challenges: extreme cold, thick haze limiting solar power, methane weather, communication delay.*

- **Atmosphere** — Atmosphere defined as 600 km thick (~99.99% of mass). ~94% N₂, ~5.6% CH₄ (lower atmosphere), complex organic haze layers (tholins) above ~100 km. Atmospheric ISRU for N₂, CH₄, and complex organics.
- **Hydrocarbon Bodies** — Methane-ethane lakes and seas on the surface. Major northern seas: Kraken Mare, Ligeia Mare, Punga Mare. Simplified geometry: ~1% of surface area, depths from a few meters to ~300 m. CH₄, C₂H₆, dissolved N₂, heavier hydrocarbons. Hydrocarbon harvest.
- **Surface** — 0–10 m. Water ice bedrock with organic sediment deposits and tholin dune fields in equatorial regions. Cryogenic excavation.
- **Ice Shell** — ~10 m to ~100 km. Water ice, possible clathrate hydrate layers and cryovolcanic intrusions.
- **Subsurface Ocean** — ~100 to ~200 km depth. Water-ammonia liquid ocean, ~100 km thick. Possibly saline. Astrobiological interest.
- **Inner Ice** — ~200 to ~500 km. High-pressure ice phases (V, VI).
- **Core** — Center, radius ~2,075 km. Hydrated silicate rock; no distinct metallic core confirmed. Speculative deep extraction.

## Mimas

*Mean radius 198 km. Surface gravity 0.06 m/s² (0.01 g). No atmosphere. Dominated by Herschel crater (130 km diameter, ~⅓ of body diameter). Density 1.15 g/cm³. Global subsurface ocean inferred from orbital libration analysis. Ocean geologically recent (~5–25 Myr) based on lack of surface tectonic expression. Best guess (see note 3).*

- **Ice Surface** — 0–few m. Water ice. Herschel impact crater dominates surface morphology. No surface expression of interior ocean.
- **Ice Shell** — ~few m to ~25 km. Rigid water ice, ~20–30 km thick.
- **Subsurface Ocean** — ~25 to ~70 km depth. Global liquid water ocean. Relatively young formation hypothesized.
- **Core** — ~70–198 km (center). Silicate rock, radius ~130 km. Poorly characterized.

## Enceladus

*Mean radius 252 km. Surface gravity 0.11 m/s² (0.01 g). No significant atmosphere (localized water vapor near south pole). Global subsurface ocean confirmed. Active cryovolcanism at south polar tiger stripe fractures: water-ice plumes deliver ocean material to the surface and into space. Hydrothermal activity at ocean-rock interface inferred. Key astrobiological target. Key challenges: Saturn-system distance, planetary protection.*

- **Ice Surface** — 0–few m. Clean water ice, exceptionally high albedo (~0.99). Fresh ice deposits from plume fallback near south pole.
- **Ice Shell** — ~few m to ~20 km (thinner at south pole ~5 km, thicker at equator ~20–25 km). Water ice with tidal fractures and possible liquid brine pockets.
- **Subsurface Ocean** — ~20 to ~60 km depth. Global liquid saline water, ~30–40 km thick. Contains dissolved CO₂, NH₃, H₂, silica nanoparticles. Active hydrothermal venting at ocean floor. Major astrobiological target. Plume ejecta provides direct ocean sampling without drilling.
- **Core** — ~60–252 km (center). Porous silicate rock, radius ~190 km. Low density (~2.4 g/cm³) implies high porosity; hydrothermal circulation permeates the core.

## Tethys

*Mean radius 531 km. Surface gravity 0.15 m/s² (0.01 g). No atmosphere. Nearly pure water ice (density 0.984 g/cm³, ~6% rock by mass). Heavily cratered ancient surface. Ithaca Chasma rift system (~2,000 km long) and Odysseus impact basin (~450 km diameter). No evidence of differentiation or internal activity.*

- **Surface** — 0–few m. Water ice, heavily cratered. Ithaca Chasma and Odysseus basin.
- **Crust** — ~few m to ~100 km. Water ice.
- **Interior** — ~100–531 km. Water ice with very minor rock component. No significant differentiation. High-pressure ice phases possible near center.

## Dione

*Mean radius 561 km. Surface gravity 0.23 m/s² (0.02 g). No atmosphere. Moderately cratered with evidence of past geological activity (tectonic fractures, possible cryovolcanism). Density 1.48 g/cm³ (~50% rock by mass). Possible subsurface ocean supported by Cassini gravity and shape analysis. Best guess (see note 3).*

- **Surface** — 0–few m. Predominantly water ice. Bright wispy features (tectonic ice cliffs on trailing hemisphere).
- **Ice Shell** — ~few m to ~100 km. Water ice, rigid.
- **Subsurface Ocean** — ~100 to ~120 km depth. Thin global liquid water layer in contact with rocky interior. Lower confidence than Enceladus or Mimas oceans.
- **Interior** — ~120–561 km. Rock-enriched ice-rock mixture, radius ~440 km. Partially hydrated silicate. No distinct metallic core.

## Rhea

*Mean radius 764 km. Surface gravity 0.26 m/s² (0.03 g). Tenuous O₂–CO₂ exosphere. Saturn's second-largest moon. Density 1.24 g/cm³ (~25% rock by mass). Heavily cratered, geologically inactive surface. Moment of inertia consistent with near-homogeneous interior (minimal differentiation).*

- **Surface** — 0–few m. Water ice with minor dark non-ice lag material. Heavily cratered.
- **Outer Shell** — ~few m to ~100 km. Ice-rock mixture, primarily water ice.
- **Interior** — ~100–764 km. Ice-rock mixture with gradual increase in rock fraction toward center. No confirmed core. Weakly constrained internal structure.

## Iapetus

*Mean radius 735 km. Surface gravity 0.22 m/s² (0.02 g). No atmosphere. Extreme albedo dichotomy: leading hemisphere very dark (albedo ~0.04), trailing hemisphere bright (albedo ~0.5). Prominent equatorial ridge up to ~20 km elevation. Density 1.09 g/cm³ (~15–20% rock by mass). Shape consistent with a body that froze during more rapid earlier rotation.*

- **Surface** — 0–few m. Dark carbonaceous/tholins material on leading hemisphere, bright water ice on trailing hemisphere. Equatorial ridge.
- **Crust** — ~few m to ~100 km. Water ice with minor rock.
- **Interior** — ~100–735 km. Water ice with minor rock. Likely undifferentiated or minimally differentiated. Possible small rocky concentration near center.

## Uranus

*Mean radius 25,362 km at 1-bar reference level. Surface gravity 8.87 m/s² (0.90 g) at 1-bar. No solid surface; H₂/He/CH₄ ice giant. Extreme axial tilt (97.8°); seasonal variation on ~84-year orbital period. Faint dark ring system. Near-zero excess internal heat flux — coldest planetary atmosphere in the solar system (~49 K at tropopause). Offset, tilted dipole magnetic field (~59° from rotation axis). Key challenges: extreme distance (~19.2 AU), ~2.7-hour one-way light time, very limited survey data (Voyager 2 flyby 1986 only; no dedicated orbiter as of early 2026), deep gravity well. Lower He mass fraction than Jupiter or Saturn may modestly ease ³He separation.*

- **Ring System** — 13 known rings orbiting at ~38,000–51,000 km from Uranus's center (main rings), with faint dusty components extending to ~98,000 km. Narrow, dark (albedo ~0.05). Primarily water ice darkened by radiation-processed organics or silicate dust. Total mass poorly constrained (estimated ~10¹⁵ kg or less — roughly 10,000× less than Saturn's rings). Negligible resource potential at foreseeable scales.
- **Atmosphere** — Defined as extending from upper atmosphere to ~1,000 km below the 1-bar reference level. Cloud decks: CH₄ ice (~1.2 bar), H₂S (~3–6 bar), NH₄SH and H₂O (deeper, ~50+ bar). H₂ (~83% by volume), He (~15%), CH₄ (~2.3%). ³He abundance ~15 ppm in H₂. Atmospheric skimming for H₂, He, ³He, CH₄.
- **Molecular Envelope** — ~1,000 to ~5,000 km below 1-bar. H₂/He compressed from supercritical fluid to dense liquid, with increasing admixture of H₂O, CH₄, and NH₃. Gradual compositional transition toward ionic fluid mantle. Speculative deep extraction.
- **Ionic Fluid Mantle** — ~5,000 to ~20,000 km depth. Hot, dense fluid dominated by H₂O, NH₃, and CH₄ under extreme pressure (~2,000–8,000 K, up to several hundred GPa). Ionic and superionic states; sometimes called the "ice" layer despite being fluid. Possible diamond precipitation from methane decomposition. Source of Uranus's magnetic field. Speculative planet harvest.
- **Core** — Center, radius ~5,000–8,000 km. Rock and metal, ~0.5–3.5 Earth masses. May be diffuse rather than sharply bounded. Poorly constrained by available data. Speculative planet harvest.

## Miranda

*Mean radius 236 km. Surface gravity 0.08 m/s² (0.008 g). No atmosphere. Innermost and smallest of the five major Uranian moons. Extraordinary surface geology: three large coronae (Arden, Elsinore, Inverness) with ridged, grooved, and banded terrain in sharp contact with older cratered plains; Verona Rupes (~20 km cliff face, tallest known in the solar system). Density 1.20 g/cm³ (~40% rock by mass). Surface features suggest intense past geological activity, likely driven by tidal heating during a former orbital resonance with Ariel or Umbriel. Only southern hemisphere imaged by Voyager 2. Key challenges: Uranus-system distance, very limited survey data.*

- **Surface** — 0–few m. Water ice, ammonia hydrate. Coronae display complex ridged and grooved terrain. Verona Rupes cliff face dominates regional topography.
- **Ice Shell** — ~few m to ~100 km. Water ice, possibly ammonia-bearing. Complex deformation history recorded in surface geology.
- **Interior** — ~100–236 km (center). Undifferentiated or weakly differentiated ice-rock mixture. Possible modest rocky concentration toward center (radius ~100 km if differentiated). Any past subsurface ocean likely frozen; no current geological activity.

## Ariel

*Mean radius 579 km. Surface gravity 0.27 m/s² (0.028 g). No atmosphere. Geologically youngest surface of the major Uranian moons. Extensive rift valleys (chasmata: Kachina, Kewpie, Sylph) and smooth plains suggest past cryovolcanism and tectonic resurfacing. CO₂ ice detected spectroscopically on trailing hemisphere (possibly radiolytically produced). Density 1.59 g/cm³ (~55% rock by mass). Only southern hemisphere imaged by Voyager 2. Key challenges: Uranus-system distance, limited survey data.*

- **Surface** — 0–few m. Water ice, CO₂ ice (trailing hemisphere). Relatively young crater-poor terrain with cryovolcanic smooth plains and graben systems.
- **Ice Shell** — ~few m to ~100 km. Water ice. Extensional fractures indicate past stress from interior processes or freezing of subsurface liquid.
- **Subsurface Ocean** — ~100 to ~130 km depth. Possible thin water-ammonia liquid layer. Geological evidence of past internal activity supports a prior ocean; current persistence depends on ammonia concentration and residual heat flux. Best guess (see note 3).
- **Interior** — ~130–579 km (center). Likely partially differentiated: rocky core (radius ~360 km, hydrated silicate) overlain by ice-rock mantle.

## Umbriel

*Mean radius 585 km. Surface gravity 0.23 m/s² (0.023 g). No atmosphere. Ancient, heavily cratered, geologically inactive surface. Darkest of the major Uranian moons (geometric albedo ~0.21). Bright annular feature on the floor of Wunda crater remains unexplained (possible CO₂ ice deposit or impact-exposed fresh ice). Density 1.39 g/cm³ (~45% rock by mass). Only southern hemisphere imaged by Voyager 2. Key challenges: Uranus-system distance, limited survey data.*

- **Surface** — 0–few m. Dark water ice with carbonaceous or organic lag material. Uniformly low albedo. Heavily cratered, no evidence of resurfacing.
- **Ice Shell** — ~few m to ~120 km. Water ice.
- **Subsurface Ocean** — ~120 to ~150 km depth. Possible thin water-ammonia layer. No direct geological evidence of internal activity; retention depends on ammonia concentration. Lower confidence than Ariel. Best guess (see note 3).
- **Interior** — ~150–585 km (center). Ice-rock mixture, possibly weakly differentiated with modest rocky core (radius ~315 km). Poorly constrained internal structure.

## Titania

*Mean radius 789 km. Surface gravity 0.37 m/s² (0.038 g). No atmosphere. Largest moon of Uranus. Extensional tectonic features (grabens, fault scarps with up to ~5 km relief) indicate past global expansion, likely from freezing of interior liquid. CO₂ ice detected on trailing hemisphere. Density 1.71 g/cm³ (~60% rock by mass). Likely differentiated. Most probable of the Uranian moons to retain a current subsurface ocean owing to its larger radiogenic heat budget. Only southern hemisphere imaged by Voyager 2. Key challenges: Uranus-system distance, limited survey data.*

- **Surface** — 0–few m. Water ice, CO₂ ice (trailing hemisphere). Impact craters, tectonic scarps and grabens.
- **Ice Shell** — ~few m to ~100 km. Water ice. Extensional features suggest history of ice shell thickening as subsurface liquid froze.
- **Subsurface Ocean** — ~100 to ~150 km depth. Thin water-ammonia liquid layer; best-supported subsurface ocean case among Uranian moons. Sufficient radiogenic heating from large rocky interior to maintain liquid if ammonia antifreeze is present. Best guess (see note 3).
- **Interior** — ~150–789 km (center). Differentiated rocky core (radius ~520 km, hydrated silicate) with ice-rock mantle above. No distinct metallic core expected.

## Oberon

*Mean radius 761 km. Surface gravity 0.35 m/s² (0.036 g). No atmosphere. Outermost of the five major Uranian moons. Heavily cratered, ancient surface with limited tectonic features. Dark material on several large crater floors (possibly cryovolcanic deposits or impact-excavated subsurface material). Large mountain (~11 km elevation) observed on limb. Density 1.63 g/cm³ (~55–60% rock by mass). Likely differentiated. Only southern hemisphere imaged by Voyager 2. Key challenges: Uranus-system distance, limited survey data.*

- **Surface** — 0–few m. Water ice, dark material deposits. Heavily cratered; several large craters with dark floor deposits.
- **Ice Shell** — ~few m to ~100 km. Water ice.
- **Subsurface Ocean** — ~100 to ~150 km depth. Possible thin water-ammonia layer; slightly less probable than Titania owing to smaller size and radiogenic heat budget. Best guess (see note 3).
- **Interior** — ~150–761 km (center). Differentiated rocky core (radius ~480 km, hydrated silicate) with ice-rock mantle. No distinct metallic core expected.

## Neptune

*Mean radius 24,622 km at 1-bar reference level. Surface gravity 11.15 m/s² (1.14 g) at 1-bar. No solid surface; H₂/He/CH₄ ice giant. Most distant major planet (~30.1 AU). Radiates ~2.6× the energy it receives from the Sun (significant internal heat flux, in contrast to Uranus). Strongest sustained winds in the solar system (up to ~2,100 km/h). Tilted dipole magnetic field (~47° from rotation axis). Faint ring system with partial arcs. Key challenges: extreme distance (~30.1 AU), ~4.2-hour one-way light time, very limited survey data (Voyager 2 flyby 1989 only), deep gravity well, extreme atmospheric wind speeds.*

- **Ring System** — 5 named rings (Galle, Le Verrier, Lassell, Arago, Adams) orbiting at ~42,000–63,000 km from Neptune's center. Faint and partially clumpy; Adams ring contains distinct arcs (Liberté, Égalité, Fraternité). Water ice and silicate dust. Total mass extremely small (estimated ~10¹²–10¹³ kg). Negligible resource potential.
- **Atmosphere** — Defined as extending from upper atmosphere to ~1,000 km below the 1-bar reference level. Cloud decks: CH₄ ice (~1.5 bar), H₂S (~5 bar), H₂O (deeper). H₂ (~80% by volume), He (~19%), CH₄ (~1.5%). ³He abundance ~15 ppm in H₂. Extreme wind speeds at altitude complicate atmospheric extraction operations.
- **Molecular Envelope** — ~1,000 to ~7,000 km below 1-bar. Compressed H₂/He transitioning to heavier-volatile-rich supercritical fluid. Higher internal heat than Uranus drives more vigorous convection. Speculative deep extraction.
- **Ionic Fluid Mantle** — ~7,000 to ~19,000 km depth. Hot, dense ionic/superionic fluid of H₂O, NH₃, CH₄ (~2,000–7,000 K). Source of Neptune's magnetic field. Possible diamond precipitation from methane decomposition. Speculative planet harvest.
- **Core** — Center, radius ~6,000–8,000 km. Rock and metal, possibly ~1–3 Earth masses. May be diffuse. Speculative planet harvest.

## Triton

*Mean radius 1,353 km. Surface gravity 0.78 m/s² (0.08 g). Thin N₂ atmosphere (~1.5 Pa surface pressure). Surface temperature ~38 K — among the coldest solid surfaces in the solar system. Retrograde orbit confirms capture origin (former Kuiper Belt object). Geologically active: nitrogen geysers observed by Voyager 2 at the south polar cap, "cantaloupe terrain" (unique diapir-formed surface), very few impact craters indicating young resurfaced terrain. Density 2.061 g/cm³ (~65–70% rock by mass). Differentiated. Largest moon of Neptune and seventh-largest in the solar system. Key challenges: extreme distance (~30.1 AU), cryogenic temperatures, limited survey data (Voyager 2 flyby 1989 only; southern hemisphere imaged).*

- **Surface** — 0–few m. N₂ ice, CH₄ ice, CO ice, CO₂ ice, H₂O ice. South polar cap of nitrogen ice with dark geyser deposit streaks. Cantaloupe terrain across much of the observed surface. Very young, sparsely cratered.
- **Ice Shell** — ~few m to ~100 km. Water ice with trapped volatile ices (N₂, CH₄, CO) in upper portion, grading to clean water-ammonia ice at depth. Possible clathrate hydrate layers. Active geysers sourced from solar-heated subsurface N₂.
- **Subsurface Ocean** — ~100 to ~350 km depth. Water-ammonia liquid ocean, possibly ~250 km thick. In contact with rocky core at base, enabling hydrothermal chemistry. Intense tidal dissipation during post-capture orbit circularization provided massive heating; residual tidal and radiogenic heat likely sustain current ocean. Among the higher-confidence outer solar system ocean candidates. Best guess (see note 3).
- **Core** — ~350–1,353 km (center). Rocky, radius ~1,000 km. Likely hydrated silicate with possible small metallic concentration at center. Speculative deep extraction.

## Pluto

*Mean radius 1,188 km. Surface gravity 0.62 m/s² (0.063 g). Thin N₂ atmosphere (~1 Pa, highly variable with heliocentric distance and seasonal sublimation). Surface temperature ~44 K. New Horizons flyby (2015) provided detailed surface and atmospheric data. Sputnik Planitia: ~1,000 km wide nitrogen ice basin filling a probable ancient impact structure, with active convective overturn. Water ice mountains (Norgay Montes, Hillary Montes) rising ~3–5 km. Cryovolcanic constructs (Wright Mons, Piccard Mons). Density 1.854 g/cm³ (~65% rock by mass). Differentiated. Tidally locked with Charon. Key challenges: extreme distance (~39.5 AU mean), ~5.5-hour one-way light time, cryogenic temperatures.*

- **Volatile Ice Deposits** — Surface-level deposits of N₂, CH₄, and CO ices. Major deposit: Sputnik Planitia nitrogen-CO ice sheet (~1,000 km diameter, ~4.4% of surface area, up to ~3–4 km thick, actively convecting). CH₄ ice highlands (Tartarus Dorsa bladed terrain, up to ~500 m relief). Volatile redistribution driven by seasonal and orbital sublimation-condensation cycles. Cryogenic volatile harvest.
- **Surface** — 0–few m. Water ice bedrock with variable volatile ice cover and dark tholin deposits. Diverse terrain: nitrogen ice plains, water ice mountains, cryovolcanic edifices, dark equatorial maculae (Cthulhu Macula and others, organic tholins).
- **Water Ice Shell** — ~few m to ~150–200 km. Water ice, possibly insulated by a low-thermal-conductivity gas hydrate (clathrate) layer that retards ocean freezing. Cryovolcanic intrusions possible.
- **Subsurface Ocean** — ~150–300 km depth range. Water-ammonia liquid layer, estimated ~80–100 km thick. Supported by New Horizons evidence: Sputnik Planitia's current orientation implies a positive mass anomaly consistent with thinned ice shell over denser liquid, and global extensional tectonics lack the compressional features expected from a fully frozen interior. In contact with rocky core. Best guess (see note 3).
- **Core** — Center, radius ~850–900 km. Rocky (hydrated silicate); no distinct metallic core expected. Radiogenic heat production helps sustain subsurface ocean. Speculative deep extraction.

## Charon

*Mean radius 606 km. Surface gravity 0.29 m/s² (0.029 g). No confirmed atmosphere (possible thin, transient seasonal exosphere). Surface temperature ~53 K. Tidally locked to Pluto. Red-brown north polar cap (Mordor Macula) attributed to cold-trapped volatiles (CH₄, N₂) originating from Pluto, processed into tholins by UV irradiation. Vulcan Planitia (southern smooth plains) suggests past cryovolcanic resurfacing. Serenity Chasma and related extensional features indicate past global expansion consistent with freezing of an interior ocean. Density 1.702 g/cm³ (~55–60% rock by mass). Differentiated. Characterized by New Horizons (2015). Key challenges: extreme distance, cryogenic temperatures.*

- **Surface** — 0–few m. Water ice, ammonia hydrates, tholins (concentrated at north polar cap). Cratered terrain in north, smoother Vulcan Planitia in south.
- **Ice Shell** — ~few m to ~200 km. Water ice with ammonia. Pervasive extensional fracture systems. A substantial past subsurface ocean has likely largely or fully frozen, driving the observed global expansion; a thin remnant liquid layer at the ice-rock interface (~200 km depth) may persist if ammonia concentration is sufficient. Best guess (see note 3).
- **Core** — ~200–606 km (center). Rocky (hydrated silicate), radius ~400 km. No metallic core expected.

## Small/Undifferentiated Bodies

*Small bodies with negligible to very low surface gravity and no atmospheres. Specific bodies have individual characteristics but are treated as bulk-composition strata.*

- **Phobos (bulk)** — Mars moon. Irregular, mean radius ~11 km. Density ~1.87 g/cm³ (highly porous). C/D-type spectral affinity. Possibly captured or co-accreted with Mars. Accessible from Mars orbit with very low ΔV. Potential volatile content; strategic Mars-system resource depot.
- **Deimos (bulk)** — Mars moon. Irregular, mean radius ~6 km. Density ~1.47 g/cm³. Similar spectral properties to Phobos. Higher Mars orbit (~23,460 km), very low escape velocity.
- **Amalthea (bulk)** — Jupiter moon. Irregular, mean dimensions ~250 × 146 × 128 km (mean radius ~84 km). Density 0.86 g/cm³ — anomalously low (below water ice), requiring substantial macroporosity regardless of composition. Reddish surface from sulfur and sulfur compounds sputtered from Io. Orbits within Jupiter's gossamer ring and intense inner magnetospheric radiation environment. Observed in detail by Galileo spacecraft. Possible rubble-pile structure.
- **Hyperion (bulk)** — Saturn moon. Irregular, mean dimensions ~360 × 280 × 225 km (mean radius ~135 km). Density ~0.54 g/cm³ (~40% porosity, sponge-like structure). Dark reddish material (organics/carbonaceous). Chaotic tumbling rotation. Water ice with dark organic surface material.
- **Phoebe (bulk)** — Saturn moon. Near-spherical, mean radius ~107 km. Density ~1.64 g/cm³. Retrograde orbit; likely captured Kuiper Belt or outer solar system object. Water ice, CO₂ ice, dark carbonaceous material, phyllosilicates. Compositionally primitive.

## Generic

*Generic types are compositional templates for unsurveyed small/undifferentiated bodies (see note 6).*

- **Class-M (bulk)** — Metallic. Primarily Fe-Ni alloy with possible platinum-group element enrichment. High radar albedo. Interpreted as core material from differentiated parent bodies. Iron meteorite analogs; stony-iron variants bridge toward Class-A.

- **Class-E (bulk)** — Enstatite. High optical albedo, chemically reduced mineralogy: enstatite (MgSiO₃), oldhamite (CaS), niningerite, exotic sulfides. Formed under highly reducing, low-oxygen conditions. Aubrite and enstatite chondrite analogs.

- **Class-V (bulk)** — Basaltic. Pyroxene-rich differentiated crust material (low-Ca and high-Ca pyroxene, plagioclase). Evidence of igneous processing on parent body. HED (howardite–eucrite–diogenite) meteorite analogs.

- **Class-A (bulk)** — Olivine-Rich. Dominated by olivine (forsterite–fayalite series), with minor pyroxene or Fe-Ni metal. Mantle fragments of disrupted differentiated parent bodies. Rare. Pallasite and brachinite meteorite affinities.

- **Class-S (bulk)** — Siliceous. Olivine, pyroxene, feldspar, minor Fe-Ni metal. Moderate albedo. Spans ordinary chondrite through partially melted compositions. ~17% of characterized small bodies. Fresh unweathered surfaces present Q-type spectra.

- **Class-C (bulk)** — Carbonaceous. Phyllosilicates, water of hydration, organic compounds, magnetite, sulfides. Low albedo. Aqueously altered. CI/CM/CR chondrite analogs. Most common class (~75% of characterized bodies). Subtypes (B, F, G) reflect varying aqueous and thermal processing histories rather than fundamentally different bulk compositions.

- **Class-D (bulk)** — Dark Primitive. Very low albedo, anhydrous silicates, carbon-rich organic compounds, spectrally red. Minimal aqueous alteration; less processed than Class-C. Any volatile content is minor or deeply sequestered. Subsumes related P-type and T-type spectral variants.

- **Class-I (bulk)** — Ice-Volatile. Ice-rock-organic mixture with volatiles as a major bulk component (roughly ≥20% by mass). Volatile species include H₂O ice, CO₂, CO, CH₃OH, NH₃, HCN, and others; refractory fraction is silicate rock and organic solids. Low bulk density (~0.4–0.6 g/cm³), high porosity. Applies regardless of current outgassing state — encompasses active, dormant, and depleted volatile-bearing bodies alike. Grades into Class-D at low volatile fractions.

- **Class-U (bulk)** — Ultra-Primitive. Ice-rich interior mantled by irradiated organic compounds (tholins). Ultra-red spectral slope. May retain hypervolatiles (N₂, CO, CH₄) depending on thermal history. Represents cold-preserved, minimally processed primordial material. Very low bulk density, high porosity; contact-binary and bilobed morphologies common. Grades into Class-I for thermally evolved examples where the tholin mantle has been lost or volatiles partially mobilized.