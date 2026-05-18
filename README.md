# ESP32 Smart Home Control System

Distributed relay control system based on the ESP32 microcontroller, communicating over Wi-Fi via WebSocket. Provides real-time bidirectional control of eight independent relay channels through a Flutter mobile application.

---

## System Architecture

```
Flutter App (Mobile)
       |
       |  WebSocket  ws://192.168.1.100:81
       |
  ESP32 (Server)
       |
  GPIO Outputs (3.3V logic)
       |
  2N2222 NPN Transistor Array (x8)
       |
  Relay Coils (5V)
       |
  Relay Contacts (COM / NO)
       |
  Load (AC/DC Appliances)
```

## Hardware

### Bill of Materials

| Qty | Component         | Value / Part No.     | Notes                            |
|-----|-------------------|----------------------|----------------------------------|
| 1   | Microcontroller   | ESP32-WROOM-32       | Wi-Fi + BT SoC, 38-pin DevKit    |
| 8   | Relay             | SRD-05VDC-SL-C       | 5V coil, SPDT, 10A contacts      |
| 8   | NPN Transistor    | 2N2222 (TO-92)       | Relay coil driver                |
| 8   | Diode             | 1N4007               | Flyback suppression              |
| 8   | Resistor          | 1 kΩ, 0.25W          | Transistor base resistor         |
| 8   | Resistor          | 10 kΩ, 0.25W         | Button pull-up (if buttons used) |
| 1   | Capacitor         | 10 µF electrolytic   | 5V bulk decoupling               |
| 1   | Capacitor         | 4.7 µF electrolytic  | 3.3V bulk decoupling             |
| 4   | Capacitor         | 100 nF ceramic       | IC supply decoupling             |
| 8   | Screw Terminal    | 2-pin, 5.08mm pitch  | Load side output                 |
| 1   | Voltage Regulator | AMS1117-3.3 or LM1117| 5V → 3.3V for ESP32             |

### GPIO Assignment

| GPIO | Function  | Notes                          |
|------|-----------|--------------------------------|
| 13   | Relay 1   |                                |
| 32   | Relay 2   |                                |
| 14   | Relay 3   |                                |
| 27   | Relay 4   |                                |
| 19   | Relay 5   |                                |
| 21   | Relay 6   | Shared with I2C SDA if needed  |
| 22   | Relay 7   | Shared with I2C SCL if needed  |
| 23   | Relay 8   |                                |

### Relay Drive Circuit (per channel)

```
ESP32 GPIO ── 1kΩ ──► 2N2222 Base
                      2N2222 Emitter ──► GND
                      2N2222 Collector ──► Relay Coil (A1) ──► 1N4007 Anode
                                                                1N4007 Cathode ──► 5V
                      Relay Coil (A0) ──► 5V

Relay Contact:
  COM ──► Phase (Line in)
  NO  ──► Phase (Line out to load)
  NC  ──► Not connected
  Neutral bypasses relay directly to load neutral terminal
```

### Power Supply Decoupling

```
5V rail:
  10µF  (electrolytic) — at power entry point
  100nF (ceramic)      — near transistor array

3.3V rail:
  4.7µF (electrolytic) — at regulator output
  100nF (ceramic)      — at ESP32 VCC pin
```

### PCB Design Guidelines

- Two-layer board: signal/power on top, GND copper pour on bottom
- GND pour with thermal relief on through-hole pads, stitching vias every 15–20mm
- No copper (top or bottom) beneath ESP32 antenna area
- Trace widths: signal 0.3mm, 3.3V rail 1.0mm, 5V rail 2.0mm, relay contacts 2.5mm minimum
- Isolate three zones: 3.3V logic / 5V relay coil / high-voltage load contacts
- Physical PCB slot recommended between relay coil zone and mains contact zone
- All net assignments must be defined — unassigned pads are not protected by GND pour clearance

---

## Firmware

### Dependencies

| Library              | Source                          |
|----------------------|---------------------------------|
| Arduino core ESP32   | espressif/arduino-esp32         |
| arduinoWebSockets    | links2004/arduinoWebSockets     |

Install via Arduino Library Manager: search `arduinoWebSockets` by Markus Sattler.

### Configuration

In `firmware/smart_home/smart_home.ino`, set network credentials and static IP:

```cpp
const char* SSID     = "YOUR_WIFI_SSID";
const char* PASSWORD = "YOUR_WIFI_PASS";

IPAddress local_IP(192, 168, 1, 100);
IPAddress gateway  (192, 168, 1,   1);   // match your router
IPAddress subnet   (255, 255, 255,  0);
```

### WebSocket Protocol

| Direction      | Topic / Payload       | Description                   |
|----------------|-----------------------|-------------------------------|
| App → ESP32    | `R{n}:ON`             | Energize relay n (0–7)        |
| App → ESP32    | `R{n}:OFF`            | De-energize relay n (0–7)     |
| ESP32 → App    | `1,0,1,0,0,0,0,1`     | Full state broadcast (8 bits) |

State is broadcast to all connected clients after every write command and upon new client connection.

### Boot Behavior

All relay GPIOs are driven LOW before Wi-Fi initialisation, ensuring all relays remain de-energized during boot and network connection.

---

## Mobile Application

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  web_socket_channel: ^2.4.0
```

### Android Permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Connection

On the connect screen, enter the ESP32 static IP (`192.168.1.100` by default) and tap Connect. The app subscribes to the WebSocket stream and updates relay state tiles in real time. Any state change triggered physically or by another client is reflected across all connected instances.

---

## Electrical Safety

- Only the phase (Live) conductor is routed through relay contacts. Neutral is wired directly to the load.
- Maintain a minimum 4mm creepage and clearance distance between mains-voltage conductors and low-voltage circuitry on the PCB.
- A physical routed slot in the PCB between the relay contact zone and the driver zone is recommended for mains applications.
- The circuit is not isolated. Do not contact any part of the board when mains voltage is applied to the relay contact side.

---

## License

MIT License. See `LICENSE` for full terms.
