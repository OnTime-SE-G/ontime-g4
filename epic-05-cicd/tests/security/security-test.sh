#!/usr/bin/env bash
set -euo pipefail

BASE_URL=${BASE_URL:-http://localhost:8080}

require_cmd() {
	local name=$1
	if ! command -v "$name" >/dev/null 2>&1; then
		echo "Missing required command: $name" >&2
		exit 1
	fi
}

require_cmd curl

echo "Running security checks against: $BASE_URL"

status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/v1/scheduler/dispatch" || true)
if [[ "$status" == "401" || "$status" == "403" ]]; then
	echo "[OK] Unauthorized scheduler dispatch is blocked ($status)."
else
	echo "[FAIL] Scheduler dispatch should be blocked (got $status)." >&2
	exit 1
fi

status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/driver/status" || true)
if [[ "$status" == "401" || "$status" == "403" ]]; then
	echo "[OK] Unauthorized driver status is blocked ($status)."
else
	echo "[FAIL] Driver status should be blocked (got $status)." >&2
	exit 1
fi

echo "Security checks passed."

