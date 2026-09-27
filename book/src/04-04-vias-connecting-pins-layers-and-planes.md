# 4.4 Vias: connecting pins, layers and planes

A via is a plated hole joining copper on different layers. On our board
every via is a **through via**, drilled from `F.Cu` to `B.Cu`. It passes
through all four layers but **connects only to copper of its own net**.
On every other layer the copper is cut back around it, leaving an
antipad (section 4.2). A `+3.3V` via therefore joins the +3.3 V island
on `In2.Cu` and passes through the GND plane on `In1.Cu` without
touching it.

That one rule covers the four jobs vias do on this board:

| Job | From | To |
|---|---|---|
| power pin to its island | pad on `F.Cu` | `VBUS` or `+3.3V` zone on `In2.Cu` |
| ground pin to the plane | pad on `F.Cu` | GND zone on `In1.Cu` |
| signal changes layer | track on `F.Cu` | track on `B.Cu` |
| stitching | GND pours on `F.Cu` and `B.Cu` | GND plane on `In1.Cu` |

Through-hole pads need none of this. The header pins, the USB-C shield
slots and the button pegs are plated holes themselves, so they connect
to the zone of their net on every layer directly.

## Before you start: via size

Via diameter and drill are set per net class in **File → Board Setup →
Design Rules → Net Classes**. Our board uses a 0.7 mm via with a 0.4 mm
drill, the same as the global minimum in section 5.1, which any
four-layer fabricator builds without a query. Smaller vias such as
0.6 mm / 0.3 mm are widely available too, but check them against your
manufacturer's standard capabilities first: smaller drills can cost extra.

## Power pins to their island

Every pad on the `VBUS` or `+3.3V` net needs its own path down to
`In2.Cu`. On our board that means:

- **VBUS**: the connector's VBUS pads, the protection diode, the LDO
  input (pin 1), the input capacitor, the CE resistor and the USBLC6's
  pin 5 (the finished result is shown in section 4.3, image
  *VBUS-zones-finished*);
- **+3.3V**: the LDO output (pin 5), the output capacitor, the module's
  pin 3 and its decoupling capacitors, the LED resistors and every
  pull-up.

The procedure is the same for each pad:

1. Make `F.Cu` the active layer.
2. Hover over the pad and press `X` to start routing. The track takes
   the pad's net.
3. Move out 0.3–0.5 mm, away from neighbouring pads, and press `V`. A
   via now hangs on the end of the track.
4. Click to fix the via. The router continues on the other layer; press
   `Esc` to stop. The short stub and the via stay.
5. Press `B` to refill the zones. The ratsnest line from that pad to the
   zone disappears once the via lands in the filled island.

Use the router for these vias, not the free-via tool. A via created
while routing inherits the net of the pad you started from, so it cannot
end up on the wrong net.

**Use more than one via on the power path.** The LDO input and output,
and the connector's VBUS pads, should each get two vias rather than one.
Two vias in parallel have roughly half the inductance of one, provided
they are at least a couple of via diameters apart. Placed
shoulder-to-shoulder they share their magnetic field and the gain
shrinks. Given `u = L·di/dt` from section 2.9, halving *L* halves the
voltage that appears across that connection during a current burst,
such as a Wi-Fi transmission. The reason is inductance, not current: a
single via of this size carries far more current than this whole board draws.
It is the cheapest improvement available anywhere on a board: one extra
via, no extra components, no extra cost.

## Ground pins to the plane

Exactly the same procedure, on the GND net: every GND pad on `F.Cu` gets
**its own via**, right beside the pad, down to `In1.Cu`. Return current
then has the shortest possible path home. Do not collect several GND
pads with traces into one shared via. Each trace adds loop area, which
is exactly what the plane exists to avoid.

The GND pour on `F.Cu` touches many of these pads directly, but that is
no substitute for the via. Traces and pads cut the top pour into narrow
fragments, so the via is the pad's real, short connection to ground.

Place vias **beside** small SMD pads, not inside them. An open via inside
a pad draws solder paste down the hole during reflow and leaves a weak
joint.

Two places deserve extra care:

