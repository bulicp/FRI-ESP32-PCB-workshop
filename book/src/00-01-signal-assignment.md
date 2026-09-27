# Signal assignment

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
| `GPIO0`, `GPIO1`, `GPIO3`–`GPIO5` | — | free, on header J3 |

Note the naming convention: every strapping pin carries the `_BOOT` suffix directly in its net label. This is a good habit — anyone reading the schematic immediately knows *"this net affects boot behaviour, don't casually repurpose it."*
