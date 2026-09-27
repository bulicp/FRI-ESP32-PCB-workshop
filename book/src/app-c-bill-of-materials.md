# Appendix C: Bill of materials

Part data checked against LCSC/JLCPCB in September 2026. Stock changes
weekly: always check availability before ordering.

| Ref(s) | Qty | Value / Part | Package | LCSC | Purpose | Key specifications | A substitute must have |
|---|---|---|---|---|---|---|---|
| U3 | 1 | ESP32-C3-MINI-1-N4 | module 13.2 × 16.6 mm | C2838502 | RISC-V Wi-Fi/BLE module, 4 MB flash | 3.0–3.6 V supply, up to 350 mA during Wi-Fi TX, PCB antenna, −40…85 °C | Same footprint: only the ESP32-C3-MINI-1 family (e.g. the 105 °C variant ESP32-C3-MINI-1-H4). Any other module needs a new footprint. |
| U2 | 1 | XC6220B331MR (TDSEMIC) ⚠ | SOT-23-5 (SOT-25) | C22466451 | 3.3 V, 1 A LDO | 3.3 V out, 1 A, V<sub>IN</sub> 1.6–6 V, dropout 655 mV at 1 A, CE enable pin, over-current and thermal protection | Same pinout (1 VIN, 2 GND, 3 CE, 4 NC, 5 VOUT), 3.3 V, ≥ 500 mA, V<sub>IN</sub> max ≥ 6 V, stable with ceramic capacitors. Re-check C1 and C2 against its datasheet. |
| U1 | 1 | USBLC6-2SC6 | SOT-23-6 | C7519 | USB data-line ESD protection | 2 lines, V<sub>RWM</sub> 5.25 V, V<sub>BR</sub> 6 V, clamp 17 V, 3.5 pF per line, IEC 61000-4-2 | Same pinout (I/O on 1/3/4/6, GND 2, VBUS 5), line capacitance ≤ 5 pF for USB Full Speed. |
| D1 | 1 | PESD5V0L1ULD,315 ⚠ | DFN1006D-2 (SOD-882D) | C552557 | VBUS ESD protection | Unidirectional, 5 V working voltage, 12 V clamp, 3.5 A (8/20 µs) | Unidirectional, V<sub>RWM</sub> 5–5.5 V (lower leaks on VBUS), same 1006 footprint, cathode on VBUS. Low capacitance is not needed on VBUS. |
| J1 | 1 | GT-USB-7010ASV | USB-C 16P, SMD | C2988369 | USB-C power and data | USB 2.0 receptacle, 16 pins, right angle, 3 A, 24 V, 10 000 cycles, shell pegs through-hole | Not a drop-in part: any other 16-pin receptacle needs its own footprint. Compare pad and peg positions. |
| J2, J3 | 2 | Conn_01x08 | 2.54 mm THT | — | GPIO / UART breakout (DNP) | 1 × 8 pin header, 2.54 mm pitch | Any 2.54 mm header: straight, angled or female. |
| BOOT1, RESET1, USER1 | 3 | B3U-1000P-B | SMD 3.0 × 2.5 mm | C231330 | boot / reset / user switches | SPST-NO, 12 V / 50 mA, 1.6 mm high, 153 gf actuation | Same footprint, including the locating boss of the "-B" variant. |
| D2 | 1 | KT-0805G, green | 0805 | C2297 | `LED0`, GPIO6 | Emerald green, 525 nm, V<sub>F</sub> 2.6–3.1 V | Any 0805 LED. A lower V<sub>F</sub> gives more current through R9: recompute R = (3.3 V − V<sub>F</sub>) / I. |
| D3 | 1 | KT-0805Y, yellow | 0805 | C2296 | `LED1`, GPIO7 | Yellow, ≈ 590 nm, V<sub>F</sub> 1.8–2.4 V | Any 0805 LED; same resistor rule as D2. |
| C1 | 1 | 10 µF | 0805 | C15850 | LDO input capacitor (C<sub>IN</sub>) | Samsung CL21A106KAYNNNE: 25 V, X5R, ±10 % | ≥ 10 µF, X5R or X7R, **≥ 16 V** (it sits on 5 V, and DC bias reduces the real capacitance). |
| C2 | 1 | 4.7 µF | 0805 | C597439 ⚠ | LDO output capacitor (C<sub>L</sub>) | not verified, see notes | 4.7 µF, X5R or X7R, ≥ 10 V, value per the regulator's datasheet table. |
| C7 | 1 | 10 µF | 0805 | C15850 | module bulk capacitance | as C1 | ≥ 10 µF, X5R or X7R, ≥ 10 V. |
| C6 | 1 | 100 nF | 0805 | C49678 ⚠ | module decoupling | Yageo CC0805KRX7R9BB104: 50 V, X7R, ±10 % | 100 nF, X7R (or X5R), ≥ 10 V. |
| C3, C4, C5 | 3 | 100 nF | 0805 | C49678 ⚠ | RC debounce for RESET, BOOT, USER | as C6 | 100 nF, X7R or X5R, ≥ 10 V. |
| R1, R2 | 2 | 5.1 kΩ | 0402 | C25905 ⚠ | USB-C CC1/CC2 sink resistors | UNI-ROYAL 0402WGF5101TCE: ±1 %, 62.5 mW, thick film | 5.1 kΩ, ±1 % or ±5 %, 0402. |
| R3 | 1 | 4.7 kΩ | 0402 | C105871 | LDO `CE` pull-up | Yageo RC0402FR-074K7L: ±1 %, 62.5 mW, 50 V | Any 0402 resistor of this value, ±1 % or ±5 %. |
| R4 | 1 | 10 kΩ | 0402 | C60490 | `EN` pull-up | Yageo RC0402FR-0710KL: ±1 %, 62.5 mW, 50 V | as R3 |
| R5, R6, R7 | 3 | 10 kΩ | 0402 | C60490 | strapping pull-ups: GPIO9, GPIO2, GPIO8 | as R4 | as R3 |
| R8 | 1 | 10 kΩ | 0402 | C60490 | `USER_BTN` pull-up | as R4 | as R3 |
| R9, R10 | 2 | 330 Ω | 0402 | C105875 | LED series resistors | Yageo RC0402FR-07330RL: ±1 %, 62.5 mW | as R3; adjust the value if you change the LEDs. |

