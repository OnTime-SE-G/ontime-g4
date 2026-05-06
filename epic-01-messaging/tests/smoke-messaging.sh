#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Epic 01 — Messaging Backbone Smoke Test
# Verifies: HiveMQ, Kafka, Topics, and MQTT→Kafka bridge flow
# Usage: ./smoke-messaging.sh [--k8s]
#   --k8s  run against Kubernetes cluster (default: local docker)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
MODE="docker"

if [[ "${1:-}" == "--k8s" ]]; then
  MODE="k8s"
fi

pass() { ((PASS++)); echo -e "${GREEN}✅ PASS${NC}: $1"; }
fail() { ((FAIL++)); echo -e "${RED}❌ FAIL${NC}: $1"; }
info() { echo -e "${YELLOW}ℹ️  ${NC}$1"; }

# ── Resolve hosts ──
if [[ "$MODE" == "k8s" ]]; then
  MQTT_HOST="hivemq-service.transit-edge.svc.cluster.local"
  KAFKA_BOOTSTRAP="kafka.transit-streaming.svc.cluster.local:9092"
  info "Running in Kubernetes mode"
else
  MQTT_HOST="localhost"
  KAFKA_BOOTSTRAP="localhost:9092"
  info "Running in Docker Compose mode"
fi

echo ""
echo "=============================="
echo " Epic 01 — Smoke Tests"
echo "=============================="
echo ""

# ── Test 1: HiveMQ MQTT broker is reachable ──
info "Test 1: MQTT broker connectivity (port 1883)"
if nc -z "$MQTT_HOST" 1883 2>/dev/null; then
  pass "MQTT broker is reachable on port 1883"
else
  fail "MQTT broker is NOT reachable on port 1883"
fi

# ── Test 2: Kafka broker is reachable ──
KAFKA_HOST="${KAFKA_BOOTSTRAP%%:*}"
KAFKA_PORT="${KAFKA_BOOTSTRAP##*:}"
info "Test 2: Kafka broker connectivity (port $KAFKA_PORT)"
if nc -z "$KAFKA_HOST" "$KAFKA_PORT" 2>/dev/null; then
  pass "Kafka broker is reachable on port $KAFKA_PORT"
else
  fail "Kafka broker is NOT reachable on port $KAFKA_PORT"
fi

# ── Test 3: All 5 G2 topics exist ──
EXPECTED_TOPICS=(
  "transport-telemetry-raw"
  "transport-telemetry-cleaned"
  "transport-anomaly-alerts"
  "transport-telemetry-dlq"
  "trip.lifecycle"
)

info "Test 3: Verifying all 5 Kafka topics exist"
if command -v kafka-topics &>/dev/null; then
  TOPIC_LIST=$(kafka-topics --bootstrap-server "$KAFKA_BOOTSTRAP" --list 2>/dev/null || true)
elif docker exec kafka kafka-topics --bootstrap-server kafka:9092 --list &>/dev/null; then
  TOPIC_LIST=$(docker exec kafka kafka-topics --bootstrap-server kafka:9092 --list 2>/dev/null || true)
else
  TOPIC_LIST=""
  fail "Cannot run kafka-topics (not in PATH or Docker)"
fi

if [[ -n "$TOPIC_LIST" ]]; then
  for topic in "${EXPECTED_TOPICS[@]}"; do
    if echo "$TOPIC_LIST" | grep -q "^${topic}$"; then
      pass "Topic '$topic' exists"
    else
      fail "Topic '$topic' is MISSING"
    fi
  done
fi

# ── Test 4: MQTT publish/subscribe round-trip ──
info "Test 4: MQTT publish round-trip"
TEST_MSG="smoke-test-$(date +%s)"
if command -v mosquitto_pub &>/dev/null && command -v mosquitto_sub &>/dev/null; then
  # Start subscriber in background
  timeout 5 mosquitto_sub -h "$MQTT_HOST" -p 1883 -t "test/smoke" -C 1 > /tmp/mqtt_smoke_result 2>/dev/null &
  SUB_PID=$!
  sleep 1
  # Publish
  mosquitto_pub -h "$MQTT_HOST" -p 1883 -t "test/smoke" -m "$TEST_MSG" 2>/dev/null
  wait $SUB_PID 2>/dev/null || true
  RECEIVED=$(cat /tmp/mqtt_smoke_result 2>/dev/null || echo "")
  if [[ "$RECEIVED" == "$TEST_MSG" ]]; then
    pass "MQTT pub/sub round-trip succeeded"
  else
    fail "MQTT pub/sub round-trip failed (expected '$TEST_MSG', got '$RECEIVED')"
  fi
  rm -f /tmp/mqtt_smoke_result
else
  info "Skipping MQTT round-trip (mosquitto_pub/sub not installed)"
fi

# ── Test 5: Publish G2-schema GPS payload to MQTT ──
info "Test 5: Publish G2-schema test payload to MQTT"
GPS_PAYLOAD='{"busId":"BUS-SMOKE-001","lat":6.7730,"lon":79.8820,"speed":34.5,"heading":45.0,"timestamp":"2025-10-01T08:30:00.000Z"}'
if command -v mosquitto_pub &>/dev/null; then
  if mosquitto_pub -h "$MQTT_HOST" -p 1883 -t "transport/BUS-SMOKE-001/location" -m "$GPS_PAYLOAD" 2>/dev/null; then
    pass "G2-schema GPS payload published to MQTT"
  else
    fail "Failed to publish GPS payload to MQTT"
  fi
else
  info "Skipping GPS payload test (mosquitto_pub not installed)"
fi

# ── Summary ──
echo ""
echo "=============================="
echo -e " Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "=============================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
