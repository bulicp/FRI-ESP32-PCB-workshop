# 0. What we are building

A small development board, about 35 × 48.5 mm, four copper layers, built around the **ESP32-C3-MINI-1-N4** module: a 32-bit RISC-V core at 160 MHz, 400 KB SRAM, 4 MB flash, Wi-Fi 4 and Bluetooth 5 LE.

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
