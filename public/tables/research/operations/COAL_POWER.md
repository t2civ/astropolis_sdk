I need information for a simulation. Some abstractions or simplifications may be necessary. However, please tell me if my instructions seem too oversimplified or have erroneous assumptions. Summarize simplifications and important omissions in your analysis. State references and show your work.

The process is coal power. First, characterize a typical "coal" that can be used to model worldwide usage for coal power. Please include water or any other reactants/products that are part of the composition of coal in your analysis. You can ignore air components that aren't part of the chemical reaction. If the process generates excess oxygen, please deduct that amount from the input rate. Total mass rate should be the same for reactants and products (if not, explain and quantify any differences).

Provide final answers in tonnes/hour (t/h) or megawatts (MW). Normalize results to 1 MW of electricity generated.

Required values:

Input rates of coal and oxygen.
Output rates of carbon dioxide, water, sulfur dioxide, carbon monoxide, and ash.
Total mass rate.
Waste heat.

---

_Claude-Opus-4.6 (output effort = medium). Feb 10, 2026._
_Note: I forgot to list nitrogen (N2) in products but Claude listed it anyway. Intentionally ignoring NOx._

---

*Thinking...*

> The user wants a mass and energy balance for coal power generation, normalized to 1 MW of electrical output. Let me work through this systematically.
> 
> ## Step 1: Characterize typical coal
> 
> For a worldwide average, I'll use a bituminous coal representative of global power generation. Based on World Energy Council data and standard references (e.g., Steam: Its Generation and Use by Babcock & Wilcox; EPA AP-42 emission factors), a reasonable "typical" coal for worldwide power generation:
> 
> **Proximate/Ultimate Analysis (as-received basis):**
> 
> Using a composite that reflects the global mix (which includes significant sub-bituminous and bituminous coal):
> 
> 
> - Carbon (C): 62%
> - Hydrogen (H): 4.2%
> - Oxygen (O): 8.5%
> - Nitrogen (N): 1.3%
> - Sulfur (S): 1.5%
> - Moisture (H₂O): 12%
> - Ash: 10.5%
> 
> This composition totals 100% and gives a higher heating value of approximately 25 MJ/kg, which is typical for the global coal mix used in power generation.
> 
> Now I'm refining my assumptions. The global average HHV is probably closer to 24 MJ/kg when accounting for the large proportion of lower-quality coal burned worldwide, and I should use 33% net efficiency as a realistic global average for coal power plants after accounting for auxiliary losses.
> 
> With 33% efficiency, a 1 MW electrical output requires 3.03 MW of thermal input, which I can convert using the 24 MJ/kg heating value.
> 
> Now I'm calculating the actual coal consumption rate and working through the combustion stoichiometry per kilogram of coal. For the carbon content, I'm using the molecular weight ratios to determine oxygen requirements and CO₂ production, though I need to account for the fact that real coal plants produce small amounts of CO from incomplete combustion rather than complete conversion to CO₂. Now I'm working through the stoichiometry for the CO₂ production from that carbon fraction, calculating the oxygen needed and the resulting CO₂ mass. I'm also reconsidering the CO emission factor—EPA data shows it's quite small at 0.25 g per kg of coal, so I'll stick with that realistic value rather than inflating it. Moving on to hydrogen combustion next.
> 
> For the hydrogen content, I'm applying the same stoichiometric approach: 0.042 kg of hydrogen requires oxygen in a 16:2 mass ratio and produces water vapor at an 18:2 ratio. Then I'm handling sulfur combustion similarly—0.015 kg of sulfur needs an equal mass of oxygen and yields 0.030 kg of SO₂. I also need to account for the oxygen already present in the coal itself, which reduces the external oxygen demand, plus the moisture that simply passes through as water vapor in the flue gas. Now I'm summing up the total oxygen requirement from air.
> 
> I'm recalculating the oxygen needed more systematically: carbon requires 1.6533 kg of oxygen per kg of coal, hydrogen needs 0.336 kg, and sulfur needs 0.015 kg, totaling about 2.0043 kg. After subtracting the 0.085 kg of oxygen already in the coal, the net oxygen I need to pull from air is roughly 1.92 kg per kg of coal. Now I'm moving on to quantifying the products.
> 
> For every kilogram of coal burned, I get 2.27 kg of CO₂, about 0.5 kg of water (combining combustion water from hydrogen and the moisture already in the coal), 0.03 kg of SO₂, 0.105 kg of ash, and trace amounts of CO. The nitrogen in the coal mostly converts to N₂ but some forms NOx, which I'm treating as a minor component for now. Let me verify the mass balance by checking that inputs equal outputs. Now I'm calculating the stoichiometric oxygen requirement by working through each element's combustion needs, then subtracting the oxygen already present in the coal to find how much needs to come from air.
> 
> With the coal and required oxygen as inputs, I'm determining the mass of each combustion product—carbon dioxide, water vapor, sulfur dioxide, and ash—along with the nitrogen from fuel oxidation and a small amount of carbon monoxide.
> 
> The total output mass comes to 2.9196 kg, which matches the input of 2.9193 kg within rounding error. The tiny discrepancy of 0.0003 kg comes from the CO production, but it's negligible. Let me refine this by accounting for the oxygen requirement more precisely: the small amount of carbon forming CO instead of CO₂ reduces the oxygen needed slightly, and I can verify this doesn't meaningfully change the overall balance.
> 
> Now I'm scaling everything up to 1 MW electrical output. At this power level, the coal consumption is 0.455 tonnes per hour, so I multiply all the per-kilogram values by 1000 to get the hourly rates. The oxygen requirement becomes 0.873 tonnes per hour, while CO₂ production is 1.034 tonnes per hour, and I'm calculating the water vapor output as well.
> 
> Continuing with the remaining outputs: water vapor comes to 0.227 tonnes per hour, SO₂ at 0.0137 tonnes per hour, trace amounts of CO and nitrogen from the fuel, and ash residue at 0.0478 tonnes per hour. The mass balance checks out perfectly—total inputs and outputs both equal 1.328 tonnes per hour, confirming the calculations are consistent.
> 
> Now looking at the waste heat side: with a thermal input of 3.03 megawatts and electrical output of 1.00 megawatt, that leaves 2.03 megawatts dissipated as waste heat. I'm cross-checking my coal composition assumptions against global averages—the IEA data suggests coal-fired power plants operate at roughly 33% net efficiency on a global basis, which aligns with what I'm seeing here.
> 
> The efficiency varies significantly by region and plant age: newer facilities in developed nations hit 38-45%, but the global average gets pulled down by the large installed base of older plants, particularly in developing countries. For the coal's energy content, I'm settling on 24 MJ/kg as a reasonable global weighted average, accounting for China's bituminous coal around 25-27 MJ/kg, the US mix of sub-bituminous and bituminous ranging from 20-30 MJ/kg, and India's lower-quality coal in the 15-20 MJ/kg range.
> 
> Using 24 MJ/kg with 33% efficiency gives me a coal consumption rate of about 0.455 tonnes per hour per megawatt, which aligns with standard industry references of 0.4-0.5 t/h per MW. I should note that coal combustion consumes oxygen rather than generating it, so the user's instruction about deducting excess oxygen doesn't apply here. Real plants have pollution controls that remove most SO₂ and other contaminants, but the chemical reaction itself produces the products I've outlined.

