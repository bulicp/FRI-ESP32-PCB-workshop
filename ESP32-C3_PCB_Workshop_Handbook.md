# ESP32-C3-MINI-1 Custom PCB — Workshop Handbook

*A student guide to designing, laying out, and verifying a breadboard-compatible ESP32-C3-MINI-1 development board in KiCad.*

---

## 0. What We Are Building

Over this workshop we design a small, breadboard-compatible development board built around the **ESP32-C3-MINI-1** Wi-Fi/BLE module (RISC-V core). The board is powered from **USB-C**, regulated down to 3.3 V, and exposes:

- Two status LEDs (green, yellow)
- A user button
- BOOT and RESET buttons for firmware flashing
- Two 1×8 breadboard-compatible headers exposing all free GPIOs

The design is deliberately kept to **digital logic + one linear regulator** — no RF matching, no crystal, no external flash — because all of that is already solved for us *inside* the ESP32-C3-MINI-1 module. This is exactly why we chose a module instead of the bare SoC: it lets first-time PCB designers focus on power distribution, decoupling, protection, and layout discipline, without needing to understand RF design.

The schematic is split into two sheets:

| Sheet | Contents |
|---|---|
| `power.kicad_sch` | USB-C connector, ESD protection, LDO regulator |
| `digital.kicad_sch` | ESP32-C3-MINI-1 module, LEDs, buttons, breakout headers |

---

## 1. The Digital Section

### 1.1 Net overview

The digital sheet carries the following named nets to and from the module:

| Net name | Module pin | Purpose |
|---|---|---|
| `EN` | EN (pin 8) | Chip enable / reset |
| `GPIO0` … `GPIO5` | IO0–IO5 | General-purpose I/O, broken out to headers |
| `GPIO2_BOOT`, `GPIO8_BOOT`, `GPIO9_BOOT` | IO2, IO8, IO9 | Strapping pins — control boot mode |
| `USER_BTN` | free GPIO | User push button input |
| `LED0`, `LED1` | free GPIOs | Green / yellow status LEDs |
| `RXD0`, `TXD0` | IO20/IO21 | UART0 console, broken out to header J3 |
| `USB_D+`, `USB_D-` | IO19/IO18 | Native USB (flashing + JTAG debug) |

Note the naming convention: any strapping pin is suffixed `_BOOT` directly in the net label. This is a good habit — anyone reading the schematic instantly knows "this net affects boot behaviour, don't casually repurpose it."

### 1.2 Why we need decoupling capacitors

Every IC (the ESP32-C3 module included) draws current in short, fast pulses as its internal logic switches state — not as a smooth, constant draw. If the power pin were connected to the regulator only through a long trace, the trace's own inductance would prevent the current from responding instantly, so the local supply voltage would sag for a few nanoseconds every time the chip switches. That tiny sag is invisible to a multimeter, but it is enough to reset a microcontroller or corrupt a Wi-Fi packet.

A **decoupling capacitor** sits right next to the IC's power pin and acts as a tiny local energy reservoir: it supplies those fast current pulses locally, so the chip never has to "wait" for current to arrive all the way from the regulator. This is why decoupling capacitors:

- Are always **100 nF (0.1 µF)** ceramic, placed as physically close to the power pin as possible (a few mm at most)
- Sit in **parallel** with any larger bulk capacitor on the same rail
- Are needed at *every* IC — not just once per board

In our design, `C3`–`C6` (four × 100 nF, 0805) are the decoupling capacitors for the digital section, placed near the module's power pin and near the push-button circuits (see §1.4).

**One capacitor per VDD *pin*, not per IC.** Many ICs — including the ESP32-C3 itself, once you look at the module's internal reference schematic — actually expose *several separate* power pins (e.g. `VDDA`, `VDD3P3`, `VDD3P3_RTC`, `VDD3P3_CPU`, `VDD_SPI`), each feeding a different internal block. Each of these pins needs its **own local decoupling capacitor right next to it**, even if they're all nominally "the same 3.3 V rail." The reason is that a decoupling cap only helps the specific pin it's physically close to — the parasitic inductance of the trace between two pins (even a few mm of PCB trace) is enough that a cap sitting next to pin A does essentially nothing for the fast current transients happening at pin B. This is why the ESP32-C3-MINI-1 module datasheet's own reference schematic shows *multiple* decoupling capacitors scattered around the module footprint, not one shared capacitor for the whole chip.

**Why always 100 nF specifically?** It's a deliberately chosen sweet spot, not an arbitrary habit:

- It needs to be **small enough** (physically) that its own parasitic series inductance (ESL, coming from the package and the mounting pads/vias) stays low — a physically smaller capacitor has a shorter internal current path, hence lower ESL, hence a higher self-resonant frequency, hence it stays effective (looks like a low impedance) up into the tens-of-MHz range where fast digital switching edges live.
- It needs to be **large enough** to actually hold a meaningful amount of charge to supply during a switching transient.
- 100 nF in a small package (0402/0603/0805) happens to land right in the middle of that trade-off, which is why virtually every digital IC datasheet recommends it as the default local decoupling value — it's become a de facto industry standard for exactly this reason, not just convention.

