# B.3 Dielectric class

| Dielectric | Stability | Typical use |
|---|---|---|
| **C0G / NP0** | extremely stable, ~0 ppm/°C | precision analogue, timing, RF |
| **X7R** | good, ±15% over −55 to +125 °C | **recommended default** |
| **X5R** | good, ±15% over −55 to +85 °C | very common, narrower range |
| **Y5V / Z5U** | poor, −80% / +22% swing | avoid where capacitance matters |

Every capacitor on this board is X5R or X7R. Avoid Y5V and Z5U even though they are often the cheapest option; the swing under temperature and bias can be severe enough to undermine exactly the stability the capacitor is there to provide.
