# G4 Environments and Scope

This document defines the target environments, cluster assumptions, and Helm release layout for epic-05 (CI/CD + Helm + deployment support).

## Target Environments

### Staging (Primary)
- Cluster: DigitalOcean Kubernetes (DOKS)
- Purpose: shared integration, smoke tests, pre-release validation
- Namespace layout (from SDD 8.1):
  - transit-edge
  - transit-streaming
  - transit-intelligence
  - transit-ui
  - transit-data
  - transit-platform

### Production (Future)
- Not in scope for epic-05 implementation.
- Any production-specific hardening is documented but not executed.

## Helm Release Layout

- Umbrella chart: transit-platform
- Local subcharts: mosquitto, flyway-job, g2-services
- External dependencies: postgresql, kafka, kong, keycloak, influxdb, prometheus, grafana, redis

Recommended release name:
- staging: transit-platform

Values files:
- values.yaml (baseline)
- values-staging.yaml (resource limits and DOKS-specific settings)

## Secrets Strategy

Secrets are managed as plain Kubernetes Secrets for staging.

Required secrets (staging) are sourced from GitHub Actions secrets and applied
to the cluster using the apply script:
- epic-05-cicd/scripts/apply-secrets.sh

Secret values should not be committed to YAML files.
The template file is for reference only.

No service mesh (Istio/Linkerd) is configured in epic-05.

## CI/CD Scope

Epic-05 delivers:
- Helm packaging and environment values
- CI pipeline (lint/test/build/publish)
- CD pipeline (deploy to DOKS)
- Smoke and security test gates
- Bootstrap and rollout scripts
- Release and rollback documentation
