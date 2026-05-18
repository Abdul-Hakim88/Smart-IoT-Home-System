#include <WiFi.h>
#include <WebSocketsServer.h>

const char* SSID     = "YOUR_WIFI_SSID";
const char* PASSWORD = "YOUR_WIFI_PASS";

// Static IP — so Flutter app always knows where to connect
IPAddress local_IP(192, 168, 1, 100);
IPAddress gateway(192, 168, 1,   1);
IPAddress subnet (255, 255, 255, 0);

const int RELAY_PINS[8] = {13, 32, 14, 27, 19, 21, 22, 23};
bool relayState[8] = {false};

WebSocketsServer ws(81);
unsigned long lastReconnectAttempt = 0;

// ── State helpers ─────────────────────────────────────────
String buildStateMsg() {
  String msg = "";
  for (int i = 0; i < 8; i++) {
    msg += relayState[i] ? "1" : "0";
    if (i < 7) msg += ",";
  }
  return msg;
}

void sendStates(uint8_t clientNum) {
  ws.sendTXT(clientNum, buildStateMsg());
}

void broadcastStates() {
  ws.broadcastTXT(buildStateMsg());
}

// ── WebSocket event handler ───────────────────────────────
void onWsEvent(uint8_t clientNum, WStype_t type, uint8_t* payload, size_t length) {
  switch (type) {

    case WStype_CONNECTED:
      Serial.printf("[WS] Client %d connected\n", clientNum);
      sendStates(clientNum);  // sync state to newly connected client
      break;

    case WStype_DISCONNECTED:
      Serial.printf("[WS] Client %d disconnected\n", clientNum);
      break;

    case WStype_TEXT: {
      String msg = String((char*)payload, length);  // length-safe construction
      Serial.printf("[WS] Received: %s\n", msg.c_str());

      // Validate format: must be "Rn:ON" or "Rn:OFF"
      if (msg.length() < 5)         break;
      if (msg.charAt(0) != 'R')     break;

      int idx = msg.charAt(1) - '0';
      if (idx < 0 || idx > 7)       break;

      String cmd = msg.substring(3);
      if (cmd != "ON" && cmd != "OFF") break;

      bool on = (cmd == "ON");
      relayState[idx] = on;
      digitalWrite(RELAY_PINS[idx], on ? HIGH : LOW);
      broadcastStates();  // keep all connected clients in sync
      break;
    }

    default:
      break;
  }
}

// ── Setup ─────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  // Relays first — all OFF before WiFi starts
  for (int i = 0; i < 8; i++) {
    pinMode(RELAY_PINS[i], OUTPUT);
    digitalWrite(RELAY_PINS[i], LOW);
  }

  // WiFi
  WiFi.mode(WIFI_STA);
  WiFi.config(local_IP, gateway, subnet);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(false);
  WiFi.begin(SSID, PASSWORD);

  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected: " + WiFi.localIP().toString());

  // WebSocket
  ws.begin();
  ws.onEvent(onWsEvent);
  Serial.println("WebSocket server on port 81");
}

// ── Loop ──────────────────────────────────────────────────
void loop() {
  ws.loop();

  // Non-blocking WiFi reconnect — won't freeze WebSocket processing
  if (WiFi.status() != WL_CONNECTED) {
    unsigned long now = millis();
    if (now - lastReconnectAttempt > 5000) {
      lastReconnectAttempt = now;
      Serial.println("WiFi lost — reconnecting...");
      WiFi.reconnect();
    }
  }
}