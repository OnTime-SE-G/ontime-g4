#!/usr/bin/env bash
set -euo pipefail

BASE_URL=${BASE_URL:-http://localhost:8080}
WS_URL=${WS_URL:-ws://localhost:8080/v1/live}

PASS_COUNT=0

print_ok() {
	PASS_COUNT=$((PASS_COUNT + 1))
	echo "[OK] $1"
}

print_skip() {
	echo "[SKIP] $1"
}

check_http() {
	local name=$1
	local path=$2
	local url="${BASE_URL}${path}"
	if curl -fsS "$url" >/dev/null; then
		print_ok "$name"
	else
		echo "[FAIL] $name ($url)" >&2
		exit 1
	fi
}

check_ws() {
	local name=$1
	local url=$2
	if command -v websocat >/dev/null 2>&1; then
		if echo 'ping' | websocat -n1 "$url" >/dev/null 2>&1; then
			print_ok "$name"
		else
			echo "[FAIL] $name ($url)" >&2
			exit 1
		fi
	else
		print_skip "$name (websocat not installed)"
	fi
}

echo "Running smoke tests against: $BASE_URL"

check_http "API gateway connectivity" "/api/v1/status/200"

check_ws "WebSocket live feed" "$WS_URL"

echo "Smoke tests passed ($PASS_COUNT checks)."

