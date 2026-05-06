#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

require_text() {
  local path="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$path"; then
    echo "Expected '$expected' in $path" >&2
    exit 1
  fi
}

require_file "$ROOT_DIR/migrations/ontime/V1__create_route_schema.sql"
require_file "$ROOT_DIR/migrations/ontime/V2__create_spatial_indexes.sql"
require_file "$ROOT_DIR/migrations/ontime/R__seed_route_255.sql"
require_file "$ROOT_DIR/migrations/fleet/V1__create_fleet_schema.sql"
require_file "$ROOT_DIR/k8s/database-secrets.yaml"
require_file "$ROOT_DIR/k8s/postgres-statefulset.yaml"
require_file "$ROOT_DIR/k8s/postgres-service.yaml"
require_file "$ROOT_DIR/k8s/influxdb-statefulset.yaml"
require_file "$ROOT_DIR/k8s/redis-statefulset.yaml"
require_file "$ROOT_DIR/k8s/flyway-job.yaml"

require_text "$ROOT_DIR/migrations/ontime/V1__create_route_schema.sql" "CREATE TABLE IF NOT EXISTS routes"
require_text "$ROOT_DIR/migrations/ontime/V1__create_route_schema.sql" "CREATE TABLE IF NOT EXISTS stops"
require_text "$ROOT_DIR/migrations/ontime/V1__create_route_schema.sql" "CREATE TABLE IF NOT EXISTS route_stop_links"
require_text "$ROOT_DIR/migrations/fleet/V1__create_fleet_schema.sql" "CREATE TABLE IF NOT EXISTS buses"
require_text "$ROOT_DIR/k8s/postgres-statefulset.yaml" "value: ontime_db"
require_text "$ROOT_DIR/k8s/postgres-statefulset.yaml" "CREATE DATABASE fleet_db"
require_text "$ROOT_DIR/k8s/influxdb-statefulset.yaml" "value: ontime"
require_text "$ROOT_DIR/k8s/influxdb-statefulset.yaml" "value: telemetry"
require_text "$ROOT_DIR/k8s/redis-statefulset.yaml" "name: redis"
require_text "$ROOT_DIR/k8s/flyway-job.yaml" "jdbc:postgresql://postgres:5432/ontime_db"
require_text "$ROOT_DIR/k8s/flyway-job.yaml" "jdbc:postgresql://postgres:5432/fleet_db"

if grep -R -n -E "transit_db|CREATE TABLE .*halts|CREATE TABLE .*vehicles|gps-telemetry|transit-org|R1__" \
  --exclude=verify-schema.sh "$ROOT_DIR"; then
  echo "Found old G4-only database names or schemas that do not match G2." >&2
  exit 1
fi

if command -v kubectl >/dev/null 2>&1; then
  kubectl create --dry-run=client --validate=false -f "$ROOT_DIR/k8s" >/dev/null
else
  echo "kubectl not found; skipped Kubernetes manifest dry-run" >&2
fi

echo "Epic 03 data schema and Kubernetes manifests match G2 database requirements."
