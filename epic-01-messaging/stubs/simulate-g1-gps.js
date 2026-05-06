#!/usr/bin/env node

// ============================================================
// G4-06 — Simulate G1 GPS device publishing at 1Hz
// Publishes G2-schema payloads to the MQTT broker
//
// Usage:
//   npm install mqtt
//   node simulate-g1-gps.js [--count 3600] [--host localhost] [--port 1883]
//
// Required fields per G2's strict schema:
//   busId, lat, lon, speed, heading, timestamp
// ============================================================

const mqtt = require("mqtt");

// ── Parse CLI args ──
const args = process.argv.slice(2);
function getArg(name, defaultVal) {
  const idx = args.indexOf(`--${name}`);
  return idx !== -1 && args[idx + 1] ? args[idx + 1] : defaultVal;
}

const HOST = getArg("host", "localhost");
const PORT = parseInt(getArg("port", "1883"), 10);
const COUNT = parseInt(getArg("count", "10"), 10);
const BUS_ID = getArg("busId", "BUS-255-TEST");
const TOPIC = `transport/${BUS_ID}/location`;

// ── Moratuwa–Kadawatha corridor approximate coordinates ──
const BASE_LAT = 6.773;
const BASE_LON = 79.882;

console.log(`🚌 Simulating GPS for ${BUS_ID}`);
console.log(`   MQTT: mqtt://${HOST}:${PORT}`);
console.log(`   Topic: ${TOPIC}`);
console.log(`   Messages: ${COUNT} at 1Hz\n`);

const client = mqtt.connect(`mqtt://${HOST}:${PORT}`);

let sent = 0;

client.on("connect", () => {
  console.log("✅ Connected to MQTT broker\n");

  const interval = setInterval(() => {
    if (sent >= COUNT) {
      clearInterval(interval);
      console.log(`\n✅ Done. Published ${sent} messages.`);
      client.end();
      return;
    }

    // Simulate slight movement along the corridor
    const jitterLat = (Math.random() - 0.5) * 0.002;
    const jitterLon = (Math.random() - 0.5) * 0.002;

    const payload = {
      busId: BUS_ID,
      lat: parseFloat((BASE_LAT + jitterLat + sent * 0.0001).toFixed(6)),
      lon: parseFloat((BASE_LON + jitterLon + sent * 0.00005).toFixed(6)),
      speed: parseFloat((25 + Math.random() * 20).toFixed(1)),
      heading: parseFloat((45 + Math.random() * 10).toFixed(1)),
      timestamp: new Date().toISOString(),
    };

    client.publish(TOPIC, JSON.stringify(payload), { qos: 1 }, (err) => {
      if (err) {
        console.error(`❌ Publish error: ${err.message}`);
      }
    });

    sent++;
    if (sent % 100 === 0 || sent === 1) {
      console.log(`  [${sent}/${COUNT}] ${JSON.stringify(payload)}`);
    }
  }, 1000); // 1Hz
});

client.on("error", (err) => {
  console.error(`❌ MQTT error: ${err.message}`);
  process.exit(1);
});