**How far can the larger bulk capacitor (the 1 µF/10 µF one) sit from the VDD pin?** Unlike the 100 nF cap, the bulk capacitor's job is different: it's not reacting to nanosecond-scale switching edges, it's supplying the *slower*, larger-scale current swings (e.g. an entire Wi-Fi TX burst lasting microseconds to milliseconds) and smoothing out ripple at the board/branch level. Because it's responding to a slower phenomenon, its placement is far less sensitive to trace inductance. A good rule of thumb: **within roughly 1 cm of the pin/branch it serves is plenty** — it doesn't need to be millimeters away like the 100 nF cap, but it also shouldn't be on the opposite side of the board. One bulk capacitor per power *entry point* or per cluster of ICs on a branch is normal; you don't need one per pin the way you do for 100 nF decoupling.

### 1.3 LEDs (D2, D3)

| Ref | Colour | LCSC | Package | Series resistor |
|---|---|---|---|---|
| D2 | Green | C2297 | 0805 | R9, 330 Ω |
| D3 | Yellow | C2296 | 0805 | R10, 330 Ω |

Each LED is driven directly from a GPIO through a current-limiting resistor to GND:

```
GPIO ──[330Ω]──▶|── GND
```

**Why 330 Ω?** Using the standard LED equation:

$$I = \frac{V_{GPIO} - V_f}{R}$$

At 3.3 V logic and a typical LED forward voltage of ~2.0–2.2 V, 330 Ω gives roughly 3–4 mA — plenty bright for an indicator LED, while staying well under the ESP32-C3's per-pin drive limit (the chip can source up to ~40 mA, but good practice keeps indicator LEDs in the low single-digit mA range to save power and avoid unnecessary heating).

### 1.4 Buttons: BOOT, RESET, and USER — and why they are different

The board has **three** identical SMD tactile switches (`BOOT1`, `RESET1`, `USER1` — Omron B3U-1000P-B, LCSC C231330), but they serve three conceptually different roles.

#### RESET (EN)

Pulls the module's `EN` pin to GND. `EN` is the chip's power-on/reset control — pulling it low powers the chip off; releasing it restarts it. Per the datasheet:

> *"Do not leave the EN pin floating."*

This is why `EN` always has a pull-up resistor (part of R4–R8, 10 kΩ) holding it HIGH by default, so the chip runs normally unless the RESET button is actively held.

**Do you have to hold BOOT and RESET at the same time?** Not for the entire process — only at one specific instant. The strapping pins are sampled *once*, right when `EN` transitions from LOW back to HIGH (i.e. the moment the chip comes out of reset), per the datasheet's *hold time* (`t_H`, minimum 3 ms after `EN` goes high). The standard manual flashing sequence is:

1. **Press and hold BOOT** (pulls GPIO9 low)
2. **While still holding BOOT, press and release RESET** (this pulls `EN` low, then lets it go back high through the pull-up — the chip resets and, at the exact moment `EN` rises, samples GPIO9 as LOW)
3. **Release BOOT**

