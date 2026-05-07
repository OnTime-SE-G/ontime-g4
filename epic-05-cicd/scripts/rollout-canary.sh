#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)

CHART_DIR=${CHART_DIR:-"${REPO_ROOT}/epic-05-cicd/helm/transit-platform"}
VALUES_FILE=${VALUES_FILE:-"${CHART_DIR}/values-staging.yaml"}
RELEASE_NAME=${RELEASE_NAME:-transit-platform}
NAMESPACE=${NAMESPACE:-transit-platform}
MODE=${MODE:-canary} # canary | promote
TIMEOUT=${TIMEOUT:-10m}

CANARY_REPLICAS=${CANARY_REPLICAS:-1}
G2_IMAGE_TAG=${G2_IMAGE_TAG:-}

require_cmd() {
	local name=$1
	if ! command -v "$name" >/dev/null 2>&1; then
		echo "Missing required command: $name" >&2
		exit 1
	fi
}

require_cmd kubectl
require_cmd helm

set_image_tag_args() {
	if [[ -z "$G2_IMAGE_TAG" ]]; then
		return 0
	fi
	echo "--set g2-services.services.api-gateway.image.tag=${G2_IMAGE_TAG}"
	echo "--set g2-services.services.route-service.image.tag=${G2_IMAGE_TAG}"
	echo "--set g2-services.services.fleet-management-service.image.tag=${G2_IMAGE_TAG}"
	echo "--set g2-services.services.ingestion.image.tag=${G2_IMAGE_TAG}"
	echo "--set g2-services.services.websocket-service.image.tag=${G2_IMAGE_TAG}"
	echo "--set g2-services.services.anomaly-service.image.tag=${G2_IMAGE_TAG}"
	echo "--set g2-services.services.stream-processing.image.tag=${G2_IMAGE_TAG}"
}

rollout_status() {
	local deployments
	deployments=$(kubectl get deploy -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME" -o name)
	if [[ -z "$deployments" ]]; then
		echo "No deployments found for release: $RELEASE_NAME" >&2
		return 1
	fi
	while IFS= read -r dep; do
		kubectl rollout status "$dep" -n "$NAMESPACE" --timeout="$TIMEOUT"
	done <<< "$deployments"
}

if [[ "$MODE" != "canary" && "$MODE" != "promote" ]]; then
	echo "Invalid MODE: $MODE (use 'canary' or 'promote')" >&2
	exit 1
fi

echo "Rolling out in mode: $MODE"
echo "Release: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"

if [[ "$MODE" == "canary" ]]; then
	set -o pipefail
	mapfile -t image_args < <(set_image_tag_args)

	helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
		-n "$NAMESPACE" --create-namespace \
		-f "$VALUES_FILE" \
		--set flyway-job.enabled=false \
		--set g2-services.services.api-gateway.replicaCount="$CANARY_REPLICAS" \
		--set g2-services.services.route-service.replicaCount="$CANARY_REPLICAS" \
		--set g2-services.services.fleet-management-service.replicaCount="$CANARY_REPLICAS" \
		--set g2-services.services.ingestion.replicaCount="$CANARY_REPLICAS" \
		--set g2-services.services.websocket-service.replicaCount="$CANARY_REPLICAS" \
		--set g2-services.services.anomaly-service.replicaCount="$CANARY_REPLICAS" \
		--set g2-services.services.stream-processing.replicaCount="$CANARY_REPLICAS" \
		"${image_args[@]}" \
		--wait --timeout "$TIMEOUT"

	rollout_status
	echo "Canary rollout complete."
	exit 0
fi

mapfile -t image_args < <(set_image_tag_args)
helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
	-n "$NAMESPACE" --create-namespace \
	-f "$VALUES_FILE" \
	"${image_args[@]}" \
	--wait --timeout "$TIMEOUT"

rollout_status
echo "Promotion complete."

