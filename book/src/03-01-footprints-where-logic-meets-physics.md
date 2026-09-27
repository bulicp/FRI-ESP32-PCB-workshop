# 3.1 Footprints: where logic meets physics

A symbol has no size. A footprint does. Every component must be assigned one — the actual pattern of copper pads it will be soldered to.

`Tools → Assign Footprints`

> **Warning.** A wrong footprint is the most expensive mistake in this project. Once the boards are made, it cannot be fixed. Check every footprint against the dimensions in the datasheet, especially the regulator, the ESD parts and the USB-C connector.

The USB-C connector deserves particular care: the footprint must match **exactly the connector you will buy** (here GT-USB-7010ASV). USB-C receptacles from different manufacturers are not interchangeable, despite looking identical from the outside.