You do *not* need to keep holding RESET — RESET only needs a brief pulse. BOOT, however, must still be held at the moment RESET is released (i.e. at the moment `EN` rises), which is why the usual instruction is "hold BOOT, tap RESET, then let go of BOOT." Many finished boards avoid this dance entirely with an automatic reset circuit (extra transistors driven by the USB-serial adapter's DTR/RTS lines) — but since we're using the ESP32-C3's native USB, and keeping the circuit simple for teaching purposes, our board uses the manual two-button method.

#### BOOT (strapping pins)

`GPIO2_BOOT`, `GPIO8_BOOT`, and `GPIO9_BOOT` are the three **strapping pins** that the ROM bootloader samples *only during the reset pulse* to decide how to boot. From the ESP32-C3-MINI-1 datasheet, Table 4-3, *Chip Boot Mode Control*:

| Boot Mode | GPIO2 | GPIO8 | GPIO9 |
|---|---|---|---|
| **SPI Boot mode** (normal) | 1 | any value | **1** |
| **Joint Download Boot mode** (flashing) | 1 | 1 | **0** |

> Note (from the datasheet): *"GPIO2 actually does not determine SPI Boot and Joint Download Boot mode, but it is recommended to pull this pin up due to glitches."*

In other words: **GPIO9 is the pin that actually matters**, GPIO8 only matters when GPIO9 is already low, and GPIO2 is pulled up purely for glitch immunity. All three get 10 kΩ pull-ups (part of R4–R8) so that, by default (no button pressed), the module always boots straight into your firmware — **SPI Boot mode**.

Holding the BOOT button pulls GPIO9 to GND. If you then pulse RESET while BOOT is still held, the chip samples GPIO9 = LOW at the moment EN goes high, and enters **Joint Download Boot mode** — which, per the datasheet, *"supports the following download methods: USB-Serial-JTAG Download Boot, UART Download Boot."* This is the mode your flashing tool (`esptool.py`, Arduino IDE, `idf.py flash`) needs in order to write new firmware.

#### USER (USER_BTN)

A completely ordinary GPIO input, with its own 10 kΩ pull-up, wired to a free GPIO (`USER_BTN`). It has no special meaning to the chip's boot process — it is simply read in your application code (`digitalRead()` / `gpio_get_level()`), e.g. to trigger an action or cycle through LED states. It is electrically identical to the BOOT circuit, just connected to a *non-strapping* pin.

### 1.5 Why 100 nF next to the switches

You'll notice small 100 nF capacitors placed near the button circuits. Mechanical switches don't produce a single, clean transition from HIGH to LOW — the metal contacts physically bounce for a few milliseconds, producing a rapid train of spurious transitions ("contact bounce"). Without filtering, firmware could misread one button press as several.

A 100 nF capacitor from the GPIO node to GND forms a simple **RC low-pass filter** together with the 10 kΩ pull-up resistor already on that line:

$$\tau = R \times C = 10\text{k}\Omega \times 100\text{nF} = 1\text{ms}$$

This ~1 ms time constant is enough to smooth out the fast electrical noise of contact bounce, while still being far shorter than a human button press (typically 50–200 ms), so it doesn't make the button feel sluggish. This is a *hardware* debounce; it complements (but does not replace) a short software debounce delay in firmware, which is good practice regardless.

**What does "time constant" (τ) actually mean?** In an RC circuit, the voltage across the capacitor doesn't jump instantly to its new value — it follows an exponential curve. The time constant τ = R×C is defined as **the time it takes the voltage to cover 63.2% of the remaining distance to its final value** (when charging from 0 toward some target voltage), or equivalently, to fall to 36.8% of its starting value (when discharging toward 0). It is *not* the time to fully reach the final value — after one τ you're at 63.2%, after two τ you're at ~86%, and by convention a circuit is considered to have "settled" after about **5τ** (>99% of the way there). So in our button-filter example, τ = 1 ms means: within about 1 ms of a clean edge appearing on the line, the filtered voltage has moved 63% of the way toward that new level, and within ~5 ms it's essentially fully settled — comfortably faster than a human press/release, but slow enough to average out the microsecond-scale glitches from contact bounce.

### 1.6 Breakout headers (J2, J3)

Two `Conn_01x08`, 2.54 mm pitch, THT vertical headers. As established earlier, they are placed **15.24 mm (0.6″)** apart, center-to-center — six standard breadboard grid steps — so the board straddles the breadboard's central trough exactly like an Arduino Nano does, leaving one row of holes free on each side for jumper wires.

---

## 2. The Power Section

### 2.1 USB-C receptacle (J1)

We use a **USB 2.0-only** 16-pin Type-C receptacle (GT-USB-7010ASV, LCSC C2988369). A full USB-C connector has many pins because it supports cable-flip (either orientation works) and USB 3.x — but since we only need USB 2.0 Full-Speed, most of those pins are simply unused (SuperSpeed TX/RX lanes, SBU1/SBU2). The pins we *do* use:

| Pin function | Purpose |
|---|---|
| **VBUS** (×2, both orientations) | 5 V power in |
| **GND** (×2, both orientations + shield) | Return path |
| **CC1, CC2** | Configuration Channel — cable/orientation detection |
| **D+, D−** (×2, both orientations) | USB 2.0 data |

#### Why does the receptacle even have D+/D− pins in two places?

This trips up almost everyone the first time. It's not that we *choose* to duplicate the signal — the USB-C **receptacle itself is mechanically symmetric**, so it physically exposes two rows of contacts (the "A" row and the "B" row), and D+/D− exist at a specific position in *both* rows (A6/A7 and B6/B7), because that same physical position has to make contact with the plug regardless of which way it's inserted.

Here's the part that actually resolves the confusion: the **plug** on the cable (the part on the other end from our connector) is built so that, *inside the plug itself*, pin A6 is permanently wired to pin B6, and A7 to B7. In other words, the cable's plug already ties the "A-row" and "B-row" D+/D− together, internally, regardless of orientation — that's how a passive, reversible USB 2.0-over-Type-C cable is able to work at all, since the actual copper wires inside a basic cable only carry *one* physical D+/D− pair from end to end.

Because the plug already performs this bridging, it is standard, correct design practice for **our own receptacle-side PCB to mirror that same bridging** — tie A6↔B6 together, and A7↔B7 together, right at our connector. That way, no matter which of the two rows ends up actually contacting the cable's D+/D− wires (which depends entirely on insertion orientation, and is out of our control), the signal reaches the *same* board-side net either way. This is why the digital sheet only sees **one** `USB_D+` and one `USB_D-` net, not four — we're doing exactly what the cable plug already does, just on our side of the connection.

#### CC1 / CC2 — why exactly 5.1 kΩ (R1, R2)

USB-C uses the CC lines for power/role negotiation through a simple resistor-divider trick. A device like ours, acting as a **sink** (power consumer), pulls each CC line down to GND through a resistor called **Rd**, fixed by the USB-C specification at **5.1 kΩ ± 20%**. The host (or charger), acting as a **source**, pulls the *same* CC line up toward its own supply through a resistor called **Rp**, whose value it deliberately varies (56 kΩ, 22 kΩ, or 10 kΩ) to advertise how much current it's willing to supply.

The value 5.1 kΩ isn't arbitrary — it's the fixed reference against which the *host's* varying Rp forms a voltage divider, and the specification defines precise voltage-threshold bands the host measures on the CC line to figure out which Rp (and therefore which current capability) is present:

| Voltage measured on CC (with the fixed 5.1 kΩ Rd on our side) | Meaning |
|---|---|
| below ~0.20 V | no sink attached |
| ~0.20 – 0.66 V | default USB power (500 mA / 900 mA after enumeration) |
| ~0.66 – 1.23 V | 1.5 A available |
| ~1.23 – 2.04 V | 3.0 A available |

Because **every** compliant sink device in the world uses the *same* 5.1 kΩ value, this voltage-divider math is predictable and standardized — the host can reliably tell current capability apart using only a simple analog voltage measurement, no digital communication required. If we used some other resistor value instead, the divider math would land in the wrong voltage band and the host might refuse to provide power at all, or provide the wrong amount.

We use CC1 *and* CC2 (two separate 5.1 kΩ resistors, R1 and R2 — never tied together) for the same reversibility reason as D+/D−: only one of the two CC pins actually makes contact with the cable's single real CC wire, and which one depends on plug orientation, so both must be terminated identically for the connector to work either way up.

#### Other USB-C port roles besides "sink"

"Sink" (Rd, power consumer) is only one of several roles a USB-C port can take on:

- **UFP (Upstream-Facing Port)** — the *data* role our board plays: a peripheral/device, as opposed to a host. Usually paired with being a power sink.
- **DFP (Downstream-Facing Port)** — the *data* role a host (PC, hub) plays; on the power side, a DFP is normally a **source** (Rp instead of Rd), supplying VBUS current to whatever is plugged in.
- **DRP (Dual-Role Port)** — a port (e.g. on a phone or laptop) that can dynamically switch between source/sink and host/device, actively toggling its CC resistor between Rp and Rd until it detects what's on the other end, then settling into whichever role makes sense (this is how phones can both charge *and* power/charge accessories through the same port).
- There's also a **VCONN source** role, relevant only for *active* cables (which contain their own small chip and need extra power on the cable's dedicated VCONN pin) — irrelevant for our simple, passive USB-C connection.

