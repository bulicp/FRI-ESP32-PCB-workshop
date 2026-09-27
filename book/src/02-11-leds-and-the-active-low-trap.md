# 2.11 LEDs and the active-low trap

Both LEDs are wired **active LOW**: the anode goes through a resistor to +3.3 V, and the cathode connects to the GPIO. **The LED lights when the GPIO is driven to logic 0.**

```
+3.3 V ──[330 Ω]──▶|── GPIO
```

This is not a designer's whim. The output stages of most SoCs can *sink* more current than they can *source*, so this arrangement is the more reliable one.

For you as a programmer it means that writing a logic 1 will **turn the LED off**. Always hide the inversion behind a macro rather than remembering it:

```c
#define LED0        6    /* green  */
#define LED1        7    /* yellow */

#define LED_ON(pin)   gpio_set_level((pin), 0)
#define LED_OFF(pin)  gpio_set_level((pin), 1)
```

**Why 330 Ω?** From Ohm's law, with a typical LED forward voltage around 2.0–2.2 V:

```
I = (3.3 V − V_f) / R  ≈  (3.3 − 2.0) / 330  ≈  4 mA
```

Plenty bright for an indicator with modern LEDs, and comfortably below the ESP32-C3's per-pin limit. The chip can handle far more, but good practice keeps indicator LEDs in the low single-digit milliamps — it saves power and avoids stressing the output stage for no visible gain.
