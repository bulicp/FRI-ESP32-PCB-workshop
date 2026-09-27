# 2.13 Schematic grouping and PWR_FLAG

**Grouping.** You will have noticed that both sheets place related components inside visual boxes — one around the USB-C connector with its CC resistors and protection, another around the regulator and its capacitors, four around the button and LED circuits. This costs nothing electrically and is worth a great deal:

- a reader identifies a functional block at a glance, without tracing wires;
- it documents *design intent* — grouping tells the next person which components form one unit;
- it makes cross-checking a block against a datasheet's application circuit easy, one box at a time.

This is a habit worth carrying into every schematic you draw afterwards.

**PWR_FLAG.** The power sheet contains `PWR_FLAG` symbols. These are not real components; they exist purely for ERC. ERC expects every power net to be *driven* by a pin explicitly marked as a power output — a regulator's output pin, for instance. But a net like `VBUS`, which originates at a plain connector pin (electrically just "passive" as far as KiCad's pin-type system is concerned), has no such driver, so without a flag ERC would report *"power net has no driver"* as an error.

Placing a `PWR_FLAG` is you telling ERC explicitly: *this net is genuinely powered from outside the schematic — a cable, a battery, a connector — stop warning me.*
