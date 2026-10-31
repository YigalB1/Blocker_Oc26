# Road Blocker firmware (v1.1)

ESP32 DOIT DevKit V1 on the train-controller PCB.

- Wave a hand in front of the US-025A sensor → barrier toggles (starts blocked).
- Red LED = blocked, green LED = open; red blinks while the arm moves.

## Open in VS Code
1. Install the **PlatformIO IDE** extension.
2. File → Open Folder → this folder (`road_blocker_fw`).
3. PlatformIO downloads the ESP32 platform and the ESP32Servo library on first build.
4. Build ✓, Upload →, Serial Monitor 🔌 (115200) from the bottom status bar.

## Pins (from Schematic_Train_1)
| Function | GPIO |
|---|---|
| US-025A Trig | 23 |
| US-025A Echo | 22 |
| Servo (S1) | 33 |
| Green LED (CN8) | 18 |
| Red LED (CN9) | 19 |
| Buzzer (BZ1) | 25 |

## Tuning (top of `src/main.cpp`)
`ANGLE_CLOSED` / `ANGLE_OPEN`, `HAND_CM` (trigger distance), `STEP_DELAY_MS` (arm speed),
`DEBUG = true` to print distances on the serial monitor.
