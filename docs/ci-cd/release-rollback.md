# Release and Rollback Guide (G4)

This guide documents the staging release flow, canary rollout, and rollback steps for the transit platform.

## Prerequisites

- Helm and kubectl installed
- Kube context set to the DOKS cluster
- Required GitHub Actions secrets configured
- Staging secrets applied using the apply script

## Standard Release (Staging)

### 1) Apply secrets (if needed)

```bash
K8S_NAMESPACE=transit-platform \
POSTGRES_ADMIN_PASSWORD=... \
POSTGRES_APP_PASSWORD=... \
KEYCLOAK_ADMIN_PASSWORD=... \
INFLUXDB_ADMIN_PASSWORD=... \
INFLUXDB_ADMIN_TOKEN=... \
GRAFANA_ADMIN_PASSWORD=... \
FLYWAY_PASSWORD=... \
G2_INFLUXDB_TOKEN=... \
./epic-05-cicd/scripts/apply-secrets.sh
```

### 2) Deploy platform

```bash
helm upgrade --install transit-platform ./epic-05-cicd/helm/transit-platform \
  -n transit-platform --create-namespace \
  -f ./epic-05-cicd/helm/transit-platform/values-staging.yaml \
  --wait --timeout 10m
```

## Canary Release

Use the canary script to roll out changes with reduced replicas:

```bash
MODE=canary \
CANARY_REPLICAS=1 \
G2_IMAGE_TAG=<commit-sha> \
./epic-05-cicd/scripts/rollout-canary.sh
```

Promote to full rollout:

```bash
MODE=promote \
G2_IMAGE_TAG=<commit-sha> \
./epic-05-cicd/scripts/rollout-canary.sh
```

## Rollback

### 1) Helm rollback

```bash
helm rollback transit-platform 1 -n transit-platform
```

List revisions:

```bash
helm history transit-platform -n transit-platform
```

### 2) Rollback a specific deployment

```bash
kubectl rollout undo deploy/<deployment-name> -n transit-platform
```

## Post-Release Verification

- Run smoke tests:
  ```bash
  BASE_URL=http://<gateway-host> ./epic-05-cicd/tests/smoke-test.sh
  ```
- Run security tests:
  ```bash
  BASE_URL=http://<gateway-host> ./epic-05-cicd/tests/security/security-test.sh
  ```

## Notes

- The CI deploy stage applies secrets using GitHub Actions secrets.
- This guide targets the staging DOKS cluster only.
