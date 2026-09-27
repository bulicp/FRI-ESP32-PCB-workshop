# Appendix D: Where to go next

- **I²C sensors** — `GPIO4` and `GPIO5` are on the header. I²C is open-collector: devices can only pull the line low, so the bus needs pull-up resistors, typically 4.7 kΩ. A digital temperature or pressure sensor is the natural next step.
- **CAN bus** — the ESP32-C3 has a TWAI controller, compatible with CAN 2.0. With an external transceiver the board can talk to automotive and industrial equipment.
- **Current measurement** — a sense resistor and some measurement, to see what transmitting over Wi-Fi actually costs.
- **Your own revision of this board** — you learn most from the second one. Add whatever you found missing.
