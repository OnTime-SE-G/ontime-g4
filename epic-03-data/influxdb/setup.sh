#!/usr/bin/env bash
set -euo pipefail

ORG="${DOCKER_INFLUXDB_INIT_ORG:-transit-org}"
TOKEN="${DOCKER_INFLUXDB_INIT_ADMIN_TOKEN:?missing InfluxDB admin token}"
AGGREGATE_BUCKET="gps-aggregates"
G2_ORG="ontime"
G2_BUCKET="telemetry"

until influx ping --host http://localhost:8086 >/dev/null 2>&1; do
  sleep 2
done

if ! influx bucket list --org "$ORG" --token "$TOKEN" | awk 'NR > 1 {print $2}' | grep -qx "$AGGREGATE_BUCKET"; then
  influx bucket create \
    --name "$AGGREGATE_BUCKET" \
    --org "$ORG" \
    --retention 2160h \
    --token "$TOKEN"
fi

if ! influx org list --token "$TOKEN" | awk 'NR > 1 {print $2}' | grep -qx "$G2_ORG"; then
  influx org create --name "$G2_ORG" --token "$TOKEN"
fi

if ! influx bucket list --org "$G2_ORG" --token "$TOKEN" | awk 'NR > 1 {print $2}' | grep -qx "$G2_BUCKET"; then
  influx bucket create \
    --name "$G2_BUCKET" \
    --org "$G2_ORG" \
    --retention 168h \
    --token "$TOKEN"
fi
