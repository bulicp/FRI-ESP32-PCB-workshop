# 2.2 The power chain

```
USB-C  ──►  PESD (VBUS)  ──►  LDO 5 V→3.3 V  ──►  module
  │                                +3.3 V
  └── D+/D− ──► USBLC6 ────────────────────────►  GPIO19/GPIO18
```

The ESP32-C3-MINI-1 requires **3.3 V** and does **not** tolerate 5 V. At 5 V it is permanently destroyed. The regulator is therefore not a choice but a precondition.
