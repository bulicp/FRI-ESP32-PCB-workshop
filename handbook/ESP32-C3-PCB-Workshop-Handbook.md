# Build Your Own ESP32 Computer

## A KiCad PCB Design Handbook

### ESP32-C3-MINI-1 Development Board

### Workshop handbook ###
### Pa3cio, Faculty of Computer and Information Science, University of Ljubljana ###

---

> **How to use this handbook**
>
> These are not step-by-step instructions. During the workshop we draw everything together, and every step is explained as we go.
>
> This handbook is for *afterwards*: for the moment you sit in front of an empty project on your own and wonder why something was the way it was. It explains **why**, not **how**.
>
> Read it during or after the workshop, not before.

---

## 0. What we are building

A small development board, 35 × 48 mm, four copper layers, built around the **ESP32-C3-MINI-1-N4** module: a 32-bit RISC-V core at 160 MHz, 400 KB SRAM, 4 MB flash, Wi-Fi 4 and Bluetooth 5 LE.

| Block | Components |
|---|---|
| Power input | USB-C receptacle, LDO XC6220B331MR |
| Protection | USBLC6-2SC6 (data lines), PESD5V0L1ULD (VBUS) |
| The computer | ESP32-C3-MINI-1-N4 module |
| Control | RESET, BOOT and USER tactile switches |
| Indication | Green and yellow LEDs |
| Expansion | Two 1×8 headers exposing free GPIOs |

The design is deliberately restricted to **digital logic plus one linear regulator** — no RF matching network, no crystal, no external flash chip. All of that is already solved *inside* the module. That is precisely why we chose a module rather than the bare SoC: it lets first-time PCB designers concentrate on power distribution, decoupling, protection and layout discipline, without needing to understand RF design first.

The schematic is split across two sheets:

| Sheet | Contents |
|---|---|
| `power.kicad_sch` | USB-C connector, ESD protection, LDO regulator |
| `digital.kicad_sch` | ESP32-C3-MINI-1 module, LEDs, buttons, breakout headers |

Splitting a schematic into sheets is the same discipline as splitting a program into modules: one sheet, one job.

### Signal assignment

| Signal | Module pin | Note |
|---|---|---|
| `LED0` (green) | GPIO6 | **active LOW** |
| `LED1` (yellow) | GPIO7 | **active LOW** |
| `USER_BTN` | GPIO10 | active LOW |
| `USB_D−` | GPIO18 | native USB |
| `USB_D+` | GPIO19 | native USB |
| `TXD0` / `RXD0` | GPIO21 / GPIO20 | on header |
| `GPIO2_BOOT`, `GPIO8_BOOT`, `GPIO9_BOOT` | GPIO2, 8, 9 | strapping pins |
| `EN` | pin 8 | reset |
| `GPIO0`–`GPIO5` | — | free, on headers |

Note the naming convention: every strapping pin carries the `_BOOT` suffix directly in its net label. This is a good habit — anyone reading the schematic immediately knows *"this net affects boot behaviour, don't casually repurpose it."*

---

## 1. Vocabulary

You are computer scientists, not electrical engineers. These are the terms this handbook assumes, defined once.

| Term | Meaning |
|---|---|
| schematic | the logical design: what is connected to what |
| symbol | a component's graphical representation in the schematic |
| footprint | the physical copper pads on the board for one component |
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

---

## 2. The schematic

### 2.1 What a schematic is, and what it is not

A schematic is **not** a map of the board. It contains no distances, no sizes, no physics. It is a statement of connectivity: *this pin is connected to that pin.* Nothing more.

That is why the same schematic can be realised as a hundred different boards, all electrically identical — and only some of them will work. The difference between them is the subject of sections 4 and 5.

You make connections two ways:

- **with a wire** (`W`) — a visible line between pins,
- **with a label** (`L` for local, global for cross-sheet) — two pins carrying the same label are connected even though no line is drawn.

Use labels. A schematic with twenty crossing lines is unreadable; a schematic with labels like `SDA`, `LED0`, `GPIO9_BOOT` reads like code.

---

### 2.2 The power chain

```
USB-C  ──►  PESD (VBUS)  ──►  LDO 5 V→3.3 V  ──►  module
  │                                +3.3 V
  └── D+/D− ──► USBLC6 ────────────────────────►  GPIO19/GPIO18
```

The ESP32-C3-MINI-1 requires **3.3 V** and does **not** tolerate 5 V. At 5 V it is permanently destroyed. The regulator is therefore not a choice but a precondition.

---

### 2.3 The USB-C receptacle

![Input power and USB-C schematic sheet](images/schematic_inputpower_usb-c.png)

*The complete input-power sheet: the USB-C receptacle J1, the VBUS protection diode D1, the two CC resistors R1/R2, and the data-line protection IC U1.*

**What to look for in this drawing.** Three details on this one sheet are worth more attention than everything else on it:

1. **The connector symbol lists `D−` twice and `D+` twice** (pins A7/B7 and A6/B6), and in the drawing they are simply wired together. Section 2.4 explains why.
2. **`SBU1` and `SBU2` carry a blue ×** — the *no-connect* marker. This is not laziness; it is an explicit statement to ERC that leaving these pins unconnected is intentional. An unmarked floating pin is an ERC error; a marked one is documentation.
3. **`PWR_FLAG` sits on the VBUS net**, not on any component. Section 2.10 explains what it is for.

Also note the drawing hygiene: the protection components sit to the right of the connector, in the direction the signal travels. Signal flows left to right across the sheet, exactly as you read.

We use a **USB 2.0-only** 16-pin Type-C receptacle (GT-USB-7010ASV). A full USB-C connector has many pins because it supports cable flipping and USB 3.x, but since we only need USB 2.0 Full Speed, most of those pins are simply unused — the SuperSpeed lanes, SBU1 and SBU2.

The pins we do use:

| Pin function | Purpose |
|---|---|
| **VBUS** (×2, both orientations) | 5 V power in |
| **GND** (×2, plus shield) | return path |
| **CC1, CC2** | Configuration Channel — cable and orientation detection |
| **D+, D−** (×2, both orientations) | USB 2.0 data |

---

### 2.4 Why the receptacle has D+/D− in two places

This trips up almost everyone the first time.

It is not that we *choose* to duplicate the signal. The USB-C receptacle is **mechanically symmetric**, so it physically exposes two rows of contacts — the "A" row and the "B" row — and D+/D− exist at a specific position in *both* rows (A6/A7 and B6/B7), because that same physical position must make contact with the plug regardless of which way the cable is inserted.

Here is the part that resolves the confusion: the **plug** on the cable is built so that, *inside the plug itself*, pin A6 is permanently wired to B6, and A7 to B7. The cable's plug already ties the A-row and B-row data pins together internally, regardless of orientation. That is how a passive, reversible USB 2.0 cable works at all — the actual copper wires inside a basic cable carry only **one** physical D+/D− pair from end to end.

Because the plug already performs this bridging, it is standard, correct practice for **our receptacle-side PCB to mirror the same bridging** — tie A6↔B6 and A7↔B7 right at our connector. Whichever row ends up contacting the cable's real data wires (which depends entirely on insertion orientation, and is outside our control), the signal reaches the *same* board-side net.

This is why the digital sheet sees only **one** `USB_D+` and one `USB_D−` net, not four. We are doing exactly what the cable plug already does, on our side of the connection.

![USB-C footprint with CC resistors and ESD diode](images/layout_ESDdiode_51Kresistors_usbc.png)

*Close-up of the USB-C footprint on the board, with the two 5.1 kΩ CC resistors and the PESD VBUS diode placed immediately above it.*

**What to look for.** This image is the physical counterpart of the previous schematic, and reading them together is the whole point:

- Along the connector's contact row you can read the pad names directly: `B12 GND`, `A4 VBUS`, `A5 Net-(J1-CC1)`, `B7 D−`, `A6 D+`, `A7 D−`, `B6 D+`, `B5 Net-(J1-CC2)`, `A9 VBUS`, `A12 GND`. **The two D+ and two D− pads are physically visible here** — this is what section 2.4 is talking about, made concrete.
- The two CC pads carry *different* net names (`Net-(J1-CC1)` and `Net-(J1-CC2)`). They are never tied together. Each has its own resistor.
- The three components sit **directly above the connector, as close as the footprints allow.** Note how short the path from a connector pad to the protection diode is. This is not aesthetics; it is the whole purpose of the protection (section 2.6).
- The large oval pads at each end marked `SH GND` are the **shield** tabs. They are mechanical anchors as much as electrical ones: they take the force every time somebody yanks the cable. A USB connector without properly soldered shield tabs will eventually tear off the board.
- The thin cyan lines are the **ratsnest** — unrouted connections. This snapshot was taken during placement, before routing.

---

### 2.5 CC1 / CC2 — why exactly 5.1 kΩ

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


#### Other USB-C port roles

"Sink" is only one of several roles a USB-C port can take:

- **UFP** (Upstream-Facing Port) — the *data* role our board plays: a peripheral, as opposed to a host. Usually paired with being a power sink.
- **DFP** (Downstream-Facing Port) — the data role a host plays; on the power side a DFP is normally a **source** (Rp instead of Rd).
- **DRP** (Dual-Role Port) — a port, e.g. on a phone or laptop, that dynamically switches between source and sink by toggling its CC resistor between Rp and Rd until it detects what is on the other end. This is how a phone can both charge and power accessories through the same port.
- **VCONN source** — relevant only for *active* cables, which contain their own chip and need power on the cable's dedicated VCONN pin. Irrelevant for our passive connection.

Our board is deliberately the simplest possible case: a **fixed sink**, Rd only, never toggling.

---

### 2.6 ESD protection, twice

When you walk across a carpet to your board, you carry a charge whose voltage can exceed 10 kV in dry air. On contact it discharges within nanoseconds. A modern SoC's I/O pins are rated for a few volts beyond their operating range.

The connector is the one point on the entire board that is physically exposed to the outside world and to direct human contact. That is where protection belongs — and on our board it is doubled:

| Component | Protects |
|---|---|
| **U1 — USBLC6-2SC6** (SOT-23-6) | data lines D+ and D− |
| **D1 — PESD5V0L1ULD** (SOD-882D) | the VBUS power rail |

**Why two separate parts?** They protect different things with different requirements.

VBUS carries real current, up to 500 mA and more, and needs only modest clamping with no signal-integrity concerns. A simple unidirectional TVS diode is the right tool.

D+/D− carry a 12 Mbit/s differential signal and need extremely **low parasitic capacitance**, because any stray capacitance on a data line rounds off the signal edges. A generic power-rail TVS diode would be entirely unsuitable — it would protect the data lines and destroy the link at the same time. The USBLC6 is designed for exactly this: very low capacitance, two channels in one compact package. That is why it has six pins — two signals in, two signals out, plus supply and ground for the internal clamp reference.

**The placement rule, which returns in section 4: protection must be physically first on the signal path**, immediately after the connector. Protection placed halfway across the board is decoration — the surge has already done its work by the time it arrives.

---

### 2.7 The LDO regulator

![LDO schematic](images/schematic_LDO.png)

*The regulator sheet: VBUS in, +3.3 V out, with the enable pull-up R3 and the two compensation capacitors C1 and C2.*

**What to look for.** This is the smallest sheet in the project and the one with the most content per component:

- **`R3` (4.7 kΩ) pulls `CE` — chip enable — up to VBUS.** Without it, CE floats and the regulator may never turn on. A dead board with 0 V on the 3.3 V rail and a perfectly good regulator fitted is almost always a missing or wrong CE pull-up. The pull-up goes to **VBUS**, not to 3.3 V, for an obvious reason once you see it: 3.3 V does not exist until the regulator is enabled.
- **`C1` = 10 µF on the input, `C2` = 4.7 µF on the output.** These are not interchangeable and not guessed. Section 2.8 explains where they come from.
- Pin 4 is marked as unused. The regulator's `GND` pin sits on the symbol's bottom edge, so the ground path is drawn as a single clean node shared by both capacitors — the layout follows the drawing.
- The note in the corner — *"System rail (+3.3 V) is derived from VBUS via XC6220"* — is a text label, not a component. Free-text annotation of design intent costs nothing and is read by everyone who opens the file afterwards, including you in a year's time.

#### What an LDO is

A **low-dropout linear regulator** takes a higher input voltage and produces a clean, fixed, lower output by continuously "throwing away" the excess as heat across an internal pass transistor. It is the simplest possible way to get from USB's 5 V to the ESP32-C3's required 3.0–3.6 V: no inductors, no switching noise, no layout complexity — just two capacitors and the IC.

The price is efficiency:

```
P = (5 V − 3.3 V) × I
```

At 300 mA that is 0.51 W turned into heat. This is a non-issue at our current levels and board size, but it does mean the copper area around the regulator matters — that copper is its heatsink.

#### Why XC6220B331 and not AP2112K-3.3

We compared two very common 3.3 V LDOs before choosing:

| Parameter | XC6220B331 (chosen) | AP2112K-3.3 |
|---|---|---|
| Max output current | 1 A | 600 mA |
| Quiescent current | 8 µA | ~55 µA |
| Dropout voltage | 655 mV @ 1 A | 250 mV @ 600 mA |
| Package | SOT-25 | SOT-23-5 |

The deciding factor was **current headroom**. The ESP32-C3's Wi-Fi transmitter draws current in short but significant bursts — up to roughly 350 mA peak per the module datasheet. The AP2112K's 600 mA ceiling leaves comparatively little margin once LED and peripheral current is added on top. The XC6220B331's 1 A rating gives a much safer margin, at the cost of a slightly higher dropout voltage, which is irrelevant here since we have a full 5 V → 3.3 V budget. Its far lower quiescent current is a bonus if the board is ever battery-powered in a future revision.

This comparison is worth studying not for its conclusion but for its shape: **two candidates, four parameters, one deciding factor, one accepted trade-off.** That is what component selection looks like.

---

### 2.8 Regulator capacitors — do not improvise these values

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

---

### 2.9 The module and its decoupling

![ESP32-C3-MINI schematic](images/schematic_ESP32-C3-Mini.png)

*The module sheet: every signal leaves as a global label, and the supply pin carries two capacitors.*

**What to look for.** For a sheet holding the most complex component on the board, this drawing is strikingly plain — and that is the lesson:

- **The module has exactly one `3V3` pin (pin 3) and one `GND` pin in the symbol.** All the RF work, the crystal, the flash and the internal supply splitting happen inside the module, where we cannot see them and do not need to. This is the "module as a library" idea made visible.
- **`C6` (100 nF) and `C7` (10 µF) sit in parallel on that one supply pin.** Two capacitors, two jobs — section 2.9 below.
- Every I/O leaves as a **global label**, not a wire. The sheet has no crossing lines at all. Compare this with what the same circuit would look like drawn with wires.
- The pin names carry their alternate functions — `GPIO0/ADC1_CH0/XTAL_32K_P`. When you later wonder whether a pin can do ADC, the answer is already on your own schematic.
- Note which pins are *not* broken out. GPIO11–GPIO17 do not appear: on the ESP32-C3 they are used internally for the SPI flash. Pins you must not touch are best left off the drawing entirely.

#### First, a little physics: two components that resist change