# Coal Power Mass & Energy Balance — 1 MW Electrical Output

## Representative Coal Composition

To model the global fleet, I use a composite bituminous/sub-bituminous coal on an as-received basis, reflecting the mix burned worldwide (primarily in China, India, the US, and Europe). The values below draw on typical ultimate analyses reported in Babcock & Wilcox's *Steam: Its Generation and Use* (42nd ed.) and EPA AP-42 (Ch. 1.1), adjusted toward a global-average heating value consistent with IEA efficiency reporting.

| Component | Mass fraction |
|-----------|------------:|
| Carbon (C) | 62.0% |
| Hydrogen (H) | 4.2% |
| Oxygen (O) | 8.5% |
| Nitrogen (N) | 1.3% |
| Sulfur (S) | 1.5% |
| Moisture (H₂O) | 12.0% |
| Ash (inert mineral) | 10.5% |
| **Total** | **100.0%** |

**Higher heating value (HHV):** 24 MJ/kg

**Global average net electrical efficiency:** 33% (IEA World Energy Outlook, consistent with a fleet-average heat rate ≈ 10,900 kJ/kWh)

---

## Combustion Stoichiometry (per kg of coal)

The three exothermic reactions that matter, plus moisture pass-through:

$$
\text{C} + \text{O}_2 \rightarrow \text{CO}_2
$$

$$
2\text{H}_2 + \text{O}_2 \rightarrow 2\text{H}_2\text{O}
$$

$$
\text{S} + \text{O}_2 \rightarrow \text{SO}_2
$$

A trace of carbon converts to CO rather than CO₂. EPA AP-42 (Table 1.1-3) gives approximately 0.25 g CO per kg of bituminous coal burned in a utility boiler, so I assign that directly.

### Oxygen demand (per kg coal)

