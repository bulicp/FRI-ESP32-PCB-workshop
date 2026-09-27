# 5.3 Routing order

1. **Fanout.** Give every power and ground pad its short stub and via down to its plane (section 4.4). On a board with planes, power and ground are not routed as traces from part to part; each pad simply drops a via into its plane, and that *is* the power routing. Do it first, because these vias must sit right beside their pads. Once signal traces have taken that space, there is no room left for them.
2. Traces from each decoupling capacitor to its supply pin — these should be the shortest on the whole board.
3. The USB differential pair, entirely on `F.Cu`.
4. Everything else.
