/*
  Toy-car Road Blocker - ESP32 DOIT DevKit V1 on the train-controller PCB
  Firmware v1.2 (2026-10-31)
    v1.0  first sketch (Arduino .ino)
    v1.1  PlatformIO project for VS Code; sensor is a US-025A (3-5.5 V, runs fine on 3.3 V)
    v1.2  test log on the serial monitor (115200): one line per sensor read
          with distance, bridge state, LED colour and any state change

  Start: barrier DOWN (blocked), red LED on.
  Wave a hand in front of the ultrasonic sensor -> barrier rises, green LED.
  Wave again -> barrier lowers, red LED. And so on.
  The hand must be removed before the next wave counts.

  Serial log example (one line per read, ~14 lines/s):
    #   152 | dist   45.3 cm |       | bridge CLOSED | LED RED   |
    #   153 | dist    8.1 cm | HAND  | bridge CLOSED | LED RED   |
    #   155 | dist    7.9 cm | HAND  | bridge OPEN   | LED GREEN | CHANGE: CLOSED -> OPEN
    #   160 | dist  ---  cm |       | bridge OPEN   | LED GREEN |        (--- = no echo / out of range)

  Library: ESP32Servo (installed automatically by PlatformIO, see platformio.ini).
*/
#include <Arduino.h>
#include <ESP32Servo.h>

// ---------------- Pins (from the PCB schematic) ----------------
constexpr int PIN_TRIG      = 23;   // U7 US-025A Trig
constexpr int PIN_ECHO      = 22;   // U7 US-025A Echo
constexpr int PIN_SERVO     = 33;   // S1 MG90S PWM
constexpr int PIN_LED_GREEN = 18;   // R2 -> CN8
constexpr int PIN_LED_RED   = 19;   // R3 -> CN9
constexpr int PIN_BUZZER    = 25;   // R5 -> BZ1

// ---------------- Tuning ----------------
constexpr int   ANGLE_CLOSED      = 0;     // arm horizontal  (tune after fitting the horn)
constexpr int   ANGLE_OPEN        = 90;    // arm vertical
constexpr int   STEP_DELAY_MS     = 12;    // servo speed: ms per degree
constexpr float HAND_CM           = 12.0;  // closer than this = hand
constexpr int   HITS_TO_TRIGGER   = 3;     // consecutive close readings to act
constexpr int   MISSES_TO_REARM   = 5;     // consecutive clear readings before next wave
constexpr unsigned long PING_MS   = 70;    // US-025A: >= 60 ms between pings (out-of-range echo is ~66 ms)
constexpr bool  BUZZER_PASSIVE    = false; // true if BZ1 is a passive piezo
constexpr bool  LOG_EVERY_READ    = true;  // false = log only state changes
constexpr unsigned long SERIAL_BAUD = 115200;

Servo barrier;
bool isOpen       = false;
int  currentAngle = ANGLE_CLOSED;
bool latched      = false;
int  hits = 0, misses = 0;
unsigned long readCount = 0;

// ---------------- Helpers ----------------
const char* bridgeName(bool open) { return open ? "OPEN  " : "CLOSED"; }
const char* ledName(bool open)    { return open ? "GREEN" : "RED  "; }

float readDistanceCm() {
  digitalWrite(PIN_TRIG, LOW);  delayMicroseconds(2);
  digitalWrite(PIN_TRIG, HIGH); delayMicroseconds(10);
  digitalWrite(PIN_TRIG, LOW);
  unsigned long us = pulseIn(PIN_ECHO, HIGH, 25000UL);   // ~4 m timeout
  if (us == 0) return -1;
  return us / 58.0f;
}

void beep(int ms) {
  if (BUZZER_PASSIVE) {
    tone(PIN_BUZZER, 2000, ms);
    delay(ms);
  } else {
    digitalWrite(PIN_BUZZER, HIGH); delay(ms); digitalWrite(PIN_BUZZER, LOW);
  }
}

