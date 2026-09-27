# 2.1 What a schematic is, and what it is not

A schematic is **not** a map of the board. It contains no distances, no sizes, no physics. It is a statement of connectivity: *this pin is connected to that pin.* Nothing more.

That is why the same schematic can be realised as a hundred different boards, all electrically identical — and only some of them will work. The difference between them is the subject of sections 4 and 5.

You make connections two ways:

- **with a wire** (`W`) — a visible line between pins,
- **with a label** (`L` for a local label, `Ctrl`+`L` for a global label that crosses sheets) — two pins carrying the same label are connected even though no line is drawn.

Use labels. A schematic with twenty crossing lines is unreadable; a schematic with labels like `SDA`, `LED0`, `GPIO9_BOOT` reads like code.