Almost everything in this handbook about power delivery follows from two equations. They are worth ten minutes even if you have never studied electronics, because once you have them, decoupling stops being a rule you memorise and becomes something you can derive.

**A wire resists change in current.**

```
u = L · di/dt
```

A wire — and a PCB trace is a wire — has **inductance** *L*. The voltage that appears across it is proportional not to the current, but to how fast the current is **changing**.

Read what that means at the two extremes. If the current is steady, `di/dt = 0`, so `u = 0`: the wire behaves as though it were not there. A multimeter measuring a trace's resistance reads essentially zero, and it is telling the truth — about DC. But if the current changes abruptly, `di/dt` is enormous, and a voltage appears across that same piece of copper as though a resistor had suddenly materialised in the middle of it.

This "apparent resistance that depends on how fast things change" is not resistance. It is called **impedance**. The distinction matters: resistance is a fixed property of the material, while a trace's impedance grows with frequency — the faster the edge, the more the wire fights back.

How much? A rough figure for a PCB trace is about **1 nH per millimetre**. Take a 10 mm trace, so 10 nH, and a digital circuit that demands an extra 100 mA within a nanosecond as a block of logic switches:

```
u = 10 nH × (0.1 A / 1 ns) = 10×10⁻⁹ × 10⁸ = 1 V
```

**One volt**, dropped across a centimetre of copper, on a 3.3 V rail. Not measurable with a multimeter, because it lasts nanoseconds. Entirely sufficient to reset the chip.

**A capacitor resists change in voltage.**

```
i = C · du/dt
```

The mirror image. A capacitor stores energy as accumulated charge, and the current through it is proportional to how fast the voltage across it is **changing**.

Again, read the extremes. A constant voltage means `du/dt = 0`, so no current flows: to DC, a capacitor is an open circuit — a break in the wire. But the instant the voltage tries to move, current flows to oppose that movement. The faster the attempted change, the more current the capacitor delivers. Its impedance falls as frequency rises — the exact opposite behaviour to the inductor.

**Now put them together, and the whole thing falls out.**

The trace between the regulator and the chip is an inductance. When the chip demands a sudden burst of current, that inductance produces a voltage drop and the local supply sags. Now place a capacitor right at the chip's supply pin. The sag is a *change in voltage* — precisely what a capacitor opposes. It responds by delivering current locally, immediately, from the charge it holds, and the sag never fully develops.

> **L is the disease, C is the cure.** The inductance of the supply path is what makes fast current demands turn into voltage dips; the capacitance placed next to the load is what supplies those demands locally so the inductance is never asked to.

This is also why *proximity* is not a detail but the entire point. The capacitor helps only across the inductance that lies **between it and the chip**. Put it 2 mm away and it is fighting 2 nH; put it 20 mm away and it is fighting 20 nH, and it has become part of the problem it was meant to solve.

And it explains one more thing you will meet later in this handbook: whenever we say "use two vias in parallel," or "keep the return path directly underneath," or "never cut the ground plane," we are saying the same sentence in different words — **make L smaller.**

#### Why decoupling capacitors exist

Every IC draws current in short, fast pulses as its internal logic switches — not as a smooth, constant draw. If the power pin reached the regulator only through a long trace, that trace's own inductance would prevent the current from responding instantly, and the local supply voltage would sag for a few nanoseconds on every switching edge. That sag is invisible to a multimeter and entirely sufficient to reset a microcontroller or corrupt a Wi-Fi packet.

A **decoupling capacitor** sits right next to the power pin and acts as a local energy reservoir: it supplies those fast pulses locally, so the chip never waits for current to travel from the regulator.

#### One capacitor per VDD *pin*, not per IC

This is the rule most beginners get wrong, and it is worth stating precisely.

Many ICs expose *several separate* power pins — `VDDA`, `VDD3P3`, `VDD3P3_RTC`, `VDD3P3_CPU`, `VDD_SPI` — each feeding a different internal block. Each of these needs **its own local capacitor right next to it**, even though they are all nominally the same 3.3 V rail.

The reason is physical: a decoupling capacitor only helps the specific pin it is physically close to. The parasitic inductance of even a few millimetres of trace between two pins is enough that a capacitor sitting next to pin A does essentially nothing for the fast transients at pin B.

**On our board this rule is satisfied trivially, and that is worth understanding rather than glossing over.** The ESP32-C3-MINI-1 exposes a single `3V3` pin, because Espressif already did the per-pin decoupling *inside the module*, on the module's own tiny PCB. If you were designing with the bare ESP32-C3 SoC instead, you would be placing five or six capacitors around it, one per supply pin. The module bought you that work. When you design your next board around a bare IC, this rule will come back and it will not be trivial.

#### Why 100 nF specifically

It is a deliberately chosen sweet spot, not a convention:

- It must be **physically small enough** that its own parasitic series inductance (ESL, from the package and mounting pads) stays low. A physically smaller capacitor has a shorter internal current path, hence lower ESL, hence a higher self-resonant frequency — so it remains a low impedance up into the tens of MHz where fast digital switching edges live.
- It must be **large enough** to hold a meaningful amount of charge to supply during a transient.

100 nF in a small package lands in the middle of that trade-off, which is why virtually every digital IC datasheet recommends it as the default local value.

#### How far can the bulk capacitor sit?

`C7` (10 µF) has a different job. It is not reacting to nanosecond edges; it supplies the *slower*, larger current swings — an entire Wi-Fi transmit burst lasting microseconds to milliseconds — and smooths ripple at board level. Because it responds to a slower phenomenon, its placement is far less sensitive to trace inductance.

A good rule of thumb: **within roughly 1 cm of the pin or branch it serves is plenty.** It does not need to be millimetres away like the 100 nF, but it should not be on the opposite side of the board either. One bulk capacitor per power entry point or per cluster of ICs is normal; you do not need one per pin.

---

### 2.10 Buttons, strapping pins and the boot sequence

![Buttons and LEDs schematic](images/schematic_buttons_and_LEDs.png)

*Four functional blocks on one sheet: RESET, USER BUTTON, BOOT and USER LEDs.*

**What to look for.** This single image contains four of this handbook's most important ideas, and the grouping boxes are what make them legible:

- **RESET and USER BUTTON are electrically identical circuits** — 10 kΩ pull-up, 100 nF to ground, switch to ground. Only the net they drive differs: `EN` versus `USER_BTN`. One controls the chip's existence; the other is read by your program. Same electronics, entirely different meaning. This is worth sitting with.
- **The BOOT block contains three pull-ups but only one button.** `R6` and `R7` pull `GPIO2_BOOT` and `GPIO8_BOOT` high with nothing else attached; only `GPIO9_BOOT` gets a switch. Section 2.10 explains why GPIO9 is the one that matters.
- **`GPIO2_BOOT` and `GPIO8_BOOT` have no 100 nF capacitor**, while every pin with a button does. The capacitor is there for the *switch*, not for the pin — see the debounce discussion below. Circuits without a mechanical contact do not need it.
- **In the USER LEDs block, the resistor goes to +3.3 V and the GPIO drives the cathode.** Read that connection carefully, then read section 2.11.
- The four boxes cost nothing electrically and are worth a great deal in readability. A reader identifies "this is the boot circuit" at a glance without tracing a single wire.

#### RESET

The RESET button pulls the module's `EN` pin to ground. `EN` is the chip's power-on and reset control: pulling it low powers the chip down, releasing it restarts it. The datasheet is blunt about this pin:

> *"Do not leave the EN pin floating."*

Hence `R4`, 10 kΩ, holding it high by default so the chip runs normally unless the button is actively held.

#### BOOT and the strapping pins

`GPIO2_BOOT`, `GPIO8_BOOT` and `GPIO9_BOOT` are the three **strapping pins** the ROM bootloader samples *only during the reset pulse*, to decide how to boot. From the ESP32-C3-MINI-1 datasheet, Table 4-3:

