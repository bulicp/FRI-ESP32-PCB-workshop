# 7.3 First program

```c
#define LED0        6    /* green  */
#define LED1        7    /* yellow */
#define USER_BTN   10

#define LED_ON(pin)   gpio_set_level((pin), 0)   /* active low! */
#define LED_OFF(pin)  gpio_set_level((pin), 1)
```

Sensible first exercises on your own board:

1. Alternate the two LEDs.
2. Read the button, with debouncing.
3. Connect anything at all to the headers. From here the board is yours.
