# 1. Vocabulary

You are computer scientists, not electrical engineers. These are the terms this handbook assumes, defined once.

| Term | Meaning |
|---|---|
| schematic | the logical design: what is connected to what |
| symbol | a component's graphical representation in the schematic |
| footprint | the physical copper pads on the board for one component |
| package | the physical housing of a component and its terminals (section 3.2) |
| THT / SMT | through-hole and surface-mount: leads through holes, or pads on the surface |
| pitch | the centre-to-centre distance between neighbouring pins |
| net | a set of pins that are electrically connected |
| net class | a group of nets sharing rules (width, clearance) |
| track / trace | a copper connection on the board |
| via | a plated hole connecting copper on different layers |
| pour / zone | a large copper area, usually GND |
| stackup | what is on which layer, and how thick |
| silkscreen | the printed white text and outlines |
| solder mask | the green protective coating |
| ERC | Electrical Rules Checker — schematic-level checking |
| DRC | Design Rules Checker — board-level checking |
| Gerber | the standard file format sent to the fabricator |
| BOM | Bill of Materials — the component list for purchasing |
| decoupling capacitor | a capacitor placed at a power pin |
| differential pair | two traces carrying the same signal in opposite phase |
| fanout | the short stub and via from a pad down to an inner plane; with planes, this is how power and ground pins are connected |
