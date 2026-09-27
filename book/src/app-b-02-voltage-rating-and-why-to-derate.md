# B.2 Voltage rating — and why to derate

Always choose a rated voltage **comfortably above** the actual working voltage; a good rule of thumb is **at least 2×**.

This matters because of an effect specific to ceramic capacitors called **DC bias derating**: their *effective* capacitance under real DC voltage is measurably lower than the nominal, zero-volt rating — and the closer the working voltage is to the rated voltage, the worse it gets.

A 10 µF part rated at 6.3 V, used on a 5 V rail, may deliver noticeably less than 10 µF in practice. The same nominal 10 µF rated at 16 V, on that same 5 V rail, stays much closer to its printed value. This is why our 5 V and 3.3 V rails specify **16 V** parts even though the circuit never exceeds 5 V.
