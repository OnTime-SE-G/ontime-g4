# Epic 05 CI CD

This folder is for the delivery pipeline, Helm packaging, cluster bootstrap, and release support.

## What belongs here

1. GitHub Actions workflows for lint, tests, build, integration, and deploy.
2. Helm charts for the platform and supporting services.
3. Cluster bootstrap and rollout scripts.
4. Smoke tests and security checks for release gates.
5. Rollback notes and deployment support.

## Issue order

1. G4-36 Build the CI pipeline.
2. G4-37 Create release and deployment notes.
3. G4-38 Prepare the Digital Ocean cluster bootstrap.
4. G4-39 Provision the staging Kubernetes cluster.
5. G4-40 Add Helm charts for shared services.
6. G4-41 Build the umbrella transit-platform Helm chart.
7. G4-42 Add smoke test automation to the pipeline.
8. G4-43 Add the full smoke test suite.
9. G4-44 Add deployment and rollback documentation.
10. G4-45 Add the incident response runbook.

## Key references

1. SDD section 8.3 for the six-stage CI CD pipeline.
2. SDD section 8.1 for namespace layout.
3. G4 guide sections 2, 3, 6, and 8 for repository and PR flow.

## Documentation

- **[Environments & Secrets](../../docs/ci-cd/environments.md)** — DOKS cluster, Kubernetes namespaces, secret strategy
- **[GitHub Actions Secrets](../../docs/ci-cd/ghcr-secrets.md)** — Required secrets and GHCR configuration
- **[Kong Routing](../../docs/ci-cd/kong-routing.md)** — API Gateway routing to G2 services
- **[G2 Image Tags](../../docs/ci-cd/g2-image-tags.md)** — Image tag strategies and deployment procedures
- **[Release & Rollback](../../docs/ci-cd/release-rollback.md)** — Manual release steps, canary flow, rollback
- **[Incident Runbook](../../docs/ci-cd/incident-runbook.md)** — Troubleshooting common issues

## Start here

1. Keep Helm values free of secrets.
2. Make rollout steps reproducible and documented.
3. Verify the pipeline before adding new deployment logic.

Secrets for staging are sourced from GitHub Actions secrets and applied to the
cluster using epic-05-cicd/scripts/apply-secrets.sh. Do not commit secret values
to YAML files.

## Release and incident docs

- [docs/ci-cd/release-rollback.md](docs/ci-cd/release-rollback.md)
- [docs/ci-cd/incident-runbook.md](docs/ci-cd/incident-runbook.md)

## Environment targets (epic-05)

- Primary cluster: DigitalOcean DOKS (staging).
- Secrets: plain Kubernetes Secrets for staging.
- Service mesh (Istio/Linkerd): not in scope for epic-05.

See [docs/ci-cd/environments.md](docs/ci-cd/environments.md) for the full environment layout and Helm release plan.

## G4-37 GHCR and secrets

See docs/ci-cd/ghcr-secrets.md for GHCR setup and required GitHub Actions secrets.


