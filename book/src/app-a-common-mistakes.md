# Appendix A: Common mistakes

| Mistake | Symptom | Prevention |
|---|---|---|
| missing 5.1 kΩ CC resistors | board completely dead, 0 V on VBUS | check it in the schematic |
| one decoupling capacitor per IC | random resets, instability | one capacitor per **supply pin** |
| copper under the antenna | very short Wi-Fi range | keepout on every layer |
| ground plane cut by a trace | interference, USB problems | no signal traces on `In1.Cu` |
| wrong USB-C footprint | connector does not fit | footprint for the exact part purchased |
| forgotten LED inversion | LED on when it should be off | `LED_ON` / `LED_OFF` macros |
| regulator capacitors chosen by feel | oscillation on the 3.3 V rail | values from the datasheet table |
| missing CE pull-up | regulator dead, 0 V out | CE must be held high |
| loaded strapping pin | board will not start | keep GPIO2/8/9 off the headers, as on this board |
| silkscreen over pads | poor solder joints at assembly | set `min_silk_clearance` and run DRC |
