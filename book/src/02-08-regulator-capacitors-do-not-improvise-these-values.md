# 2.8 Regulator capacitors — do not improvise these values

The XC6220 series requires a *specific, tested* combination of input capacitor (C<sub>IN</sub>) and output capacitor (C<sub>L</sub>) for **phase compensation**. The output capacitor is not a filter that you can size by feel — it is **part of the regulation loop**. Its capacitance and internal resistance (ESR) determine whether the loop is stable or whether the regulator oscillates and delivers something other than DC on its output.

The datasheet is explicit:

> *"The values needed for phase compensation are shown in the table below. If there is a loss of capacitance, a stable phase compensation might not be achieved."*

Torex's recommended table for the 3.00–3.50 V output versions, which includes our part:

| C<sub>IN</sub> | C<sub>L</sub> |
|---|---|
| 4.7 µF | 47 µF |
| **10 µF** | **4.7 µF** |
| 22 µF | 4.7 µF |

Our board uses **C1 = 10 µF, C2 = 4.7 µF** — the middle row, a directly tested combination.

What is **not** safe is deviating downward: picking a small C<sub>IN</sub> without scaling C<sub>L</sub> up to the required 47 µF, or using a symmetric 4.7 µF / 4.7 µF pair, which sits in a gap the datasheet never tested and can reduce the loop's phase margin.

> **Rule for the workshop:** always start from a documented, tested capacitor pair in the datasheet. If you deviate, deviate only by *increasing* capacitance, never by decreasing it below a tested value.

Both capacitors go as physically close as possible to the VIN and VOUT pins, per the datasheet's own layout note.