void showState() {
  digitalWrite(PIN_LED_RED,   isOpen ? LOW  : HIGH);
  digitalWrite(PIN_LED_GREEN, isOpen ? HIGH : LOW);
}

// one log line per read
void logRead(float d, bool hand, bool changed, bool wasOpen) {
  char dist[12];
  if (d < 0) snprintf(dist, sizeof(dist), "  --- ");
  else       snprintf(dist, sizeof(dist), "%6.1f", d);

  char line[128];
  int n = snprintf(line, sizeof(line), "#%6lu | dist %s cm | %s | bridge %s | LED %s |",
                   readCount, dist, hand ? "HAND " : "     ",
                   bridgeName(isOpen), ledName(isOpen));
  if (changed && n > 0 && n < (int)sizeof(line))
    snprintf(line + n, sizeof(line) - n, " CHANGE: %s -> %s",
             wasOpen ? "OPEN" : "CLOSED", isOpen ? "OPEN" : "CLOSED");
  Serial.println(line);
}

// Slow sweep with the red LED blinking while the arm moves
void moveBarrier(int target) {
  barrier.attach(PIN_SERVO, 500, 2400);
  int step = (target > currentAngle) ? 1 : -1;
  unsigned long lastBlink = millis();
  bool red = true;
  digitalWrite(PIN_LED_GREEN, LOW);
  while (currentAngle != target) {
    currentAngle += step;
    barrier.write(currentAngle);
    if (millis() - lastBlink > 150) {
      red = !red;
      digitalWrite(PIN_LED_RED, red);
      lastBlink = millis();
    }
    delay(STEP_DELAY_MS);
  }
  delay(200);
  barrier.detach();          // no hum/jitter, saves the 18650
}

void toggleBarrier() {
  beep(60);
  moveBarrier(isOpen ? ANGLE_CLOSED : ANGLE_OPEN);
  isOpen = !isOpen;
  showState();
}

void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(200);
  Serial.println();
  Serial.println("=== Road Blocker firmware v1.2 ===");
  Serial.printf("Pins: TRIG %d  ECHO %d  SERVO %d  LED_G %d  LED_R %d  BUZZ %d\n",
                PIN_TRIG, PIN_ECHO, PIN_SERVO, PIN_LED_GREEN, PIN_LED_RED, PIN_BUZZER);
  Serial.printf("Hand threshold %.1f cm, %d hits to trigger, ping every %lu ms\n",
                HAND_CM, HITS_TO_TRIGGER, PING_MS);

  pinMode(PIN_TRIG, OUTPUT);
  pinMode(PIN_ECHO, INPUT);
  pinMode(PIN_LED_RED, OUTPUT);
  pinMode(PIN_LED_GREEN, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);

  ESP32PWM::allocateTimer(0);
  barrier.setPeriodHertz(50);

  // start blocked
  barrier.attach(PIN_SERVO, 500, 2400);
  barrier.write(ANGLE_CLOSED);
  currentAngle = ANGLE_CLOSED;
  delay(500);
  barrier.detach();

  isOpen = false;
  showState();
  beep(40);
  Serial.printf("Start: bridge %s, LED %s\n", bridgeName(isOpen), ledName(isOpen));
}

void loop() {
  static unsigned long lastPing = 0;
  if (millis() - lastPing < PING_MS) return;
  lastPing = millis();

  float d = readDistanceCm();
  readCount++;
  bool hand = (d > 0 && d < HAND_CM);
  if (hand) { hits++; misses = 0; } else { misses++; hits = 0; }

  bool wasOpen = isOpen;
  bool changed = false;
  if (!latched && hits >= HITS_TO_TRIGGER) {
    latched = true;
    toggleBarrier();
    changed = true;
  }
  if (latched && misses >= MISSES_TO_REARM) latched = false;

  if (LOG_EVERY_READ || changed) logRead(d, hand, changed, wasOpen);
}
