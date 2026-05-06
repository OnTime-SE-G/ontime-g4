# Observability Tests & Verification

This directory contains scripts to verify the correctness of the observability stack and its compliance with the project's non-functional requirements (NFRs).

## Scripts

### `verify-metrics.sh`
Used for local testing with Docker Compose. It checks if Prometheus is up and can successfully scrape the core targets.

### `verify-staging.sh`
The primary acceptance test for the staging environment. It verifies:
- Prometheus pod health and 15-day retention.
- Connectivity to scrape targets (Kong, Postgres).
- Presence of Alerting Rules (G4-31).
- Loki and Promtail deployment (G4-32).
- Jaeger tracing accessibility (G4-33).
- HPA configuration for all 4 deployments (G4-34).

### `verify-hpa-scaling.sh`
A manual load-testing script for **G4-35**. It provides instructions on how to generate artificial CPU load and observe the HPA scaling the number of replicas automatically.

## Usage
Always run these scripts after making changes to the manifests or configuration to ensure no regression has occurred.
