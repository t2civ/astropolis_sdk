Just my random disorganized notes while doing research...


*******************************************************************************
Power generation (for operations.tsv & modules.tsv)


MWt or MWth denotes thermal or chemical energy. MWe is electrical output.

"Heat Rate" in the inverse of efficiency, but often shown in whacky Btu/kWh
units (e/e should be unitless). Top is thermal/chemical engery input, bottom is
electrical energy output.
1 kWh = 3.6 MJ = 3,412 Btu
https://en.wikipedia.org/wiki/Power_plant_efficiency

Typical heat rates (in Btu/kWh, so 3,412 is 100% efficiency):
Coal-fired steam turbine: 10,000 - 12,000
Gas-fired steam turbine: 10,000 - 13,000
Combined-cycle gas turbine: 6000 - 9000
https://blog.enerdynamics.com/2015/11/12/heat-rate-a-driving-force-behind-market-power-costs/



PROCESS_COAL_COMBUSTION
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




Coal plants are typically ~4000 MW ("nameplate" or total capacity).
https://en.wikipedia.org/wiki/List_of_coal-fired_power_stations


"The mining industry consumed an estimated 551 trillion British thermal units (Btu) in 2002."
https://www.energy.gov/eere/amo/mining-industry-profile

MANUFACTURING ENERGY CONSUMPTION SURVEY (MECS)
https://www.eia.gov/consumption/manufacturing/about.php
https://www.eia.gov/consumption/manufacturing/data/2018/

US 2010 Manufacturing consumed 18,358 trillion Btu (but this includes feedstock fuels)
Offsite fuel consumption by sector (in trillion Btu):
Chemicals:        3450
Petroleum & Coal: 1600 (refining! not drilling/mining)
Primary Metals:   1400  (refining! not mining)
Food:             1100
Paper:            1200

https://www.eia.gov/consumption/manufacturing/pdf/MECS%202018%20Results%20Flipbook.pdf

Detailed "offsite" energy usage by industry (but not mining!):
https://www.eia.gov/consumption/manufacturing/data/2018/pdf/Table4_1.pdf

Source for energy/t for gold, copper, nickle, iron:
https://www.ceecthefuture.org/resources/mining-energy-consumption-2021
Iron magnetite:
0.3 GJ/t ore(!)
41% mining
43% comminution
16% other processing
Iron hematite:
0.15 GJ/t ore(!)
90% mining
10% processing
Copper:
24 GJ/t final copper (average)
60% mining
36% comminution (grinding/milling)
4% other processing (smelting???)
Nickel (leach):
244 GJ/t final nickle (average)
59% mining
29% comminution
12% other processing
Lithium:
15 GJ/t hydroxide (I think)
48% mining
47% comminution
5% other processing
Gold (underground, higher grade):
130 GJ/kg unrefined gold bars
45% mining
26% comminution
29% other processing











