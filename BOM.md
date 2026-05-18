# Bill of Materials — ESP32 Smart Home Control System

Rev: 1.0

| Ref        | Qty | Description               | Part Number       | Value / Rating              |
|------------|-----|---------------------------|-------------------|-----------------------------|
| U1         | 1   | ESP32 DevKit              | ESP32-WROOM-32    | 240MHz, Wi-Fi + BT, 38-pin  |
| RL1–RL8    | 8   | Relay, SPDT               | SRD-05VDC-SL-C    | 5V coil, 10A / 250VAC       |
| Q1–Q8      | 8   | NPN Transistor            | 2N2222            | 40V, 600mA, TO-92           |
| D1–D8      | 8   | Rectifier Diode           | 1N4007            | 1A, 1000V, flyback          |
| R1–R8      | 8   | Resistor                  | —                 | 1 kΩ, 0.25W, ±5%            |
| R9–R16     | 8   | Resistor (pull-up)        | —                 | 10 kΩ, 0.25W, ±5%          |
| C1         | 1   | Electrolytic Capacitor    | —                 | 10 µF, 16V, 5V bulk         |
| C2         | 1   | Electrolytic Capacitor    | —                 | 4.7 µF, 10V, 3.3V bulk      |
| C3–C6      | 4   | Ceramic Capacitor         | —                 | 100 nF, 50V, decoupling     |
| VR1        | 1   | LDO Voltage Regulator     | AMS1117-3.3       | 5V → 3.3V, 1A, SOT-223     |
| J1–J8      | 8   | Screw Terminal, 2-pin     | —                 | 5.08mm pitch, 10A           |
| J9         | 1   | Screw Terminal, 2-pin     | —                 | 5.08mm pitch, power input   |

## Notes

- R1–R8: transistor base resistors. Located between ESP32 GPIO and 2N2222 base pin.
- R9–R16: button pull-up resistors. Omit if buttons not populated.
- D1–D8: installed across relay coil terminals. Cathode toward 5V rail.
- C3–C6: place as close as physically possible to IC VCC pins.
- VR1: omit if board is powered from a regulated 3.3V source directly.
