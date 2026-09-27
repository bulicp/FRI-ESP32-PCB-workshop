# 7.2 Sequence

1. The board appears as a serial device: `/dev/ttyACM0` on Linux, `/dev/cu.usbmodem*` on macOS, a `COM` port on Windows.
2. Confirm the chip responds and is indeed an ESP32-C3.
3. Upload a program.
4. The LED blinks.

When it blinks, you have reached the goal: a program running on a RISC-V core, on a board you drew yourself.

> **A consequence worth remembering.** Because the board has no CP2102 or CH340 converter — the ESP32-C3's USB controller is built in and connected directly to GPIO18/19 — the port appears differently from most development boards. It is a USB CDC device: `/dev/ttyACM0` on Linux and `/dev/cu.usbmodem*` on macOS. A great many online tutorials specify `/dev/ttyUSB0` or `/dev/cu.usbserial*`; those are written for boards with a converter chip and will mislead you.

Instructions for installing the toolchain are provided separately.