Our board is deliberately the simplest possible case: a **fixed sink** (Rd only, never toggling), which is the correct and sufficient choice for a USB-powered embedded board that never needs to supply power to anything else.

#### Why USB lines need dedicated ESD protection

The USB-C connector is, by definition, the one point on the entire board that is physically exposed to the outside world and to direct human contact — every time someone plugs in a cable, there's a real chance of an electrostatic discharge (ESD) event, which can be several **kilovolts** in a dry environment (a person walking across carpet can easily build up 10–15 kV). The ESP32-C3's actual USB pins, like virtually every IC's I/O pins, are only rated to tolerate a few volts beyond their normal operating range before the internal silicon is permanently damaged. Without protection, a single static discharge while plugging in a cable can silently destroy the chip's USB transceiver (or the whole SoC) — this is exactly the kind of failure that's invisible until the board mysteriously stops enumerating over USB. This is why *any* connector that a human will physically touch — USB, headers people might probe, exposed buttons — is treated as an ESD risk boundary and protected accordingly, even on a simple educational board.

#### ESD protection components

Two separate ESD protection components exist on this board, because they protect **different** things with **different** requirements:

**D1 — PESD5V0L1ULD (SOD-882D, LCSC C552557)** protects **VBUS**. It's a low-capacitance *unidirectional* TVS-type diode rated for 5 V, placed as close as possible to the USB-C connector, before the LDO. Its job: clamp any ESD spike coming in on VBUS (e.g. from a person touching the connector's shell or a poorly-shielded cable) before it reaches the regulator.

**U1 — USBLC6-2SC6 (SOT-23-6, LCSC C7519)** protects **D+ and D−** together. It's specifically designed for USB data-line protection: *very* low capacitance (critical, because any stray capacitance on a data line distorts the signal edges) and *two channels* in one package, so both D+ and D− are protected from a single, compact IC instead of two separate discrete diodes. This is why it comes in a 6-pin package — 2 signal pins in, 2 signal pins out, plus VCC and GND for the internal clamp reference.

**Why VBUS and D+/D− need separate ICs:** VBUS carries real current (up to 500 mA+) and only needs modest ESD protection with no signal-integrity concerns. D+/D− carry a 12 Mbps differential signal and need extremely low parasitic capacitance so the protection diode doesn't degrade the signal edges — a generic power-rail TVS diode would be entirely unsuitable for this job, hence the dedicated USB ESD IC.

### 2.2 Schematic grouping (visual hygiene)

You'll notice the power sheet groups related components inside visual rectangles/boxes — one box around the USB-C connector + CC resistors + ESD protection, a second box around the LDO + its capacitors. This costs nothing electrically, but it is extremely valuable for readability:

- A reader can identify "this is the USB protection block" or "this is the regulator block" at a glance, without tracing every wire
- It documents *design intent* — grouping tells the next person (or future-you) which components form one functional unit
- It makes it easy to visually cross-check a block against a reference design or datasheet application circuit, one box at a time

This is a habit worth carrying into every future schematic you draw, professional or hobby.

### 2.3 Power flags (PWR_FLAG)