| Boot mode | GPIO2 | GPIO8 | GPIO9 |
|---|---|---|---|
| **SPI Boot** (normal) | 1 | any | **1** |
| **Joint Download Boot** (flashing) | 1 | 1 | **0** |

> Datasheet note: *"GPIO2 actually does not determine SPI Boot and Joint Download Boot mode, but it is recommended to pull this pin up due to glitches."*

In other words: **GPIO9 is the pin that actually matters.** GPIO8 only matters once GPIO9 is already low, and GPIO2 is pulled up purely for glitch immunity. All three get 10 kΩ pull-ups so that, with no button pressed, the module always boots straight into your firmware.

#### Do you have to hold both buttons?

Not for the whole process — only at one specific instant. The strapping pins are sampled *once*, at the moment `EN` transitions from low back to high, subject to the datasheet's hold time (minimum 3 ms after `EN` goes high). The standard manual sequence is:

1. **Press and hold BOOT** — this pulls GPIO9 low.
2. **While still holding BOOT, press and release RESET** — `EN` goes low, then returns high through its pull-up. At the exact moment `EN` rises, the chip samples GPIO9 as low.
3. **Release BOOT.**

RESET only needs a brief pulse; you do not keep holding it. BOOT, however, must still be held at the moment RESET is released. Hence the familiar instruction: *hold BOOT, tap RESET, release BOOT.*

Many finished boards avoid this dance with an automatic reset circuit — extra transistors driven by a USB-serial adapter's DTR/RTS lines. Since we use the ESP32-C3's native USB and are keeping the circuit legible for teaching, our board uses the manual two-button method.

#### USER

An entirely ordinary GPIO input on GPIO10, with its own 10 kΩ pull-up. It has no meaning to the boot process; it is simply read by your application code. Electrically identical to the BOOT circuit, connected to a *non-strapping* pin.

> **A warning for later use of the board.** Because the strapping pins are also exposed on the headers, anything you connect to `GPIO2`, `GPIO8` or `GPIO9` that pulls them low at power-on will prevent the board from starting. This is the classic source of *"my board suddenly died"* — it did not die, it is booting into the wrong mode.

#### Why 100 nF next to the switches

Mechanical switches do not produce a single clean transition. The metal contacts physically bounce for a few milliseconds, producing a rapid train of spurious transitions — *contact bounce*. Without filtering, firmware can read one press as several.

A 100 nF capacitor from the GPIO node to ground forms an **RC low-pass filter** together with the 10 kΩ pull-up already on that line:

```
τ = R × C = 10 kΩ × 100 nF = 1 ms
```

This ~1 ms time constant smooths out the fast electrical noise of contact bounce while remaining far shorter than a human press (typically 50–200 ms), so the button does not feel sluggish. This is *hardware* debouncing; it complements, but does not replace, a short software debounce in firmware.

**What "time constant" actually means.** In an RC circuit the capacitor voltage does not jump instantly to its new value; it follows an exponential curve. τ = R × C is defined as the time taken to cover **63.2%** of the remaining distance to the final value. It is *not* the time to arrive. After one τ you are at 63.2%, after two τ at about 86%, and by convention a circuit is considered settled after about **5τ** (over 99%).

So in our filter, τ = 1 ms means: within about 1 ms of a clean edge the filtered voltage has moved 63% of the way, and within roughly 5 ms it has essentially settled — comfortably faster than a human press, slow enough to average out microsecond-scale contact glitches.

---

### 2.11 LEDs and the active-low trap

Both LEDs are wired **active LOW**: the anode goes through a resistor to +3.3 V, and the cathode connects to the GPIO. **The LED lights when the GPIO is driven to logic 0.**

```
+3.3 V ──[330 Ω]──▶|── GPIO
```

This is not a designer's whim. The output stages of most SoCs can *sink* more current than they can *source*, so this arrangement is the more reliable one.

For you as a programmer it means that writing a logic 1 will **turn the LED off**. Always hide the inversion behind a macro rather than remembering it:

```c
#define LED0        6    /* green  */
#define LED1        7    /* yellow */

#define LED_ON(pin)   gpio_set_level((pin), 0)
#define LED_OFF(pin)  gpio_set_level((pin), 1)
```

**Why 330 Ω?** From Ohm's law, with a typical LED forward voltage around 2.0–2.2 V:

```
I = (3.3 V − V_f) / R  ≈  (3.3 − 2.0) / 330  ≈  4 mA
```

Plenty bright for an indicator with modern LEDs, and comfortably below the ESP32-C3's per-pin limit. The chip can handle far more, but good practice keeps indicator LEDs in the low single-digit milliamps — it saves power and avoids stressing the output stage for no visible gain.

---

### 2.12 Breakout headers, and why the board is not a finished product

