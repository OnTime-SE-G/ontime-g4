#!/usr/bin/env bash
set -euo pipefail

# Apply Kubernetes Secrets from environment variables.
# Intended for CI/CD use (GitHub Actions) with secrets stored in GitHub Secrets.
#
# Required GitHub Secrets (no prefix):
# - POSTGRES_ADMIN_PASSWORD
# - POSTGRES_APP_PASSWORD
# - KEYCLOAK_ADMIN_PASSWORD
# - INFLUXDB_ADMIN_PASSWORD
# - INFLUXDB_ADMIN_TOKEN
# - GRAFANA_ADMIN_PASSWORD
# - FLYWAY_PASSWORD
# - G2_INFLUXDB_TOKEN
#
# Optional environment overrides:
# - GHCR_TOKEN (only needed if packages are private)
# - GHCR_USER (only needed if packages are private)
# - K8S_NAMESPACE
# - POSTGRES_HOST
# - POSTGRES_PORT
# - POSTGRES_DB
# - POSTGRES_APP_USER

NAMESPACE=${K8S_NAMESPACE:-transit-platform}
POSTGRES_HOST=${POSTGRES_HOST:-transit-platform-postgresql}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DB=${POSTGRES_DB:-g4_platform}
POSTGRES_APP_USER=${POSTGRES_APP_USER:-g4_app}

require_env() {
  local name=$1
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required env var: $name" >&2
    exit 1
  fi
}

require_env POSTGRES_ADMIN_PASSWORD
require_env POSTGRES_APP_PASSWORD
require_env KEYCLOAK_ADMIN_PASSWORD
require_env INFLUXDB_ADMIN_PASSWORD
require_env INFLUXDB_ADMIN_TOKEN
require_env GRAFANA_ADMIN_PASSWORD
require_env FLYWAY_PASSWORD
require_env G2_INFLUXDB_TOKEN

DATABASE_URL="postgresql://${POSTGRES_APP_USER}:${POSTGRES_APP_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"

kubectl -n "$NAMESPACE" create secret generic transit-platform-postgresql-auth \
  --from-literal=postgres-password="$POSTGRES_ADMIN_PASSWORD" \
  --from-literal=password="$POSTGRES_APP_PASSWORD" \
  --from-literal=replication-password="$POSTGRES_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic transit-platform-keycloak-auth \
  --from-literal=admin-password="$KEYCLOAK_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic transit-platform-influxdb-auth \
  --from-literal=admin-user-password="$INFLUXDB_ADMIN_PASSWORD" \
  --from-literal=admin-user-token="$INFLUXDB_ADMIN_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic transit-platform-grafana-admin \
  --from-literal=admin-password="$GRAFANA_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic transit-platform-flyway \
  --from-literal=FLYWAY_PASSWORD="$FLYWAY_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic g2-api-gateway-secret \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic g2-route-service-secret \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic g2-fleet-management-secret \
  --from-literal=DATABASE_URL="$DATABASE_URL" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret generic g2-stream-processing-secret \
  --from-literal=INFLUXDB_TOKEN="$G2_INFLUXDB_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -

if [[ -n "${GHCR_TOKEN:-}" && -n "${GHCR_USER:-}" ]]; then
  echo "Applying GHCR pull secrets..."
  kubectl -n "$NAMESPACE" create secret generic ghcr-credentials \
    --type=kubernetes.io/dockerconfigjson \
    --from-literal=.dockerconfigjson="$(kubectl create secret docker-registry ghcr-credentials \
      --docker-server=ghcr.io \
      --docker-username="$GHCR_USER" \
      --docker-password="$GHCR_TOKEN" \
      --docker-email="not-needed@ontime.lk" \
      --dry-run=client -o jsonpath='{.data.\.dockerconfigjson}')" \
    --dry-run=client -o yaml | kubectl apply -f -
else
  echo "GHCR_TOKEN not provided, skipping pull secret creation (assuming public packages)."
fi

echo "Secrets applied to namespace: $NAMESPACE"