The power sheet contains three `PWR_FLAG` symbols. These are not real components — they exist purely for KiCad's **ERC** (Electrical Rules Checker, see §6). ERC normally expects every net to be *driven* by a component pin explicitly marked as a power output (like a regulator's output pin). But nets like `VBUS`, which originate from a plain connector pin (electrically just "passive," as far as KiCad's pin-type system is concerned), have no such driver — so without a `PWR_FLAG`, ERC would incorrectly report *"this power net has no driver"* as an error. Placing a `PWR_FLAG` on a net is you, the designer, explicitly telling ERC: *"trust me, this net is genuinely powered from outside the schematic (a cable, a battery, a connector) — stop warning me about it."*

---

## 3. The LDO Regulator

### 3.1 What an LDO is

A **Low-Dropout linear regulator** takes an unregulated (or higher) input voltage and produces a clean, fixed, lower output voltage by continuously "throwing away" the excess voltage as heat across an internal pass transistor. It is the simplest possible way to go from USB's 5 V to the ESP32-C3's required 3.0–3.6 V (3.3 V nominal): no inductors, no switching noise, no PCB layout complexity — just two capacitors and the IC itself. The trade-off is efficiency (the "wasted" voltage × current becomes heat), which is a non-issue at our current levels (hundreds of mA) and board size.

### 3.2 Why XC6220B331 over AP2112K-3.3

We compared two very common 3.3 V LDOs before choosing:

| Parameter | XC6220B331 (chosen) | AP2112K-3.3 |
|---|---|---|
| Max output current | 1 A | 600 mA |
| Quiescent current | 8 µA | ~55 µA |
| Dropout voltage | 655 mV @ 1A | 250 mV @ 600mA |
| Package | SOT-25 | SOT-23-5 |

The deciding factor was **current headroom**. The ESP32-C3's Wi-Fi transmitter draws current in short but significant bursts (up to ~350 mA peak per the module datasheet's current consumption table). AP2112K-3.3's 600 mA ceiling leaves comparatively little margin once you add LED and peripheral current on top; XC6220B331's 1 A rating gives a much safer margin, at the cost of a slightly higher dropout voltage — which is irrelevant here since we have a full 5 V→3.3 V budget to work with. Its lower quiescent current is also a nice bonus if the board is ever battery-powered in a future revision.

### 3.3 Input/output capacitors — and why we must not improvise their values

The XC6220 series requires a *specific, tested* combination of input capacitor (CIN) and output capacitor (CL) for phase compensation — this is **not** a generic "more capacitance is always fine" situation for the *ratio* between CIN and CL, because the datasheet explicitly warns:

> *"The values needed for phase compensation are shown in the table below. If there is a loss of capacitance, a stable phase compensation might not be achieved."*

Torex's own recommended table (for 3.00–3.50 V output versions, which includes our 3.3 V part) is:

| CIN | CL (COUT) |
|---|---|
| 4.7 µF | 47 µF |
| **10 µF** | **4.7 µF** |
| 22 µF | 4.7 µF |

We picked the **CIN = 10 µF / CL = 10 µF** combination for our board (`C1`, `C7`, both 0805, 10 µF, LCSC C15850): this equals or exceeds every tested combination in the table, which is safe, because *more* output capacitance than the minimum tested value never destabilizes an LDO — it can only improve transient response. What is **not** safe is going the other direction: e.g. picking a small CIN (4.7 µF) *without* also scaling up CL to the datasheet-required 47 µF, or using a symmetric 4.7 µF/4.7 µF pair, which sits in a gap the datasheet never tested and could reduce the phase margin of the regulation loop.

**Rule of thumb for the workshop:** always start from a documented, tested capacitor pair in the datasheet, and if you deviate, only deviate by *increasing* capacitance — never decreasing it below a tested value.

Both capacitors should be placed as physically close as possible to the IC's VIN and VOUT pins respectively, per the datasheet's own layout note.

---

## 4. From Schematic to PCB

### 4.1 Grouping and placement strategy

Before routing a single trace, organize the *physical* placement of components to mirror the functional grouping we already established in the schematic:

1. In the schematic editor, select each functional block (e.g. all components inside the "USB protection" box) and note the reference designators.
2. Switch to the PCB editor (`Cmd/Ctrl+Cross-Probe`, or simply select in the schematic and use **Tools → Highlight Net** / selection sync) — KiCad highlights the corresponding footprints on the board.
3. Physically cluster each group together on the board:
   - **USB-C connector + CC resistors + ESD protection (D1, U1)** — right at the board edge, close to J1, minimizing the length of exposed, unprotected VBUS/D+/D− traces before they reach protection
   - **LDO + its capacitors (U2, C1, C7)** — directly downstream of the protection cluster
   - **ESP32-C3-MINI-1 module + its decoupling caps (C3–C6)** — central, since almost everything else connects to it
   - **LEDs, buttons, headers** — around the module's free edges, near the GPIOs they connect to, to keep those traces short

This clustering approach isn't just tidy — it directly shortens the highest-risk traces (ESD-sensitive USB lines, power input) and gives you a natural, low-stress routing order: work outward from each cluster toward the module.

### 4.2 Why a 4-layer PCB, and what each layer is for

For this board we use a **4-layer stack-up**, following the same general principle Espressif recommends for their own ESP32 reference designs:

| Layer | Name | Role |
|---|---|---|
| 1 (Top) | `F.Cu` | Signal traces **and** all components |
| 2 | `In1.Cu` | Solid **GND** plane — no signal traces |
| 3 | `In2.Cu` | **Power** plane — VBUS island + 3.3 V pour, plus a few signal traces if needed |
| 4 (Bottom) | `B.Cu` | A few remaining signal traces only, no components |

Why bother with 4 layers for a board this simple, when 2 layers would technically work?

- **A continuous ground plane (`In1.Cu`) gives every signal a clean, low-inductance return path directly underneath it.** On a 2-layer board, GND is a patchwork of hand-drawn traces/pours, and current has to find its way back to the source through whatever copper happens to be nearby — worse signal integrity, worse EMI, especially relevant next to a Wi-Fi radio module.
- **A dedicated power plane (`In2.Cu`) lets us deliver power with very low resistance and inductance to every corner of the board**, instead of relying on relatively narrow, meandering top-layer traces.
- It's genuinely good, industry-standard practice — even for "simple" boards, it's the technique students will need on every real embedded project afterward. Learning it here, on a small and forgiving board, is far better than learning it for the first time on a complex one.

