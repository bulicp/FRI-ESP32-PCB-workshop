# 2.12 Breakout headers, and why the board is not a finished product

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

## What is on the headers

J2 carries power only:

| J2 pin | Signal | Notes |
|---|---|---|
| 1, 8 | +3.3 V | output of the on-board LDO |
| 3, 4 | VBUS | 5 V straight from the USB connector |
| 5, 6 | GND | |
| 2, 7 | — | not connected; marked with no-connect flags (`Q`), see section 2.14 |

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

## Why these GPIOs and not others

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

## Electrical limits

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

## Why the headers are marked DNP

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
