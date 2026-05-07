# G2 Microservices Deployment Strategy

## Overview
All 7 G2 microservices are managed by the `g2-services` Helm subchart within the `transit-platform` umbrella chart. Image tags are configurable per-service to support different deployment strategies.

## Service List
- `api-gateway` — Main REST API entry point (port 8000)
- `route-service` — Route management and planning (port 8002)
- `fleet-management-service` — Vehicle and driver management (port 8003)
- `ingestion` — MQTT/Kafka data ingestion pipeline (port 8001)
- `websocket-service` — Real-time updates via WebSocket (port 8004)
- `anomaly-service` — Real-time anomaly detection (port 8006)
- `stream-processing` — Kafka stream processing for telemetry (port 8081)

## Image Tag Strategies

### Strategy 1: Manual Tag Updates (Current)
**When to use:** For stable releases or when you want explicit control over which commit is deployed.

**Steps:**
1. Update image tags in `epic-05-cicd/helm/transit-platform/values.yaml`:
   ```yaml
   g2-services:
     services:
       api-gateway:
         image:
           tag: sha-<new-commit-sha>
   ```

2. Deploy:
   ```bash
   helm upgrade --install transit-platform ./epic-05-cicd/helm/transit-platform \
     -n transit-platform \
     -f values.yaml \
     -f values-staging.yaml
   ```

**Pros:**
- Explicit, auditable changes
- Simple to understand
- Works well with GitOps

**Cons:**
- Manual process prone to errors
- Requires editing files per release

---

### Strategy 2: Environment Variable Override (Recommended for CI/CD)
**When to use:** For automated deployments from CI/CD pipelines.

**Usage:**
```bash
# Use rollout script with image tag override
export G2_IMAGE_TAG=sha-<commit-sha>
./epic-05-cicd/scripts/rollout-canary.sh --mode promote
```

**What happens:**
- The rollout script automatically updates all 7 service image tags
- Useful for deploying latest commit from main branch
- Can be called from `.github/workflows/ci.yml` deploy job

**Configuration in CI:**
```yaml
- name: Deploy G2 services
  env:
    G2_IMAGE_TAG: ${{ github.sha }}  # Use short commit SHA
  run: |
    ./epic-05-cicd/scripts/rollout-canary.sh --mode promote
```

**Pros:**
- Fully automated
- Integrates naturally with CI/CD
- Same image tag for all services ensures consistency

**Cons:**
- Requires external script
- Less granular (all services updated together)

---

### Strategy 3: Canary Deployment with Image Override
**When to use:** For testing before full rollout.

**Steps:**
```bash
# Deploy single replica for testing
export G2_IMAGE_TAG=sha-<new-sha>
./epic-05-cicd/scripts/rollout-canary.sh --mode canary --canary-replicas 1

# Run smoke tests
./epic-05-cicd/tests/smoke-test.sh --base-url http://<kong-lb-ip>

# Promote if tests pass
./epic-05-cicd/scripts/rollout-canary.sh --mode promote
```

**Pros:**
- Minimize blast radius of bad deployments
- Test before full rollout
- Easy rollback to previous replicas

**Cons:**
- Extra steps compared to direct deploy

---

## Current Implementation

All values use the format: `sha-<7-char-commit-sha>`

Example:
```yaml
api-gateway:
  image:
    tag: sha-ed25d77  # Points to commit ed25d77
```

This format matches GHCR image tagging where:
- Images are built and pushed to GHCR on every push to main
- Tag is generated as `sha-<commit-sha>`
- Kubernetes pulls by exact tag, preventing accidental upgrades

---

## Recommended Workflow

1. **Local development:** No changes needed; use latest from main
2. **Staging deployment:** Use rollout script with `MODE=canary` for testing
3. **Production deployment:** Use rollout script with `MODE=promote` after validation

Example promotion script:
```bash
#!/bin/bash
set -e

COMMIT_SHA=$1
NAMESPACE="transit-platform"

# Deploy canary
export G2_IMAGE_TAG=sha-${COMMIT_SHA:0:7}
./epic-05-cicd/scripts/rollout-canary.sh --mode canary --canary-replicas 1

# Wait for canary to stabilize
sleep 30

# Run smoke tests
./epic-05-cicd/tests/smoke-test.sh --base-url http://kong-lb:8000

# Promote if tests pass
./epic-05-cicd/scripts/rollout-canary.sh --mode promote

echo "Deployment complete: sha-${COMMIT_SHA:0:7}"
```

---

## Rollback Procedure

If deployment causes issues:

```bash
# Rollback to previous Helm release
helm rollback transit-platform -n transit-platform

# Or manually scale down affected service
kubectl scale deployment transit-platform-g2-api-gateway -n transit-platform --replicas 0

# Fix image tag and redeploy
export G2_IMAGE_TAG=sha-<good-commit>
./epic-05-cicd/scripts/rollout-canary.sh --mode promote
```

---

## See Also
- [Release & Rollback Guide](release-rollback.md)
- [Incident Runbook](incident-runbook.md)
- [rollout-canary.sh Script](../scripts/rollout-canary.sh)