### 4.3 Power plane strategy on `In2.Cu`: two islands, one layer

Rather than routing VBUS (5 V) and +3.3V as traces, we pour them as **copper zones (polygons)** directly on the power layer `In2.Cu` — this is the "strong power rail" technique:

1. Draw a zone on `In2.Cu`, assign it net **VBUS**. This zone only needs to cover the small area spanning USB-C connector → ESD diode → LDO input — VBUS is only used by that short path.
2. Draw a **second, separate** zone on the **same layer**, assign it net **+3.3V**. Pour it across the rest of the board — everywhere the module, LEDs, buttons, and headers need 3.3 V.
3. KiCad automatically keeps the two zones apart according to your clearance rule (§5) — they are two independent islands of copper on the same physical layer, never touching, each carrying its own net.

**What if the two zones' outlines overlap on the drawing?** This is where **zone priority** comes in. Every zone in KiCad has a **Priority** value (an integer, default 0). When two zones on the *same copper layer* overlap in their drawn outline, KiCad fills the **higher-priority zone first**, then fills the lower-priority zone everywhere *except* inside the higher-priority zone's area (plus your clearance margin) — the lower-priority zone's copper is automatically carved away around the higher-priority one, so they never bridge together even if you were sloppy when drawing the outlines.

In our case: give the small `VBUS` island a **higher priority** (e.g. 1) than the large `+3.3V` pour (priority 0, the default). That way, even if you roughly sketch the `+3.3V` zone's outline right across the area where `VBUS` should be, KiCad automatically keeps `VBUS` intact and clears the `+3.3V` copper away from it — instead of you needing to trace a pixel-perfect boundary by hand.

**Where to find it:** double-click a zone's outline (or right-click → **Zone Properties**) to open the zone's settings dialog — the **Priority** field is right there alongside net, clearance, and fill options. Newer KiCad versions (9/10) also have a dedicated **Zone Manager** panel (accessible from the zone tools or the **Edit** menu) that lists every zone on the board in one table, with layer, net, and priority all visible and editable side-by-side — much easier than hunting for each zone individually once a board has several overlapping pours.

Every component pin that needs VBUS or +3.3V connects down to its respective island through a **via** (see §4.4), rather than through a long, thin top-layer trace. The result: extremely short, low-resistance, low-inductance connections from every power pin straight down into a wide copper pour — a "strong" power rail that barely sags under load, exactly the property we want given the ESP32-C3's Wi-Fi current bursts.

### 4.4 Connecting pins to inner layers with vias

A via is a plated hole that electrically connects copper on different layers. To connect, say, the LDO's output pad (on `F.Cu`, where the LDO itself is soldered) down to the `+3.3V` island on `In2.Cu`:

1. Route (or directly place) a via on the pad's net, right at or immediately next to the pad
2. The via's barrel is plated copper running through the board, touching every layer it passes — it will automatically connect to the `+3.3V` zone on `In2.Cu` if the via's assigned net matches the zone's net (and only that layer, since `In1.Cu` is GND and `B.Cu` is a different net or unused there)
3. For power/high-current pins (LDO output, VBUS input, EN pull-up), it's good practice to use **more than one via** in parallel — this both lowers the total resistance/inductance of the connection and adds redundancy

For GND connections specifically, this is even more important: every GND pin/pad on `F.Cu` should drop a via straight down to the `In1.Cu` ground plane, right at the pad, so return current has the shortest possible path back to its source.

---

## 5. Design Rules, Per Net Class

KiCad lets you assign every net on the board to a **net class**, and each net class carries its own track width, clearance, and via settings — so a thin signal trace and a thick power trace can both be "correct" simultaneously, each following its own class's rule. This is set up in **File → Board Setup → Design Rules → Net Classes**. A separate tab, **Constraints**, holds the *absolute* global minimums that DRC checks regardless of which class a net belongs to — think of Net Classes as "what I want by default," and Constraints as "the hard floor I never want to cross even by accident."

| Net class | Assigned nets | Track width | Clearance | Via (dia / drill) | Why |
|---|---|---|---|---|---|
| **Default** | all general digital signals (GPIOs, buttons, LEDs) | 0.25 mm | 0.15 mm | 0.7 / 0.4 mm | Comfortable, reliable width for low-current digital signals; well above JLCPCB's manufacturing minimum, minimizing first-board DRC surprises |
| **Power** | `VBUS`, `+3.3V`, `GND` branches carrying real current | 0.4 – 0.5 mm | 0.2 mm | 0.8 / 0.4 mm (prefer 2+ vias in parallel per connection) | Wider traces lower resistance/voltage drop under the ESP32-C3's Wi-Fi current bursts; slightly larger clearance reduces the chance of solder bridging on a wide, current-carrying pad/pour; a bigger via pad lowers via resistance and gives more thermal/mechanical margin |
| **USB (D+/D−)** | `USB_D+`, `USB_D-` | ~0.2 mm (both traces identical) | 0.15 – 0.2 mm *between the pair*, but 0.3 mm+ to any *other* net | Equal, matched trace width keeps the differential pair symmetric; a small, consistent gap between the two traces keeps them tightly coupled (good practice even without formal impedance control at Full-Speed); wider clearance to unrelated nets reduces coupling/crosstalk into or out of the USB signal |

**Board edge clearance** (0.3 mm, copper/components to board outline) and **minimum annular ring** (0.13–0.15 mm) are board-wide settings, also configured in the Constraints tab rather than per net class, since they apply to manufacturing limits rather than to any specific signal's electrical needs.

