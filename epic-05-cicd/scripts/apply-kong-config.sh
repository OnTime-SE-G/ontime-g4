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
