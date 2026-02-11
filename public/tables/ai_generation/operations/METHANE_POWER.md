I need information for a simulation. Some abstractions or simplifications may be necessary. However, please tell me if my instructions seem too oversimplified or have erroneous assumptions. Summarize simplifications and important omissions in your analysis. State references and show your work.

The process is natural gas combustion power. Assume input gas is pure methane. Assume a typical worldwide thermal efficiency. Total mass rate should be the same for reactants and products (if not, explain and quantify any differences).

Provide final answers in tonnes/hour (t/h) or megawatts (MW). Normalize results to 1 MW of electricity generated.

Required values:

* Input rates of methane and oxygen (from air).
* Output rates of carbon dioxide and water.
* Total mass rate.
* Assumed thermal efficiency.


---

_Claude-Opus-4.6 (output effort = medium). Feb 10, 2026._

---

*Thinking...*

> Let me work through this systematically.
> 
> **Combustion reaction:**
> CH₄ + 2O₂ → CO₂ + 2H₂O
> 
> **Molar masses:**
> - CH₄: 16.04 g/mol
> - O₂: 32.00 g/mol
> - CO₂: 44.01 g/mol
> - H₂O: 18.02 g/mol
> 
> **Mass balance check:**
> Reactants: 16.04 + 2(32.00) = 16.04 + 64.00 = 80.04 g
> 
> 
> Products: 44.01 + 2(18.02) = 44.01 + 36.04 = 80.05 g — the rounding checks out.
> 
> **Thermal efficiency:**
> For natural gas power plants, I need to consider the range of technologies in use globally. Modern combined-cycle systems reach 55-62% efficiency, while simpler designs operate around 30-40%. Taking into account the mix of older and newer plants worldwide, a 40% average seems reasonable as a baseline estimate.
> 
> **Heat of combustion:**
> Methane's lower heating value is about 50.0 MJ/kg, which is the appropriate measure for gas turbines since water vapor escapes in the exhaust.
> 
> **Calculating methane consumption for 1 MW output:**
> At 40% efficiency, I need 2.5 MW of thermal input. Dividing by the heat of combustion gives me 0.05 kg/s of methane, or 0.18 tonnes per hour.
> 
> **Stoichiometric calculations:**
> Now I'm working through the combustion reaction to determine the oxygen and product requirements. Completing the calculation, I get CO₂ at 0.494 t/h and H₂O at 0.404 t/h. The mass balance checks out—reactants and products both total 0.898 t/h, confirming conservation of mass in this combustion reaction.

## Natural Gas Combustion — Normalized to 1 MW Electrical Output

### Combustion Reaction

**CH₄ + 2 O₂ → CO₂ + 2 H₂O**

Molar masses: CH₄ = 16.04 g/mol, O₂ = 32.00 g/mol, CO₂ = 44.01 g/mol, H₂O = 18.02 g/mol.

### Assumed Thermal Efficiency

I use **40%** (LHV basis), representing a worldwide fleet-average that blends older simple-cycle turbines (~30–38%) with modern combined-cycle plants (~55–62%). The IEA's *World Energy Outlook* series reports global average gas-plant efficiency in this range. This is the single largest lever on all the numbers below — a specific plant could differ by ±50% relative.

### Thermal Input

$$P_{\text{th}} = \frac{1 \text{ MW}_e}{0.40} = 2.50 \text{ MW}_{\text{th}}$$

### Methane Input Rate

Using the lower heating value of methane, LHV = 50.0 MJ/kg (ref: NIST WebBook, engineering tables):

$$\dot{m}_{\text{CH}_4} = \frac{2.50 \text{ MW}}{50.0 \text{ MJ/kg}} = 0.0500 \text{ kg/s} = \mathbf{0.180 \text{ t/h}}$$

### Stoichiometric Mass Ratios (per kg CH₄)

From the balanced equation:

$$\frac{m_{\text{O}_2}}{m_{\text{CH}_4}} = \frac{2 \times 32.00}{16.04} = 3.990, \quad \frac{m_{\text{CO}_2}}{m_{\text{CH}_4}} = \frac{44.01}{16.04} = 2.743, \quad \frac{m_{\text{H}_2\text{O}}}{m_{\text{CH}_4}} = \frac{2 \times 18.02}{16.04} = 2.247$$

### Results (per 1 MW_e)

| Stream | Rate (t/h) |
|---|---|
| **CH₄ in** | 0.180 |
| **O₂ in** | 0.718 |
| **CO₂ out** | 0.494 |
| **H₂O out** | 0.404 |
| **Total reactants** | **0.898** |
| **Total products** | **0.898** |

Mass is conserved. In a chemical reaction the mass-equivalent of the released energy ($$\Delta m = E/c^2$$) is about $$10^{-10}$$ of the total mass — entirely negligible here.

### Simplifications & Omissions

**Fuel purity.** Real pipeline natural gas is ~87–96 mol% methane, with ethane, propane, CO₂, and N₂ making up the rest. This changes the C:H ratio, heating value, and CO₂ intensity slightly (typically raising all three).

**Air vs. pure O₂.** The oxygen is drawn from air (~21 vol% O₂). The accompanying nitrogen (~3.29 t/h at stoichiometric ratio, more in practice due to excess air of 10–15%) passes through the turbine and dominates the exhaust mass flow. It also leads to thermal NOₓ formation, which is ignored here.

**Excess air.** Real turbines operate fuel-lean. This doesn't change the fuel or CO₂ numbers but increases total exhaust mass and lowers exhaust temperature.

**LHV vs. HHV.** I used the lower heating value, standard for gas turbines where exhaust water leaves as vapor. If the higher heating value (55.5 MJ/kg) were used, the same 40% efficiency label would imply a different fuel rate.

**Auxiliary loads and losses.** The 1 MW is assumed net electrical; in practice, parasitic loads (pumps, fans, controls) consume 2–5% of gross output.

### Key References

The heating value and molar masses come from the NIST Chemistry WebBook. Global average efficiency figures are drawn from IEA *World Energy Outlook* (2022/2023 editions) and the IEA *Electricity Information* statistical reports.