### 5.1 Differential pair routing for D+/D− in KiCad

Even though our Full-Speed USB link doesn't require strict 90 Ω impedance control, it's worth routing D+/D− as a proper differential pair — both for good habit-building and because KiCad makes it easy:

1. **Name the nets so KiCad recognizes them as a pair.** KiCad auto-detects diff pairs from matching suffixes — `+`/`-`, or `_P`/`_N`. Our nets `USB_D+` / `USB_D-` already follow this convention, so KiCad will offer them as a pair automatically.
2. **Set the pair's target width and gap.** In **File → Board Setup → Design Rules → Net Classes**, assign both nets to the same custom class (e.g. "USB") and set its *track width* and *diff-pair gap* fields — this is the width/spacing KiCad's router will try to maintain.
3. **Route both traces together.** Select the starting pad of either net, then switch the router to **differential pair mode** (toolbar icon, or the **Route → Differential Pair** menu item / hotkey `6` in recent KiCad versions). Draw the route as normal — KiCad automatically routes *both* traces simultaneously, keeping them the set distance apart and mitering the corners symmetrically.
4. **Length-match afterward, if needed.** **Route → Tune Differential Pair Skew** (and the regular **Tune Length** tool for the overall pair length) lets you add small meander/serpentine sections to equalize the two traces' lengths, or match the pair's total length to another signal. At Full-Speed USB, matching within a few millimeters is more than sufficient — this isn't the tight, sub-mm tuning you'd need for a High-Speed or PCIe link, but it's good practice to build the habit now.

---

## 6. Verification: ERC and DRC

Never skip these two checks — they exist specifically to catch the class of mistakes that are invisible by eye but will absolutely stop your board from working.

### 6.1 ERC — Electrical Rules Checker (schematic level)

Run from the schematic editor: **Inspect → Electrical Rules Checker**. ERC analyzes the *logical* correctness of your schematic, independent of any physical layout — things like:

- Two outputs driving the same net (a short circuit waiting to happen)
- An input pin left completely unconnected
- A power net with no driving source (this is exactly what `PWR_FLAG` symbols resolve, §2.3)
- Pins of mismatched types connected together in a way that's likely a mistake

**Run ERC before you start laying out the PCB.** Fixing a wiring mistake in the schematic takes thirty seconds; discovering the same mistake after you've already routed half the board is far more painful. The workshop rule: **zero ERC errors** before moving to layout. Warnings should be individually reviewed — some are genuinely benign (e.g. an intentionally unconnected NC pin), but never wave away an error you don't understand.

### 6.2 DRC — Design Rules Checker (board level)

Run from the PCB editor: **Inspect → Design Rules Checker → Run DRC**. DRC checks the *physical* board against the manufacturing rules you set up in §5 — things like:

