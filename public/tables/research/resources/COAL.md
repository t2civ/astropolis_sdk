I need information for a simulation that focuses on resource streams, energy, and commodity markets. Some abstractions and simplifications are necessary. However, please tell me if my instructions seem too oversimplified or have erroneous assumptions. Ask for clarification if it may help in subsequent queries. Summarize simplifications and important omissions in your analysis. State references and show your work.

The simulation entity is the resource "coal". There is only one entity in the simulation that represents all coal in the world.

- Describe a typical "coal" that can be used to simulate worldwide extraction and usage.
- Provide a "Brief Description" that can be used as context for further AI queries. Include composition by weight. It may include a subtype name if applicable.
- Provide a broad outline of the industrial processes, resource streams, and energy involved in extraction, transport, and ultimate usage in power generation. (Keep it short and high level here. I'll be asking for details separately.)
- Provide a broad outline of extraction and usage quantities by region. (Again, keep this short and high level.)
- Provide market price estimations in USD for 2010, 2020, and 2030 (projected).

---
---

_Claude-Opus-4.6 (output effort = medium)._

---
---

*Thinking...*

> The user wants a simplified but reasonable representation of "coal" as a single entity for a resource/commodity simulation. Let me provide a well-structured response covering all their bullet points.
> 
> Let me think about what a "typical" coal would look like if we're collapsing all global coal into one representative type.
> 
> Global coal is roughly split between thermal (steam) coal and metallurgical (coking) coal, with thermal being ~85% of production. The most common rank used globally is bituminous/sub-bituminous. A reasonable "average" would be something like a high-volatile bituminous thermal coal.
> 
> Composition by weight for a typical thermal coal (as-received basis):
> 
> 
> Carbon: ~60-75%, Hydrogen: ~4-5%, Oxygen: ~5-10%, Nitrogen: ~1-2%, Sulfur: ~1-3%, Moisture: ~8-15%, and Ash: ~8-15%. Energy content sits around 22-26 MJ/kg. For a world average thermal coal, I'll anchor to something like the Newcastle benchmark—a common reference point in global coal trading—targeting a calorific value around 24 MJ/kg.
> 
> Looking at production volumes, the world generated roughly 8 billion tonnes in 2023, with China dominating at about 50%, followed by India and Indonesia at 10% each, and the US, Australia, and Russia each around 5%. On pricing, Newcastle thermal coal has moved significantly: around $98-100/tonne in 2010, dipped to $60-65/tonne in 2020 during the COVID downturn, and projections for 2030 suggest a range of $90-130/tonne depending on energy transition scenarios.

# Coal — Simulation Entity Summary

## Simplifications & Important Omissions

Before diving in, here are the key abstractions I'm applying and caveats worth flagging:

Coal is not one product. It spans lignite (brown coal) through anthracite, and the market distinguishes sharply between **thermal coal** (~85% of global production, used for power/heat) and **metallurgical/coking coal** (~15%, used for steelmaking). Coking coal trades at a substantial premium (often 2–3× thermal coal prices). By collapsing these into one entity, you lose the ability to model steel-sector demand independently. This is probably fine for a power-generation-focused simulation, but worth noting.

Other simplifications: I'm ignoring coal-to-liquids (CTL) and coal-to-chemicals (significant in China but a small share globally), and I'm treating transport as a single averaged step rather than distinguishing mine-mouth power plants (short haul) from seaborne export trade (long haul). Regional quality differences (e.g., Indonesian sub-bituminous vs. South African bituminous vs. Australian premium) are averaged out.

If any of these matter for your simulation's fidelity, let me know and I can break them out.

---

## Brief Description

**Representative type:** High-volatile bituminous thermal coal (closest to the globally traded benchmark grade, e.g., Newcastle 6000 kcal/kg NAR).

**Typical composition (as-received weight basis):**

Carbon 62%, Oxygen 8%, Hydrogen 4.5%, Nitrogen 1.3%, Sulfur 1.2%, Moisture 12%, Ash 11%.

**Gross calorific value:** ~24 MJ/kg (approximately 5,750 kcal/kg on a net-as-received basis). This places it squarely between sub-bituminous and medium-volatile bituminous, which is a reasonable world-average for thermal coal when weighting high-moisture Indonesian exports against higher-grade Australian and South African product.

**Bulk density (as-handled):** ~800–900 kg/m³, relevant for transport modeling.

*References: Typical proximate/ultimate analyses are drawn from World Coal Association technical documentation and the IEA's Coal Information reports. The 6000 kcal/kg NAR figure aligns with the globalCOAL Newcastle index specification (IEA, "Coal Information 2023").*

---

## Industrial Process Outline (Extraction → Power Generation)

**1 — Extraction (Mining)**
Coal is extracted via surface (open-cut/strip) mining or underground (longwall/room-and-pillar) mining. Roughly 60% of global production is surface-mined. Key inputs are diesel fuel for haul trucks and excavators, electricity for draglines and conveyors, and explosives (ammonium nitrate/fuel oil). Energy intensity of mining is roughly 50–150 MJ per tonne of coal produced, varying with seam depth and method.

**2 — Preparation (Beneficiation)**
Run-of-mine coal is crushed, screened, and often washed (density separation in water/magnetite medium) to reduce ash and moisture content. This step consumes electricity and water and produces a reject/tailings stream. Not all coal is washed — much of China's and India's domestic coal skips this step.

**3 — Transport**
Coal moves by rail, barge, conveyor, or truck to either a domestic power plant or an export terminal. Seaborne trade (~1.4 billion tonnes/year) uses bulk carriers (Capesize/Panamax). Transport is the largest variable cost component; for exported coal, shipping can represent 15–40% of delivered cost. Energy input is primarily diesel (rail/truck) and bunker fuel (shipping).

**4 — Power Generation (Combustion)**
Pulverized coal is burned in a boiler to produce steam, which drives a turbine-generator. Subcritical plants achieve ~33–35% thermal efficiency; supercritical and ultra-supercritical plants reach 40–45%. Outputs are electricity, waste heat, flue gas (CO₂, SO₂, NOₓ, particulates), and bottom/fly ash. A representative global-average fleet efficiency is approximately **37%**, reflecting the mix of old subcritical and newer supercritical capacity.

**Approximate energy balance for 1 tonne of representative coal:**
Input energy of ~24,000 MJ yields roughly 8,900 MJ of electricity (~2,470 kWh) at 37% efficiency, with ~15,100 MJ rejected as waste heat and losses. CO₂ emissions are approximately **2.3 tonnes CO₂ per tonne of coal burned** (derived from 62% carbon content × 3.667 CO₂/C ratio, with minor corrections for incomplete combustion).

*References: IEA "Energy Technology Perspectives"; MIT "The Future of Coal" (2007, updated findings); US EIA electric power efficiency data.*

---

## Extraction & Usage by Region (approximate, ~2023 baseline)

Global production is approximately **8.5 billion tonnes/year** (2023), of which roughly 5.5 Bt is thermal and the remainder is coking coal plus lignite (counted in gross tonnes).

**China** dominates both production and consumption at roughly **50%** of global output (~4.5 Bt) and a similar share of consumption, almost entirely for domestic use. **India** produces ~1.0 Bt and is the world's second-largest consumer, supplementing domestic output with imports. **Indonesia** produces ~0.8 Bt, mostly for export (world's largest thermal coal exporter). **The United States** produces ~0.5 Bt, down sharply from ~1.0 Bt in 2008, with declining domestic demand and modest exports. **Australia** produces ~0.5 Bt, heavily export-oriented (second-largest exporter, dominant in coking coal). **Russia** produces ~0.4 Bt, with significant exports to Asia and Europe (pre-2022 sanctions shifted flows). The rest of the world (South Africa, Colombia, Kazakhstan, Poland, etc.) collectively accounts for the remaining ~0.8 Bt.