**Notes on the entries marked ⚠**

- **C3–C6: LCSC code corrected.** The earlier code C380332 is a
  **10 µF**, 16 V, X5R capacitor, not 100 nF. Fitted by an assembler, it
  would have made the RC debounce and EN delay a hundred times slower and
  replaced the module's 100 nF decoupling capacitor with a second bulk
  capacitor. C49678 is a 100 nF, 50 V, X7R part in 0805. Correct the LCSC
  field in the KiCad symbols too, or the exported BOM will still carry the
  old code.
- **R1, R2: LCSC code corrected.** The earlier code C2907044 is a 5.1 kΩ
  resistor in **0603**, while the footprint is 0402. C25905 is the same
  value in 0402.
- **U2** is a TDSEMIC part carrying the Torex name XC6220B331MR. The
  capacitor requirements in section 2.7 come from the **Torex** datasheet
  (XC6220B331MR-G, LCSC C86534). If you use the TDSEMIC version, check
  its own datasheet for the input and output capacitor requirements.
- **D1** was out of stock at LCSC when this BOM was checked. Use the
  substitute rule in the table.
- **C2 (C597439)** could not be verified against LCSC. Check the part
  page before ordering and make sure it is a 4.7 µF X5R or X7R ceramic
  capacitor in 0805, rated at least 10 V.

**General rules for substitutes**

- **The footprint decides first.** A substitute must fit the same
  footprint: 0402 is not 0603, and SOT-23-5 regulators with a different
  pin order do not work even though they fit.
- **Ceramic capacitors: X5R or X7R, never Y5V or Z5U.** Y5V and Z5U lose
  most of their capacitance with temperature and DC voltage.
- **Voltage rating: at least twice the working voltage** for capacitors
  of a few µF. A 10 µF capacitor rated 6.3 V on a 5 V rail may deliver
  only a fraction of its nominal value, because of DC bias.
- **Resistors are the easiest**: any thick-film resistor of the same
  value and size, ±1 % or ±5 %, rated at least 1/16 W.
- **Check the manufacturer's datasheet**, not only the distributor's
  summary line. Clones and second sources sometimes share a part number
  but not every specification.