- **Decoupling capacitors.** When the module needs a burst of current,
  it comes from the nearby capacitor, not from the regulator. That
  current flows in a loop: from the capacitor's `+3.3V` pad to the
  module's supply pin, through the module to its GND pin, and back to
  the capacitor's GND pad. The loop's inductance grows with the area it
  encloses. In order of importance:

  1. **Place the capacitor as close to the supply pin as possible.**
     This fixes most of the loop. Never move a capacitor away from the
     pin just to make room for a via.
  2. **Put its GND via as close to its GND pad as possible**, beside the
     pad rather than inside it.
  3. **If there is room, put that via on the side facing the module.**
     The return current in the plane then reaches it by the shortest
     route. If there is no room, the side of the pad is fine: the
     difference is about a millimetre of loop length.

  On our board there is an even better option. The module's pins 1 and
  2 are GND, right next to pin 3 (+3.3 V). Connect the capacitor's GND
  pad to pin 1 or 2 with a short, wide track on `F.Cu`. The whole loop
  then closes on the top layer within a few millimetres, without
  involving the plane at all. The capacitor still gets its own GND via
  down to `In1.Cu`, but the via's exact position no longer matters much.
- **The module's ground array** (the nine `49 GND` squares). Place vias
  in the gaps between the squares, several of them. This array is the
  module's main return path and its main route for heat.

## A signal from `F.Cu` to `B.Cu`

When a track has to cross another one, it can dive to the bottom layer
and come back up:

1. Start the track on `F.Cu` with `X`, as usual.
2. At the point where you want to change layers, press `V` and click.
   Routing continues on the other layer of the active layer pair, which
   is `F.Cu`/`B.Cu` by default. To pick the target layer explicitly, use
   `<` instead of `V`.
3. Continue on `B.Cu` and click the destination pad to finish. To come
   back up, press `V` again.

A via placed this way belongs to the track: if the track's net ever
changes, the via changes with it.

**Mind the return path.** On `F.Cu` a signal's return current flows in
the GND plane on `In1.Cu`. On `B.Cu` it flows in the power islands on
`In2.Cu`. At the via, the return current has to hop from one plane to
the other, and the only path between them is through the nearest
decoupling capacitor. For slow signals (buttons, LEDs, GPIOs to the
headers) this does not matter, and they may change layers freely. The
USB pair should **not change layers at all**: route `D+` and `D−`
entirely on `F.Cu`, above the solid ground.

## Stitching vias

Stitching vias are GND vias that belong to no pad. They tie the GND
copper on different layers together, here the pours on `F.Cu` and
`B.Cu` to the plane on `In1.Cu`.

They are needed because traces and pads chop the outer-layer pours into
fragments. A fragment connected to ground at one point only behaves like
a small antenna. A fragment connected nowhere is either removed by the
zone fill or left floating. Stitching turns all GND copper into one
low-impedance structure.

Where to put them:

- **Every pour fragment** on `F.Cu` or `B.Cu` gets at least two, one at
  each end. A through via reaches both outer layers, so one via often
  stitches a top and a bottom fragment at the same time.
- **Along the board edges** and **around the edge of the antenna
  keepout**. (Not inside it: no copper and no vias there.)
- **Near the USB connector** and around the module's ground.
- **Elsewhere**, a loose grid of roughly 5 mm is plenty for this board.

The usual rule of thumb is spacing below 1/20 of the wavelength of the
highest frequency present. For 2.4 GHz that is about 3 mm in FR4, which
is why the spacing gets denser near the antenna.

In KiCad 10:

1. Select **Add Free-Standing Via** in the right toolbar, or press
   `Ctrl`+`Shift`+`X`.
2. Click on the GND pour. A free via placed on a zone takes the zone's
   net and keeps it even if you move it later.
3. **Check the net.** On our board the GND plane and the +3.3 V island
   overlap almost everywhere, so select the via and confirm in the
   Properties panel that its net is `GND`. Change it there if it is not.
4. For many vias, copy a correct GND via (`Ctrl`+`C`, `Ctrl`+`V`), or
   select it and use **Create Array** (`Ctrl`+`T`) for a grid. Then delete
   the ones that land on other copper; DRC will point them out.
5. Press `B` and run DRC.

Every stitching via also perforates the +3.3 V island on `In2.Cu` with
an antipad. Keep them spaced rather than in tight rows, so that the
antipads do not merge into a slot (section 4.2).

## When you are done

- Press `B`. There should be no ratsnest lines left on the `GND`,
  `VBUS` or `+3.3V` nets.
- Run DRC and check for *unconnected items* and *isolated copper*.
- Hide all layers except `In1.Cu` (`Ctrl`+`H` cycles the display modes)
  and look at the plane: it should be one piece, perforated by antipads
  but not sliced by them.
