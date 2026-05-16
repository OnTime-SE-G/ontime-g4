#!/bin/bash
# DEPRECATED: This script is no longer used.
# Kong runs in dbless mode with KONG_DECLARATIVE_CONFIG mounted from ConfigMap.
# The admin API is disabled (admin.enabled: false) so this script cannot connect.
# The Kong declarative config is managed in values.yaml under kong.configMap.config
# and rendered by the kong-declarative-config.yaml Helm template.
#
# This file is kept for historical reference only.

echo "DEPRECATED: Kong is running in dbless mode. Configuration is managed via Helm values."
echo "See: epic-05-cicd/helm/transit-platform/values.yaml → kong.configMap.config"
exit 0
KONG_RELEASE="${2:-transit-platform}"

# Wait for Kong to be ready
echo "Waiting for Kong admin API to be ready..."
kubectl rollout status deployment/"${KONG_RELEASE}"-kong -n "${KONG_NAMESPACE}" --timeout=5m

# Get Kong admin service IP (Kong uses admin on port 8001 internally)
echo "Retrieving Kong admin API endpoint..."
KONG_ADMIN_IP=$(kubectl get svc "${KONG_RELEASE}"-kong-admin -n "${KONG_NAMESPACE}" -o jsonpath='{.spec.clusterIP}')

if [ -z "$KONG_ADMIN_IP" ]; then
  echo "ERROR: Could not find Kong admin service"
  exit 1
fi

KONG_ADMIN_URL="http://${KONG_ADMIN_IP}:8001"

echo "Kong Admin URL: ${KONG_ADMIN_URL}"

# Retrieve declarative config from ConfigMap
echo "Retrieving Kong declarative config from ConfigMap..."
KONG_CONFIG=$(kubectl get configmap "${KONG_RELEASE}"-kong-declarative -n "${KONG_NAMESPACE}" -o jsonpath='{.data.kong\.yaml}' 2>/dev/null || true)

if [ -z "$KONG_CONFIG" ]; then
  echo "WARNING: Kong declarative config ConfigMap not found. Skipping Kong config application."
  exit 0
fi

# Create temporary file with config
TEMP_CONFIG=$(mktemp)
echo "$KONG_CONFIG" > "$TEMP_CONFIG"
trap 'rm -f "$TEMP_CONFIG"' EXIT

# Apply declarative config via POST /config
echo "Applying Kong declarative configuration..."
curl -X POST "${KONG_ADMIN_URL}"/config \
  -H "Content-Type: application/yaml" \
  --data-binary @"$TEMP_CONFIG" \
  --silent --show-error \
  || {
    echo "WARNING: Failed to apply Kong config. Kong may be using dbless mode without direct API updates."
    echo "Config should be provided via KONG_DECLARATIVE_CONFIG environment variable."
  }

echo "Kong configuration applied successfully."