Seaborne trade totals roughly **1.4 Bt/year**, meaning about 80–85% of coal is consumed domestically in the country of extraction.

*References: IEA "Coal 2023" report; BP/Energy Institute "Statistical Review of World Energy 2024."*

---

## Market Price Estimates (USD/metric tonne, thermal coal)

I'm using the **Newcastle FOB 6000 kcal/kg NAR** benchmark as the reference, since it's the most widely cited global thermal coal price index. Annual averages:

**2010:** ~$99/tonne. This was a post-GFC recovery year; prices had rebounded from a 2009 low of ~$70 on strong Chinese import demand. (Source: globalCOAL/ICE Newcastle index historical data.)

**2020:** ~$60/tonne. COVID-related demand destruction pushed prices to multi-year lows, with the annual average settling around $58–65 depending on the exact index. (Source: same.)

**2030 (projected):** This is highly scenario-dependent. The IEA's Stated Policies Scenario (STEPS) suggests thermal coal prices in the range of **$80–110/tonne** (real 2023 USD), reflecting gradual demand decline offset by supply-side underinvestment. The IEA's Net Zero Emissions (NZE) scenario implies much lower prices ($40–60) as demand collapses. A reasonable central simulation assumption would be **~$90–100/tonne**, acknowledging that the 2021–2022 energy crisis ($200–400+ spot spikes) demonstrated that tight supply can produce extreme volatility even against a backdrop of long-term demand decline.

*References: IEA "World Energy Outlook 2024" price assumptions; World Bank Commodity Markets Outlook (Oct 2024); ICE Newcastle futures curves as of late 2025.*

---

**A note on what to ask next:** If you want me to go deeper on any branch — for instance, detailed energy/mass balances for the combustion step, a more granular regional trade-flow model, or coking coal as a separate entity — just say the word.
