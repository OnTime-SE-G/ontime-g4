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

## Start here

1. Keep Helm values free of secrets.
2. Make rollout steps reproducible and documented.
3. Verify the pipeline before adding new deployment logic.

## G4-37 GHCR and secrets

See docs/ci-cd/ghcr-secrets.md for GHCR setup and required GitHub Actions secrets.