- Traces or pads closer together than your clearance setting
- Vias or drills smaller than your minimum
- Unrouted connections (the "ratsnest" lines that haven't become real copper yet)
- Net mismatches inside zones (exactly the via/zone clearance issue we debugged earlier in this workshop — a via left without a net assignment, sitting inside a same-named copper pour, triggers a false clearance violation because KiCad sees it as electrically unrelated to the zone around it)

**Run DRC repeatedly while routing**, not just once at the end — catching a problem three traces after you made it is much easier than after the whole board is finished. The workshop rule, same as ERC: **zero DRC errors** before you send the board off for fabrication. A board with unresolved DRC errors should never be ordered.

---

## 7. Bill of Materials

| Ref(s) | Qty | Value / Part | Package | LCSC # | Purpose |
|---|---|---|---|---|---|
| U3 | 1 | ESP32-C3-MINI-1-N4 | ESP32-C3-MINI-1 module | C2838502 | Main RISC-V Wi-Fi/BLE module (4 MB flash, integrated) |
| U2 | 1 | XC6220B331MR | SOT-23-5 | C22466451 | 3.3 V, 1 A LDO regulator |
| U1 | 1 | USBLC6-2SC6 | SOT-23-6 | C7519 | Dual-channel USB D+/D− ESD protection |
| D1 | 1 | PESD5V0L1ULD | SOD-882D | C552557 | Unidirectional 5 V ESD protection on VBUS |
| J1 | 1 | USB_C_Receptacle_USB2.0_16P | GT-USB-7010ASV | C2988369 | USB-C power + data connector |
| J2, J3 | 2 | Conn_01x08 | PinHeader_1x08_P2.54mm | — | Breadboard-compatible GPIO/UART headers |
| BOOT1, RESET1, USER1 | 3 | SW_Push | SW_SPST_B3U-1000P-B | C231330 | Tactile switches (boot / reset / user input) |
| D2 | 1 | LED GREEN | 0805 | C2297 | Status LED |
| D3 | 1 | LED YELLOW | 0805 | C2296 | Status LED |
| C1, C7 | 2 | 10 µF | 0805 | C15850 | LDO input (CIN) and output (CL) capacitors |
| C2 | 1 | 4.7 µF | 0805 | C597439 | Auxiliary power capacitance |
| C3, C4, C5, C6 | 4 | 100 nF | 0805 | C380332 | Decoupling (module + button debounce filtering) |
| R1, R2 | 2 | 5.1 kΩ | 0402 | C2907044 | USB-C CC1/CC2 sink pull-downs |
| R9, R10 | 2 | 330 Ω | 0402 | C105875 | LED current-limiting resistors |
| R3 | 1 | 4.7 kΩ | 0402 | C105871 | Auxiliary pull resistor (verify net assignment against your schematic revision) |
| R4–R8 | 5 | 10 kΩ | 0402 | C60490 | Pull-ups: EN, GPIO2/8/9 (boot strapping), USER_BTN |

> **Note on R3 and C2:** these two parts don't map to one of the "textbook" circuits described in this handbook (they were added for board-specific reasons during design). Before final review, double-check their exact net assignment directly in your schematic so every component in your BOM has a documented purpose — this is good practice for any board you hand off to someone else.

---

## 8. Passive Component Packages: 0402 vs 0603 vs 0805

| Package | Metric size | Typical size (L×W) | Hand-solderable? | Notes |
|---|---|---|---|---|
| 0402 | 1005 | 1.0 × 0.5 mm | Difficult for beginners | Common for machine (reflow/JLCPCB assembly) placement; very easy to lose, hard to probe with a multimeter by hand |
| 0603 | 1608 | 1.6 × 0.8 mm | Manageable with practice | Good middle ground; still small pads |
| 0805 | 2012 | 2.0 × 1.25 mm | **Recommended for hand soldering** | Large enough pads for tweezers + soldering iron, easy to inspect visually, still compact |

**Why this matters for our BOM:** notice that our resistors are specified in **0402**, while capacitors and LEDs are **0805**. This reflects that the resistors on this particular board were sized assuming **machine (reflow/PCBA) assembly**, where 0402 is fine and actually preferred (smaller footprint, lower cost per unit at volume). If your workshop plan is **hand-soldering by students**, this is worth revisiting: consider swapping the resistor footprints to 0603 or 0805 before ordering boards, so students aren't fighting 1×0.5 mm pads with a soldering iron on day one. This mismatch is a good, concrete teaching moment about how the *intended assembly method* (hand vs. machine) should directly drive footprint choice, not just "smaller is more modern."

---

## 9. How to Select a Capacitor (Capacitance, Voltage, Temperature Coefficient)

When choosing a ceramic capacitor on LCSC (or any distributor), three parameters matter beyond the nominal capacitance value printed on the part:

### 9.1 Capacitance value

Match the value called for in the datasheet or your calculation (e.g. the LDO's tested CIN/CL pair, §3.3). Going *higher* is usually safe for bulk/decoupling capacitors; going *lower* than a specified value can break stability (as we saw with the LDO) or reduce filtering effectiveness.

### 9.2 Voltage rating — and why to derate

Always choose a rated voltage **comfortably above** the actual voltage the capacitor will see in circuit — a good rule of thumb is **at least 2× the working voltage** for ceramic capacitors. This matters because of an effect specific to ceramic (X5R/X7R) capacitors called **DC bias derating**: their *effective* capacitance under a real DC voltage is measurably lower than their nominal, zero-volt rating — and the closer the working voltage is to the rated voltage, the worse this effect gets.

For example: a capacitor rated for 10 µF at 6.3 V, used in a 5 V circuit, might deliver noticeably less than its printed 10 µF in practice. The same nominal 10 µF part rated for 16 V, used in that same 5 V circuit, keeps much closer to its printed value. This is why, for our 5 V (VBUS) and 3.3 V rails, we specify capacitors rated **16 V** even though the circuit never exceeds 5 V.

### 9.3 Temperature coefficient / dielectric class

Ceramic capacitors are graded by how much their capacitance drifts with temperature:

| Dielectric | Stability | Typical use |
|---|---|---|
| **C0G/NP0** | Extremely stable, ~0 ppm/°C | Precision analog, timing, RF — rarely needed on a digital logic board |
| **X7R** | Good, ±15% over −55 to +125 °C | **Recommended default** for decoupling and general-purpose bulk capacitance |
| **X5R** | Good, ±15% over −55 to +85 °C | Very common, slightly narrower temperature range than X7R, otherwise similar |
| **Y5V / Z5U** | Poor, up to −80%/+22% swing | Avoid for anything where the actual capacitance matters — fine only for the crudest bulk filtering, if at all |

For every capacitor on this board — LDO caps, decoupling caps, everything — we specify **X5R or X7R**. Avoid Y5V/Z5U parts even though they're often the cheapest option on LCSC; the capacitance swing under temperature and voltage can be severe enough to undermine exactly the stability these capacitors are there to provide.

### 9.4 Practical LCSC checklist

When picking a part on LCSC, confirm all four before adding it to your BOM:

1. ✅ Capacitance matches your requirement (or exceeds a tested minimum)
2. ✅ Voltage rating ≥ 2× your actual working voltage
3. ✅ Dielectric is X5R or X7R (not Y5V/Z5U)
4. ✅ Package matches your intended assembly method (§8)

---

## 10. Reference Material

- ESP32-C3-MINI-1 & MINI-1U Datasheet, v2.2 (Espressif) — module pinout, boot configuration, electrical characteristics, recommended PCB land pattern
- [Espressif ESP Hardware Design Guidelines — PCB Layout Design](https://docs.espressif.com/projects/esp-hardware-design-guidelines/en/latest/esp32/pcb-layout-design.html) — general 4-layer stack-up and power-plane principles (chip-level guide; our module-based design skips the RF/crystal-specific sections, which don't apply when using a pre-certified module)
- Torex XC6220 series datasheet — recommended CIN/CL capacitor table
- LCSC / JLCPCB component library — part numbers referenced throughout this handbook
