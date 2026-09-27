# 5.1 Net classes

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
