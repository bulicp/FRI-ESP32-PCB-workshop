# 2.5 CC1 / CC2 — why exactly 5.1 kΩ

USB-C decides *whether* to power a cable, *which way round* the plug is,
and *how much current* is on offer, using nothing more than resistors on
the two CC lines. Both ends measure the CC voltage, but for different reasons.

![CC divider: the source's Rp and our board's Rd meet on the single CC wire.
The source measures to detect attachment and orientation; the sink may measure
to learn the advertised current.](images/usb-c-cc-divider.svg)

*Further reading: Texas Instruments, "USB Type-C Configuration Channel (CC)
Controller Selection Guide", SDAA284, March 2026.*

The **source** (host, charger) pulls CC up through a resistor **Rp**. The
**sink** (our board) pulls CC down to GND through **Rd = 5.1 kΩ**, a value
fixed by the specification. The two form a voltage divider.

**What the source measures — "is anyone there?"**
A USB-C source keeps VBUS switched *off* until it sees a valid Rd on one of
its CC pins. It distinguishes three cases: open (nothing attached), Rd (a
sink, so VBUS is enabled) and Ra ≈ 1 kΩ (an e-marked cable or audio
adapter, not a sink). The pin on which Rd appears also tells the source the
plug orientation.

**What the sink measures — "how much may I draw?"**
The source advertises its current capability by its choice of Rp. It does
not adjust anything for the sink. A sink that cares measures the voltage
across its own Rd:

| Source Rp (to 5 V) | CC voltage across 5.1 kΩ | Sink band | Sink may draw |
|---|---|---|---|
| 56 kΩ | ≈ 0.42 V | 0.20 – 0.66 V | default (500/900 mA) |
| 22 kΩ | ≈ 0.94 V | 0.66 – 1.23 V | 1.5 A |
| 10 kΩ | ≈ 1.69 V | 1.23 – 2.04 V | 3.0 A |
| — | < 0.20 V | — | no source attached |

Our board never reads CC: the ESP32-C3 draws far less than 500 mA, so the
advertised current is irrelevant to us. **On our board the resistors exist
for one reason only: so that the source recognises a sink and turns VBUS on.**

**Without them, VBUS never appears on a USB-C ↔ USB-C cable.** The board
stays dead and looks exactly like a faulty chip. This is the most common
first-board failure. Confusingly, the same board *works* with a USB-A → C
cable, because that cable has Rp built in and USB-A always supplies VBUS.

Use two separate resistors, one per CC pin, and never tie CC1 and CC2
together. Only one CC pin meets the cable's CC wire (depending on
orientation). Our board has Rd on both CC pins, but the cable carries only one CC wire,
so at any moment only one of them is actually connected to the source's Rp.
The source sees Rd on one of its own CC pins and nothing on the other;
which one tells it how the plug sits in *its* receptacle. Our board sees
the same thing from its side: one CC pin at the divider voltage, the other
at 0 V. Flip the plug and the two pins swap roles, which is exactly why
both Rd resistors must be fitted.


## Other USB-C port roles

"Sink" is only one of several roles a USB-C port can take:

- **UFP** (Upstream-Facing Port) — the *data* role our board plays: a peripheral, as opposed to a host. Usually paired with being a power sink.
- **DFP** (Downstream-Facing Port) — the data role a host plays; on the power side a DFP is normally a **source** (Rp instead of Rd).
- **DRP** (Dual-Role Port) — a port, e.g. on a phone or laptop, that dynamically switches between source and sink by toggling its CC resistor between Rp and Rd until it detects what is on the other end. This is how a phone can both charge and power accessories through the same port.
- **VCONN source** — relevant only for *active* cables, which contain their own chip and need power on the cable's dedicated VCONN pin. Irrelevant for our passive connection.

Our board is deliberately the simplest possible case: a **fixed sink**, Rd only, never toggling.