| Reaction | Reactant mass (kg) | O₂ required (kg) | Product | Product mass (kg) |
|---|--:|--:|---|--:|
| C → CO₂ | 0.6199 | 0.6199 × 32/12 = 1.6531 | CO₂ | 0.6199 × 44/12 = 2.2730 |
| C → CO | 0.0001 | 0.0001 × 16/12 = 0.0001 | CO | 0.0001 × 28/12 = 0.0003 |
| H → H₂O | 0.0420 | 0.0420 × 16/2 = 0.3360 | H₂O | 0.0420 × 18/2 = 0.3780 |
| S → SO₂ | 0.0150 | 0.0150 × 32/32 = 0.0150 | SO₂ | 0.0150 × 64/32 = 0.0300 |
| **Totals** | | **2.0042** | | |

Oxygen already present in the coal: **0.0850 kg**

**Net O₂ required from air = 2.0042 − 0.0850 = 1.919 kg per kg coal**

(The process consumes oxygen; no excess oxygen is generated, so no deduction applies.)

---

## Mass Balance Check (per kg coal)

### Inputs

| Stream | Mass (kg) |
|--------|--------:|
| Coal | 1.0000 |
| O₂ (from air) | 1.9192 |
| **Total in** | **2.9192** |

### Outputs

| Stream | Mass (kg) |
|--------|--------:|
| CO₂ | 2.2730 |
| H₂O (combustion + moisture) | 0.3780 + 0.1200 = 0.4980 |
| SO₂ | 0.0300 |
| CO | 0.0003 |
| Ash | 0.1050 |
| N₂ (from fuel nitrogen) | 0.0130 |
| **Total out** | **2.9193** |

**Imbalance: < 0.01%** — attributable to rounding in the CO split. Mass is conserved.

---

## Scaling to 1 MW Electrical Output

Thermal input required:

$$
\dot{Q}_{\text{th}} = \frac{1 \text{ MW}_e}{0.33} = 3.03 \text{ MW}_{\text{th}}
$$

Coal consumption rate:

$$
\dot{m}_{\text{coal}} = \frac{3.03 \text{ MJ/s}}{24 \text{ MJ/kg}} = 0.1263 \text{ kg/s} = \mathbf{0.455 \text{ t/h}}
$$

All other streams scale linearly:

### Final Results — Normalized to 1 MW_e

| **INPUTS** | Rate (t/h) |
|---|--:|
| Coal | 0.455 |
| Oxygen (from air) | 0.873 |
| **Total in** | **1.328** |

| **OUTPUTS** | Rate (t/h) |
|---|--:|
| Carbon dioxide (CO₂) | 1.034 |
| Water vapor (H₂O) | 0.227 |
| Sulfur dioxide (SO₂) | 0.014 |
| Carbon monoxide (CO) | 0.00011 |
| Ash | 0.048 |
| Nitrogen (from fuel N, as N₂) | 0.006 |
| **Total out** | **1.328** |

| **ENERGY** | Value |
|---|--:|
| Thermal input (HHV) | 3.03 MW |
| Electrical output | 1.00 MW |
| **Waste heat** | **2.03 MW** |

---

## Simplifications & Important Omissions

**Simplifications made:**

The coal composition is a single representative blend; real coals vary enormously (HHV from ~15 MJ/kg for Indian coal to ~30 MJ/kg for high-rank bituminous), so any single composition is approximate. The 33% net efficiency is a fleet-weighted global average; individual plants range from roughly 25% (old subcritical) to 45% (ultra-supercritical). Complete combustion is assumed except for the trace CO from EPA AP-42 emission factors. Fuel nitrogen is assumed to exit as N₂, which is the dominant pathway.

**Important omissions:**

NOₓ emissions (typically 1–5 g/kg coal) are omitted — fuel nitrogen actually produces some NO/NO₂, not just N₂. Particulate matter and trace pollutants (mercury, other heavy metals, and fly ash vs. bottom ash split) are not broken out. Unburned carbon in ash (typically 1–5% of ash mass) is ignored. Flue gas desulfurization would capture 90–99% of SO₂ in modern plants, but I report the raw combustion products as requested. Atmospheric nitrogen heated in the flue gas carries significant sensible heat (the dominant waste-heat pathway in practice) but is excluded from the mass balance per the instruction to ignore non-reacting air components. The latent heat in the water vapor is embedded in the HHV basis; a lower-heating-value (LHV) analysis would shift the efficiency and waste heat figures slightly.

**References:** Babcock & Wilcox, *Steam* 42nd ed.; US EPA AP-42, 5th ed., Chapter 1.1; IEA *World Energy Outlook* (2022/2023 editions for fleet-average efficiency data); Singer, *Combustion: Fossil Power Systems*, 4th ed.