![Breakout headers J2 (power) and J3 (signals). The red crosses are
KiCad's marking for DNP (Do Not Populate) symbols.](images/pin-headers-schematic.png)

Two 8-pin headers (`Conn_01x08`, 2.54 mm pitch) bring the board's power
rails and all spare GPIOs out to the edge. This is a deliberate decision.
Without them the board would be a device that blinks two LEDs. With them
it is a **development board**: you can attach a sensor, a display, a relay
module, a logic analyser. When the workshop is over, the board remains
useful.

The 2.54 mm (0.1") pitch is the universal hobby standard: it fits
breadboards, perfboards, Dupont jumper wires and most sensor breakout
modules.

#### What is on the headers

J2 carries power only:

| J2 pin | Signal | Notes |
|---|---|---|
| 1, 8 | +3.3 V | output of the on-board LDO |
| 3, 4 | VBUS | 5 V straight from the USB connector |
| 5, 6 | GND | |
| 2, 7 | — | not connected |

J3 carries signals:

| J3 pin | Signal | Notes |
|---|---|---|
| 1 | TXD0 (GPIO21) | UART0 transmit |
| 2 | RXD0 (GPIO20) | UART0 receive |
| 3 | GND | |
| 4 | GPIO5 | digital only in practice (see below) |
| 5 | GPIO4 | ADC1 channel 4 |
| 6 | GPIO3 | ADC1 channel 3 |
| 7 | GPIO1 | ADC1 channel 1 |
| 8 | GPIO0 | ADC1 channel 0 |

The order of J3 is not accidental. TXD0, RXD0 and GND sit on three
adjacent pins, so a USB-to-serial adapter plugs onto pins 1–3 with a
single 3-way jumper cable.

#### Why these GPIOs and not others

The ESP32-C3 has three **strapping pins** (GPIO2, GPIO8 and GPIO9) whose
level at reset decides how the chip boots. A sensor or a relay module
that pulls one of them the wrong way at power-up can stop the board from
booting, or worse, briefly switch a relay while it starts. None of the
strapping pins is on the headers. The LEDs and buttons use the remaining
pins, and everything free and safe to use comes out on J3.

A few properties are worth knowing before you connect something:

- **GPIO0, GPIO1, GPIO3 and GPIO4** are ADC1 inputs, so use them for
  analogue sensors (potentiometers, photoresistors, analogue temperature
  sensors).
- **GPIO5** belongs to ADC2, which ESP-IDF does not support on the
  ESP32-C3. Treat it as a digital pin.
- **TXD0/RXD0** are UART0. The boot ROM prints its start-up messages on
  TXD0 at 115200 baud, so a device listening on that pin will receive
  some text at every reset. If you do not need the UART, both pins can
  be used as ordinary GPIOs.

#### Electrical limits

- **All signals are 3.3 V.** The ESP32-C3 is not 5 V tolerant. A 5 V
  module driving a GPIO will damage the chip over time or at once. Use a
  level shifter or a resistor divider.
- **VBUS is raw USB 5 V**, intended for 5 V peripherals such as relay
  modules or LED strips. It is limited by what the USB host provides,
  typically 500 mA for the whole board.
- **+3.3 V** comes from the same LDO that powers the ESP32-C3, whose
  Wi-Fi transmissions draw current peaks of a few hundred milliamps. Keep
  external 3.3 V loads modest (sensors, small displays) and power
  anything heavier from VBUS.
- **Never connect an external supply** to VBUS or +3.3 V while the board
  is plugged into USB. Two supplies fighting each other can back-feed the
  host's USB port or the LDO.

#### Why the headers are marked DNP

The red crosses in the schematic mean the symbols carry KiCad's
**DNP (Do Not Populate)** attribute. Their footprints are on the PCB, but
they are left out of the assembly BOM and placement file, so the
manufacturer does not fit them. You solder the headers yourself.

There are three reasons for this:

- **Choice.** You decide what to fit: straight male pins for a
  breadboard, angled pins, female sockets, or nothing at all if the
  board is going to be glued flat inside an enclosure.
- **Cost.** Through-hole parts are assembled separately from SMD parts
  and add to the price of every board.
- **Practice.** Soldering a 2.54 mm header is the easiest possible
  through-hole job, which makes it a good first soldering exercise.

---

### 2.13 Schematic grouping and PWR_FLAG

**Grouping.** You will have noticed that both sheets place related components inside visual boxes — one around the USB-C connector with its CC resistors and protection, another around the regulator and its capacitors, four around the button and LED circuits. This costs nothing electrically and is worth a great deal:

- a reader identifies a functional block at a glance, without tracing wires;
- it documents *design intent* — grouping tells the next person which components form one unit;
- it makes cross-checking a block against a datasheet's application circuit easy, one box at a time.

This is a habit worth carrying into every schematic you draw afterwards.

**PWR_FLAG.** The power sheet contains `PWR_FLAG` symbols. These are not real components; they exist purely for ERC. ERC expects every power net to be *driven* by a pin explicitly marked as a power output — a regulator's output pin, for instance. But a net like `VBUS`, which originates at a plain connector pin (electrically just "passive" as far as KiCad's pin-type system is concerned), has no such driver, so without a flag ERC would report *"power net has no driver"* as an error.

Placing a `PWR_FLAG` is you telling ERC explicitly: *this net is genuinely powered from outside the schematic — a cable, a battery, a connector — stop warning me.*

---

### 2.14 ERC

`Inspect → Electrical Rules Checker`

ERC does not check whether your circuit will work. It checks the schematic's **internal consistency**, independent of any physical layout:

- two outputs driving the same net — a short circuit waiting to happen;
- an input pin left entirely unconnected;
- a power net with no driving source (exactly what `PWR_FLAG` resolves);
- pins of mismatched types connected in a way that is likely a mistake.

| Message | Meaning | Fix |
|---|---|---|
| *Input Power pin not driven by Output Power pin* | the `+3.3V` net has no source | add `PWR_FLAG` at the regulator output |
| *Pin not connected* | a pin is floating | connect it, or mark it no-connect (`Q`) |

**Run ERC before you begin layout.** Fixing a wiring mistake in the schematic takes thirty seconds; discovering the same mistake after half the board is routed is a different afternoon entirely.

The workshop rule: **zero ERC errors** before moving to layout. Warnings should be reviewed individually — some are genuinely benign, such as an intentionally unconnected pin — but never wave away an error you do not understand.

---

## 3. Footprints and board outline

### 3.1 Footprints: where logic meets physics

A symbol has no size. A footprint does. Every component must be assigned one — the actual pattern of copper pads it will be soldered to.

`Tools → Assign Footprints`

> **Warning.** A wrong footprint is the most expensive mistake in this project. Once the boards are made, it cannot be fixed. Check every footprint against the dimensions in the datasheet, especially the regulator, the ESD parts and the USB-C connector.

The USB-C connector deserves particular care: the footprint must match **exactly the connector you will buy** (here GT-USB-7010ASV). USB-C receptacles from different manufacturers are not interchangeable, despite looking identical from the outside.

### 3.2 Package sizes: 0402 vs 0603 vs 0805

| Package | Metric | Size (L×W) | Hand-solderable? | Notes |
|---|---|---|---|---|
| 0402 | 1005 | 1.0 × 0.5 mm | difficult for beginners | preferred for machine assembly; easy to lose, hard to probe by hand |
| 0603 | 1608 | 1.6 × 0.8 mm | manageable with practice | good middle ground |
| 0805 | 2012 | 2.0 × 1.25 mm | **comfortable by hand** | large pads, easy to inspect visually, still compact |

**On this board the resistors are 0402 and the capacitors and LEDs are 0805.** That mix is not an oversight — it reflects the intended assembly method. The boards are machine-assembled at the fabricator, where 0402 is entirely routine and takes less space.

If your own next board is to be **hand-soldered**, revisit this before ordering: move the resistors up to 0603 or 0805 so you are not fighting 1.0 × 0.5 mm parts with a soldering iron.

This is the real lesson: **the intended assembly method should drive footprint choice**, not a vague preference for "smaller is more modern."

### 3.3 Board outline

The outline is drawn on the `Edge.Cuts` layer. The board will be cut along that line. Ours is **34.9 × 48.5 mm**.

Recommendations: rounded corners with a 1–2 mm radius, since sharp corners chip; the USB-C connector at the edge, aligned with the outline; mounting holes ⌀3.2 mm for M3 screws, at least 5 mm from the edge.

---

## 4. Layers and placement

### 4.1 Placement strategy

![Complete board placement](images/layout_board.png)

*The whole board with all footprints placed and nothing routed yet — the state at the end of placement.*

**What to look for.** This is the single most informative image in the handbook, because it shows the board at the moment when every decision has been made and nothing has been committed:

- **The hatched red band across the top is the antenna keepout.** The module sits with its antenna hanging over the board edge, and no copper — on any layer — is permitted in that region. Everything else on the board was arranged around this constraint, not the other way round.
- **The two 1×8 headers run down the left and right edges**, as far apart as the board allows. That is what makes the board breadboard-friendly and it is a mechanical decision taken before any electrical one.
- **The USB-C connector sits centred on the bottom edge**, with the power cluster — protection, regulator, capacitors — immediately above it. Power flows bottom to top; the module sits at the top. The signal path across the physical board mirrors the signal path across the schematic.
- **RESET is at bottom left, BOOT at bottom right**, both reachable while the board is plugged in and both far enough apart that you can press them with two fingers. Try holding BOOT and tapping RESET on a board where they are 5 mm apart and you will understand why.
- **The ratsnest lines fan out from the module in all directions.** Their number and length is your placement feedback: long crossing lines mean components in the wrong place. Fix that here, not with clever routing later.
- Small capacitors sit tucked immediately beside the pins they serve, not tidily lined up along an edge. Tidiness is not the goal; proximity is.

Work in this order:

1. **Fixed components** — the USB-C connector at the edge, mounting holes, headers along the edges, LEDs and buttons where the user can reach them.
2. **The module** — antenna at the board edge, no copper beneath it in *any* layer.
3. **The power chain** — protection immediately at the connector, then the regulator, then its capacitors.
4. **Decoupling capacitors** — each right beside its supply pin, typically under 2 mm. These go before any other routing consideration.
5. **Everything else.**

The guiding principle throughout: **components should follow the path of the signal.** If the signal travels left to right in the schematic, let it travel left to right on the board. A board that looks like its schematic routes almost by itself.

![Power cluster close-up](images/layout_USB-c-and-power.png)

*The power cluster: connector, ESD protection, regulator and capacitors, in the order the current travels.*

**What to look for.** This is placement principle 3 made concrete, and it repays close reading:

- **Trace the physical order upward from the connector**: USB-C pads → CC resistors and the VBUS diode → the USBLC6 (right) and the LDO (left) → the regulator's capacitors. Current enters at the bottom and leaves at the top as +3.3 V. Nothing doubles back.
- **The USBLC6 is placed with its three input pads facing the connector and its three output pads facing away.** Signal enters one side and leaves the other; the part is not rotated arbitrarily. Rotating it 180° would work electrically and would lengthen every trace.
- **The LDO's pads are readable in this view**: `1 VBUS`, `2 GND`, `3 Net-(U2-CE)`, `4` unused, `5 +3.3V`. Compare this against the schematic in section 2.7 — the same five pins, the same connections, now with physical positions attached. Learning to move between these two views fluently is most of what PCB design is.
- **The two capacitors sit on opposite sides of the regulator**, input capacitor near pin 1, output capacitor near pin 5. Neither is more than a couple of millimetres from the pin it serves, exactly as the datasheet's layout note requires.
- The short grey stubs already drawn at some pads are **fanout traces** — the first, deliberate connections from pad to via, placed during placement rather than routing. Getting power pins onto their plane early makes the rest of the routing simpler.

![Module and user peripherals close-up](images/layout_ESP32_userbutton_LEDs.png)

*The module footprint with its decoupling capacitors, the two LEDs, and the user button.*

**What to look for.** This close-up is where the decoupling discussion of section 2.9 becomes physical:

- **The nine large pads marked `49 GND` in the centre** are the module's thermal and ground pad array. They are not decorative: every one of them wants a via straight down to the ground plane. That array is the module's main return path.
- **The two 0805 capacitors at the upper left connect `+3.3V` to `GND`** and sit as close to the module's supply pin as the footprint permits. That distance is the whole point — a few millimetres further and their inductance would begin to matter.
- **The pads around the module's edges carry their net names**, so you can read the pinout directly off the layout: `GPIO2_BOOT`, `GPIO3`, `EN`, `USB_D+`, `USB_D−`, `LED0`, `LED1`, `USER_BTN`, `TXD0`, `RXD0`. Pads marked `x` are deliberately unused.
- **The LEDs sit side by side with their series resistors immediately below**, each pair forming an obvious visual unit. Physical grouping of functionally related parts makes a board readable in the same way that schematic grouping does.
- **The user button is placed well clear of the module**, with room around it for a finger. Ergonomics is a layout constraint like any other.
- Note again the hatched keepout at the top and the complete absence of anything beneath the antenna.

---

### 4.2 Why four layers

![Four-layer PCB stackup](images/stackup_4layer.jpg)

*The classic four-layer arrangement: signals outside, planes inside.*

**What to look for.** The exploded view makes visible what is otherwise buried inside 1.6 mm of fibreglass:

- **The two inner layers are solid sheets, not traces.** That is the entire difference between a two-layer and a four-layer board. Layers 2 and 3 are not "more room for routing" — they are continuous copper, and their value comes precisely from being uninterrupted.
- **The vertical copper barrels are vias**, passing through the whole stack. Note how a via touches every layer it passes through: this is why an unassigned via sitting inside a pour causes a DRC clearance error, and why a via on the `+3.3V` net automatically joins the power plane without you routing anything.
- **Layer 2 (GND) sits directly beneath layer 1.** The dielectric between them is thin, typically a few tenths of a millimetre. Every trace on the top layer therefore has its return path a fraction of a millimetre below it. That short vertical distance is what makes the current loop small — the inductance argument from section 2.9, now in three dimensions.
- The generic diagram labels layer 3 as a single 3.3 V plane. **Ours is slightly different:** `In2.Cu` carries *two* separate islands, `VBUS` before the regulator and `+3.3V` after it, on that same physical layer. Section 4.3 explains how they coexist without touching.

| Layer | Our board |
|---|---|
| `F.Cu` (1) | components and signals |
| `In1.Cu` (2) | **solid GND plane** |
| `In2.Cu` (3) | power islands: `VBUS` and `+3.3V` |
| `B.Cu` (4) | signals, GND pour |

#### Two layers versus four

On a two-layer board there are no inner layers at all: everything — signals, power, ground — shares the top and bottom copper. Ground becomes a patchwork of hand-drawn traces and poured fragments, threaded between whatever else needed to get across the board.

| | Two layers | Four layers |
|---|---|---|
| Ground | traces and fragmented pours, routed by hand | one continuous plane |
| Return path | wherever copper happens to be — often a long detour | directly beneath every trace |
| Loop area, hence L | large and unpredictable | small and consistent |
| Power distribution | narrow, meandering traces | a wide, low-impedance plane |
| Routing space | congested; power and ground consume it | freed up, since power and ground moved inside |
| EMI | radiates more, picks up more | substantially better |
| Cost | cheaper | more expensive, though not dramatically at small sizes |

Every line in the right-hand column is the same physics from section 2.9. A continuous plane gives every signal a return path immediately underneath, so the loop the current traces is small, so *L* is small. A poured plane distributes power with far lower resistance and inductance than any trace of practical width. And "never cut the ground plane" means: do not force a return current to detour, because a detour is added loop area, which is added inductance.

#### And yet: this board would work on two layers

It is worth being honest about this rather than pretending otherwise.

Our board has around thirty components and perhaps forty nets. The fastest signal on it is USB Full Speed at 12 Mbit/s — genuinely slow by modern standards. A competent designer could route this on two layers and it would work.

**We chose four layers anyway, for two reasons.**

The first is technical, and modest. The board carries a Wi-Fi radio and a differential pair. Both benefit from a clean ground reference, and both are exactly the kind of thing that behaves *almost* correctly on a compromised ground plane — the failure mode is not a dead board but reduced range or occasional enumeration failures, which are miserable to diagnose. Given the choice, we removed the variable.

The second reason is the honest one: **you are here to learn.**

Four-layer stackups, ground planes, power islands, and via stitching are standard practice on essentially every real embedded board you will encounter afterwards. If you learn them here — on a small, forgiving board with thirty components, where a mistake costs nothing and the design is simple enough to hold in your head — you will already know them when you meet a board where they are not optional. Learning to lay out a ground plane for the first time on a complex, dense, fast board is a much worse experience.

So the fourth layer is partly for the signals and partly for you. That is a legitimate engineering decision when the project is a workshop, and it is worth recognising it as a decision rather than mistaking it for a technical necessity. Knowing *which* of your design choices are forced and which are chosen is itself part of the craft.

Four layers buy two things we need at 160 MHz next to a radio.

**First: the return path.** Current flowing along a signal trace must return somewhere. It returns through ground — and not by the shortest geometric route, but by the route of lowest inductance, which at high frequency means **directly beneath the signal trace**. If `In1.Cu` is a solid, uninterrupted ground plane, every signal has a return path immediately below it. The loop the current traces is small. A small loop means little radiation and little susceptibility to interference.

**Second: cutting the ground plane destroys exactly that.** A signal trace routed through the ground layer creates a slot. Every signal crossing that slot must route its return current around the obstruction, and the loop grows by the size of the detour.

> This is why `In1.Cu` carries no signal traces. None.

Power lives on the separate layer `In2.Cu`, divided into islands: 5 V before the regulator, 3.3 V after it. The islands never touch — the regulator is what lies between them.

### 4.3 Two islands on one layer, and zone priority

Rather than routing VBUS and +3.3 V as traces, we pour them as **copper zones** directly on `In2.Cu`:

1. Draw a zone on `In2.Cu`, assign it net **VBUS**. It only needs to span the short path from the connector through the protection diode to the regulator input.
2. Draw a **second, separate** zone on the **same layer**, assign it net **+3.3V**, and pour it across the rest of the board.
3. KiCad keeps them apart according to your clearance rule — two independent copper islands on the same physical layer, never touching.

**What if the two outlines overlap when you draw them?** This is what **zone priority** is for. Every zone has a priority value, an integer defaulting to 0. When two zones on the same layer overlap, KiCad fills the **higher-priority** zone first, then fills the lower-priority zone everywhere *except* inside the higher-priority zone's area plus clearance. The lower-priority copper is carved away automatically.

So give the small `VBUS` island a **higher** priority (say 1) than the large `+3.3V` pour (0). Even if you sketch the `+3.3V` outline roughly across the whole board, KiCad keeps `VBUS` intact and clears 3.3 V copper away from it — no pixel-perfect hand-drawing required.

Double-click a zone outline, or right-click → **Zone Properties**, to find the Priority field. Recent KiCad versions also have a **Zone Manager** panel listing every zone with its layer, net and priority side by side, which is far easier once a board has several overlapping pours.

### 4.4 Connecting pins to inner layers with vias

A via is a plated hole connecting copper on different layers. To connect, say, the regulator's output pad on `F.Cu` down to the `+3.3V` island on `In2.Cu`:

1. Place a via on that net, at or immediately beside the pad.
2. The via barrel is plated copper running through the board, touching every layer it passes. It connects automatically to the zone on `In2.Cu` whose net matches.
3. For power pins — regulator output, VBUS input — use **more than one via in parallel.** This lowers the connection's resistance and inductance and adds redundancy.

Two vias in parallel have roughly half the inductance of one, three have roughly a third. Given `u = L·di/dt` from section 2.9, halving *L* halves the voltage that appears across that connection during a current burst. This is the cheapest improvement available anywhere on a board: one extra via, no extra components, no extra cost.

For GND this matters even more: every ground pad on `F.Cu` should drop a via straight down to `In1.Cu` right at the pad, so return current has the shortest possible path home. The module's central ground array in the image above is the clearest example on the board.

---

## 5. Routing

### 5.1 Net classes

Not all connections are equal. Power carries current and needs wider traces; USB is a differential pair with its own rules; ordinary GPIO is undemanding.

`Board Setup → Design Rules → Net Classes`

| Class | Nets | Track width | Clearance |
|---|---|---|---|
| **Default** | GPIO, buttons, LEDs | 0.25 mm | 0.2 mm |
| **POWER** | `VBUS`, `+3.3V`, `GND` | 0.4 mm | 0.2 mm |
| **USB** | `USB_D+`, `USB_D−` | 0.2 mm, pair gap 0.25 mm | 0.2 mm |

Global minimums, checked by DRC regardless of class: track 0.15 mm, via 0.7 mm with 0.4 mm drill, copper-to-board-edge 0.5 mm. These are chosen so that any four-layer fabricator, including the cheapest, can build the board without a query.

Think of net classes as *what I want by default*, and the Constraints tab as *the hard floor I never want to cross by accident.*

Once classes are configured, the router applies the correct width automatically. No manual switching, no forgotten thin power traces.

### 5.2 Differential pair routing

USB does not travel on one wire but two: `D+` and `D−` carry the same information in opposite phase, and the receiver looks at the **difference** between them. Interference that strikes both traces equally cancels in the subtraction.

For that to work the traces must be:

- **equal in length** — otherwise the signals are no longer in phase;
- **routed in parallel** at a constant separation;
- **over uninterrupted ground** — no slots in `In1.Cu` beneath them;
- **free of unnecessary vias** — each via is a discontinuity.

In KiCad:

1. **Name the nets so KiCad recognises the pair.** KiCad auto-detects pairs from matching suffixes — `+`/`−` or `_P`/`_N`. Our `USB_D+` / `USB_D−` already qualify.
2. **Set the pair's width and gap** in the net class.
3. **Route both traces together** with the differential pair router (hotkey `6`). KiCad draws both simultaneously, holding the gap and mitring corners symmetrically.
4. **Match lengths afterwards if needed** — `Route → Tune Differential Pair Skew` adds small meanders to equalise them.

> **A mitigating circumstance.** USB 2.0 Full Speed at 12 Mbit/s is relatively forgiving, and the path on our board is short. Respect the rules, but do not be paralysed by them — this is not USB 3.0 at 5 Gbit/s, and matching within a few millimetres is more than sufficient here.

### 5.3 Routing order

1. Power from the regulator to the module.
2. Traces from each decoupling capacitor to its supply pin — these should be the shortest on the whole board.
3. The USB differential pair.
4. Everything else.

### 5.4 Pours and stitching vias

Pour GND zones on `F.Cu` and `B.Cu` across the free area, excluding the antenna keepout. Then distribute **stitching vias** across the board to tie the pours on different layers together, so return current anywhere on the board finds a short path to the ground plane.

### 5.5 DRC

`Inspect → Design Rules Checker`

DRC checks physics: clearances, whether every schematic connection has actually been routed, whether anything crosses the board outline. Typical findings include traces closer than your clearance setting, drills below your minimum, unrouted ratsnest lines, and net mismatches inside zones — for example a via left without a net assignment sitting inside a same-named pour, which KiCad correctly reports as a clearance violation because it sees the via as electrically unrelated to the copper around it.

**Run DRC repeatedly while routing**, not once at the end. Catching a problem three traces after you made it is far easier than after the board is finished.

Routing is not done when it looks good. It is done when DRC reports **zero violations and zero unrouted connections**. A board with unresolved DRC errors should never be ordered.

If you find a violation you do not understand, click it — the tool takes you to the exact location. Every message means something specific.

---

## 6. Manufacturing outputs

### 6.1 What the fabricator receives

Not your KiCad project, but:

| Files | Contents |
|---|---|
| Gerber (`.gbr`) | each layer separately: copper, mask, silkscreen, outline |
| Drill (`.drl`) | position and diameter of every hole |
| BOM (`.csv`) | which components, and how many |
| CPL / Pick&Place (`.csv`) | position and rotation of every component |

Gerber is an old, textual and surprisingly simple format — essentially a list of *"move here, draw this"* commands. Open one in a text editor; it is worth seeing what you actually send.

### 6.2 Export

`File → Fabrication Outputs → Gerbers`

Export `F.Cu`, `In1.Cu`, `In2.Cu`, `B.Cu`, `F.Mask`, `B.Mask`, `F.Silkscreen`, `B.Silkscreen`, `F.Paste`, `B.Paste`, `Edge.Cuts`. Then `Generate Drill Files`.

### 6.3 Look at what you are sending

**Never send Gerbers you have not viewed.** Open them in a viewer — GerbView ships with KiCad — and check layer by layer:

- is the outline closed?
- is the ground plane genuinely continuous?
- does the silkscreen cover any solder pads?
- is there any copper under the antenna?
- are all the holes where they should be?

This is the equivalent of reading your code before committing it. It takes ten minutes and saves three weeks of waiting for the wrong board.

### 6.4 The BOM

A BOM is not merely a list. For assembly, every line must identify **one and only one** component — hence the catalogue numbers alongside the values. "10 µF" says nothing about voltage rating, dielectric or package. A catalogue number says everything.

> **Check particularly** the components whose polarity or orientation is not obvious: LEDs, protection diodes, the regulator, the connector. A part fitted backwards is not the fabricator's mistake if that is how you submitted it.

### 6.5 DFM: talking to the fabricator

Every fabricator has its own limits: minimum track width, minimum clearance, minimum via diameter, minimum annular ring. You need these numbers **before** routing, not after.

| Criterion | What to compare |
|---|---|
| price | the bare board, separately from assembly |
| lead time | days to weeks |
| DFM limits | whether your rules fit inside theirs |
| assembly | whether they stock the parts or you supply them |
| four-layer surcharge | with some vendors, substantially more than two-layer |

---

## 7. Bringing the board up

### 7.1 Before plugging in USB

A faulty board can damage the USB port on your computer.

1. **Visual inspection** — all components present, correctly oriented, no solder bridges. Look particularly at the USB-C connector and the module.
2. **Ohmmeter check** — resistance between `+3.3V` and `GND`, and between `VBUS` and `GND`. If either is close to zero, you have a short. **Do not plug it in.**
3. Only then, USB.

### 7.2 Sequence

1. The board appears as a serial device (`/dev/cu.usbmodem*` on macOS).
2. Confirm the chip responds and is indeed an ESP32-C3.
3. Upload a program.
4. The LED blinks.

When it blinks, you have reached the goal: a program running on a RISC-V core, on a board you drew yourself.

> **A consequence worth remembering.** Because the board has no CP2102 or CH340 converter — the ESP32-C3's USB controller is built in and connected directly to GPIO18/19 — the port appears differently from most development boards. On macOS it is `/dev/cu.usbmodem*`, not `/dev/ttyUSB0`. A great many online tutorials specify `/dev/ttyUSB0`; those are written for boards with a converter chip and will mislead you.

Instructions for installing the toolchain are provided separately.

### 7.3 First program

```c
#define LED0        6    /* green  */
#define LED1        7    /* yellow */
#define USER_BTN   10

#define LED_ON(pin)   gpio_set_level((pin), 0)   /* active low! */
#define LED_OFF(pin)  gpio_set_level((pin), 1)
```

Sensible first exercises on your own board:

1. Alternate the two LEDs.
2. Read the button, with debouncing.
3. Connect anything at all to the headers. From here the board is yours.

---

## Appendix A: Common mistakes

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
| loaded strapping pin | board will not start | mind what you attach to GPIO2/8/9 |
| silkscreen over pads | poor solder joints at assembly | set `min_silk_clearance` and run DRC |

---

## Appendix B: How to select a capacitor

Beyond the nominal value, three parameters matter.

### B.1 Capacitance

Match the value called for by the datasheet or your calculation. Going *higher* is usually safe for bulk and decoupling capacitors; going *lower* than a specified value can break stability, as with the LDO in section 2.8.

### B.2 Voltage rating — and why to derate

Always choose a rated voltage **comfortably above** the actual working voltage; a good rule of thumb is **at least 2×**.

This matters because of an effect specific to ceramic capacitors called **DC bias derating**: their *effective* capacitance under real DC voltage is measurably lower than the nominal, zero-volt rating — and the closer the working voltage is to the rated voltage, the worse it gets.

A 10 µF part rated at 6.3 V, used on a 5 V rail, may deliver noticeably less than 10 µF in practice. The same nominal 10 µF rated at 16 V, on that same 5 V rail, stays much closer to its printed value. This is why our 5 V and 3.3 V rails specify **16 V** parts even though the circuit never exceeds 5 V.

### B.3 Dielectric class

| Dielectric | Stability | Typical use |
|---|---|---|
| **C0G / NP0** | extremely stable, ~0 ppm/°C | precision analogue, timing, RF |
| **X7R** | good, ±15% over −55 to +125 °C | **recommended default** |
| **X5R** | good, ±15% over −55 to +85 °C | very common, narrower range |
| **Y5V / Z5U** | poor, −80% / +22% swing | avoid where capacitance matters |

Every capacitor on this board is X5R or X7R. Avoid Y5V and Z5U even though they are often the cheapest option; the swing under temperature and bias can be severe enough to undermine exactly the stability the capacitor is there to provide.

### B.4 Checklist before adding a part to the BOM

1. Capacitance meets or exceeds the requirement
2. Voltage rating ≥ 2× the working voltage
3. Dielectric is X5R or X7R
4. Package matches the intended assembly method

---

## Appendix C: Bill of materials

| Ref(s) | Qty | Value / Part | Package | LCSC | Purpose |
|---|---|---|---|---|---|
| U3 | 1 | ESP32-C3-MINI-1-N4 | module | C2838502 | RISC-V Wi-Fi/BLE module, 4 MB flash |
| U2 | 1 | XC6220B331MR | SOT-23-5 | C22466451 | 3.3 V, 1 A LDO |
| U1 | 1 | USBLC6-2SC6 | SOT-23-6 | C7519 | USB data-line ESD protection |
| D1 | 1 | PESD5V0L1ULD | SOD-882D | C552557 | VBUS ESD protection |
| J1 | 1 | GT-USB-7010ASV | USB-C 16P | C2988369 | USB-C power and data |
| J2, J3 | 2 | Conn_01x08 | 2.54 mm THT | — | GPIO / UART breakout |
| BOOT1, RESET1, USER1 | 3 | B3U-1000P-B | SMD tactile | C231330 | boot / reset / user switches |
| D2 | 1 | LED green | 0805 | C2297 | `LED0`, GPIO6 |
| D3 | 1 | LED yellow | 0805 | C2296 | `LED1`, GPIO7 |
| C1 | 1 | 10 µF | 0805 | C15850 | LDO input capacitor (C<sub>IN</sub>) |
| C2 | 1 | 4.7 µF | 0805 | C597439 | LDO output capacitor (C<sub>L</sub>) |
| C7 | 1 | 10 µF | 0805 | C15850 | module bulk capacitance |
| C6 | 1 | 100 nF | 0805 | C380332 | module decoupling |
| C3, C4, C5 | 3 | 100 nF | 0805 | C380332 | RC debounce for RESET, BOOT, USER |
| R1, R2 | 2 | 5.1 kΩ | 0402 | C2907044 | USB-C CC1/CC2 sink resistors |
| R3 | 1 | 4.7 kΩ | 0402 | C105871 | LDO `CE` pull-up |
| R4 | 1 | 10 kΩ | 0402 | C60490 | `EN` pull-up |
| R5, R6, R7 | 3 | 10 kΩ | 0402 | C60490 | strapping pull-ups: GPIO9, GPIO2, GPIO8 |
| R8 | 1 | 10 kΩ | 0402 | C60490 | `USER_BTN` pull-up |
| R9, R10 | 2 | 330 Ω | 0402 | C105875 | LED series resistors |

---

## Appendix D: Where to go next

- **I²C sensors** — `GPIO4` and `GPIO5` are on the header. I²C is open-collector: devices can only pull the line low, so the bus needs pull-up resistors, typically 4.7 kΩ. A digital temperature or pressure sensor is the natural next step.
- **CAN bus** — the ESP32-C3 has a TWAI controller, compatible with CAN 2.0. With an external transceiver the board can talk to automotive and industrial equipment.
- **Current measurement** — a sense resistor and some measurement, to see what transmitting over Wi-Fi actually costs.
- **Your own revision of this board** — you learn most from the second one. Add whatever you found missing.

---

## Appendix E: Reference material

| Document | Source |
|---|---|
| ESP32-C3-MINI-1 & MINI-1U Datasheet v2.2 | Espressif — pinout, boot configuration, land pattern |
| ESP32-C3 Technical Reference Manual | Espressif |
| ESP Hardware Design Guidelines — PCB Layout | Espressif — stackup and power-plane principles |
| XC6220 series datasheet | Torex — the C<sub>IN</sub>/C<sub>L</sub> compensation table |
| USBLC6-2SC6 datasheet | STMicroelectronics |
| PESD5V0L1ULD datasheet | Nexperia |
| KiCad documentation | docs.kicad.org |


---

### KiCad PCB Design Workshop ###
### Faculty of Computer and Information Science, University of Ljubljana ###
### Pa3cio ###
