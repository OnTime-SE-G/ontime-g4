#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)

CHART_DIR=${CHART_DIR:-"${REPO_ROOT}/epic-05-cicd/helm/transit-platform"}
VALUES_FILE=${VALUES_FILE:-"${CHART_DIR}/values-staging.yaml"}
RELEASE_NAME=${RELEASE_NAME:-transit-platform}
PLATFORM_NAMESPACE=${PLATFORM_NAMESPACE:-transit-platform}
TIMEOUT=${TIMEOUT:-10m}

CREATE_NAMESPACES=${CREATE_NAMESPACES:-true}
INSTALL_PLATFORM=${INSTALL_PLATFORM:-false}
APPLY_SECRETS=${APPLY_SECRETS:-false}

NAMESPACES=(
	transit-edge
	transit-streaming
	transit-intelligence
	transit-ui
	transit-data
	transit-platform
)

require_cmd() {
	local name=$1
	if ! command -v "$name" >/dev/null 2>&1; then
		echo "Missing required command: $name" >&2
		exit 1
	fi
}

ensure_namespace() {
	local ns=$1
	if kubectl get namespace "$ns" >/dev/null 2>&1; then
		return 0
	fi
	kubectl create namespace "$ns"
}

require_cmd kubectl
require_cmd helm

echo "Using kube context: $(kubectl config current-context)"

if [[ "$CREATE_NAMESPACES" == "true" ]]; then
	echo "Creating namespaces (if missing)..."
	for ns in "${NAMESPACES[@]}"; do
		ensure_namespace "$ns"
	done
fi

if [[ ! -d "${CHART_DIR}/charts" || -z "$(ls -A "${CHART_DIR}/charts" 2>/dev/null)" ]]; then
	echo "Building Helm dependencies..."
	helm dependency build "$CHART_DIR"
fi

if [[ "$APPLY_SECRETS" == "true" ]]; then
	echo "Applying platform secrets..."
	bash "${SCRIPT_DIR}/apply-secrets.sh"
fi

if [[ "$INSTALL_PLATFORM" == "true" ]]; then
	echo "Installing/upgrading Helm release: $RELEASE_NAME"
	helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
		-n "$PLATFORM_NAMESPACE" --create-namespace \
		-f "$VALUES_FILE" \
		--wait --timeout "$TIMEOUT"
fi

cat <<EOF
Bootstrap complete.

Next steps:
- Apply secrets: APPLY_SECRETS=true ${SCRIPT_DIR}/bootstrap-cluster.sh
- Install platform: INSTALL_PLATFORM=true ${SCRIPT_DIR}/bootstrap-cluster.sh
EOF

