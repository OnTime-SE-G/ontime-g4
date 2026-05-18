#!/usr/bin/env bash
# fetch-latest-tags.sh
#
# Queries the GitHub Container Registry (GHCR) API to find the most recently
# pushed image tag for each G2 service and each frontend app.
#
# Outputs shell variable assignments (source-able or eval-able):
#   G2_IMAGE_TAG=sha-abc1234
#   ADMIN_WEB_IMAGE_TAG=abc1234def...
#   DRIVER_WEB_IMAGE_TAG=abc1234def...
#   PASSENGER_WEB_IMAGE_TAG=abc1234def...
#
# Usage:
#   export GHCR_TOKEN=<GitHub token>
#   eval "$(bash scripts/fetch-latest-tags.sh)"
#   echo "$G2_IMAGE_TAG"
#
# All packages are public. In GitHub Actions GITHUB_TOKEN is sufficient.
# Locally, use a classic PAT with read:packages scope.

set -euo pipefail

GHCR_TOKEN=${GHCR_TOKEN:-}
GITHUB_ORG=${GITHUB_ORG:-ontime-se-g}

if [[ -z "$GHCR_TOKEN" ]]; then
  echo "Error: GHCR_TOKEN is required." >&2
  exit 1
fi

# ── Helpers ──────────────────────────────────────────────────────────────────

# Query the latest version of a GHCR container package and extract its first tag.
# Args: <package-name>   e.g.  "ontime-g2/api-gateway"
get_latest_tag() {
  local pkg=$1
  local encoded_pkg
  # URL-encode the forward slash in the package name
  encoded_pkg=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${pkg}', safe=''))")

  local url="https://api.github.com/orgs/${GITHUB_ORG}/packages/container/${encoded_pkg}/versions?per_page=1"

  local response
  response=$(curl -fsSL \
    -H "Authorization: Bearer ${GHCR_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$url")

  # The API returns an array of versions sorted newest-first.
  # Each version has a metadata.container.tags array.
  # We pick the first non-empty, non-"latest" tag.
  local tag
  tag=$(echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not data:
    print('')
    sys.exit(0)
tags = data[0].get('metadata', {}).get('container', {}).get('tags', [])
# Prefer sha- prefixed tags; fallback to any non-'latest' tag
sha_tags = [t for t in tags if t.startswith('sha-')]
other_tags = [t for t in tags if t != 'latest']
chosen = (sha_tags or other_tags or tags or [''])
print(chosen[0])
")

  echo "$tag"
}

# ── G2 services — all share one image tag per release ────────────────────────
# Any one service is representative; we use api-gateway.
G2_TAG=$(get_latest_tag "ontime-g2/api-gateway")

# ── Frontend apps — each has its own image and independent release ────────────
ADMIN_TAG=$(get_latest_tag    "ontime-frontend/ontime-admin-web")
DRIVER_TAG=$(get_latest_tag   "ontime-frontend/ontime-driver-web")
PASSENGER_TAG=$(get_latest_tag "ontime-frontend/ontime-passenger-web")

# ── Emit assignments ─────────────────────────────────────────────────────────
echo "G2_IMAGE_TAG=${G2_TAG}"
echo "ADMIN_WEB_IMAGE_TAG=${ADMIN_TAG}"
echo "DRIVER_WEB_IMAGE_TAG=${DRIVER_TAG}"
echo "PASSENGER_WEB_IMAGE_TAG=${PASSENGER_TAG}"
