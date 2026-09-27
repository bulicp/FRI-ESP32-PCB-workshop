# 5.2 Differential pair routing

USB does not travel on one wire but two: `D+` and `D−` carry the same information in opposite phase, and the receiver looks at the **difference** between them. Interference that strikes both traces equally cancels in the subtraction.

For that to work the traces must be:

- **equal in length** — otherwise the signals are no longer in phase;
- **routed in parallel** at a constant separation;
- **over uninterrupted ground** — no slots in `In1.Cu` beneath them;
- **free of unnecessary vias** — each via is a discontinuity.

In KiCad:

1. **Name the nets so KiCad recognises the pair.** KiCad auto-detects pairs from matching suffixes — `+`/`-` or `_P`/`_N`. Our `USB_D+` / `USB_D-` already qualify. Type the minus as a plain ASCII hyphen. This handbook prints it as a typographic minus (−) for readability, but KiCad matches the character literally, and a pasted `−` produces a net the pair router will not recognise.
2. **Set the pair's width and gap** in the net class.
3. **Route both traces together** with the differential pair router (hotkey `6`). KiCad draws both simultaneously, holding the gap and mitring corners symmetrically.
4. **Match lengths afterwards if needed** — `Route → Tune Differential Pair Skew` adds small meanders to equalise them.

> **A mitigating circumstance.** USB 2.0 Full Speed at 12 Mbit/s is relatively forgiving, and the path on our board is short. Respect the rules, but do not be paralysed by them — this is not USB 3.0 at 5 Gbit/s, and matching within a few millimetres is more than sufficient here.
