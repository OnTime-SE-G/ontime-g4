# Epic 04 Observability

This folder is for Prometheus, Grafana, Loki, Jaeger, alerts, dashboards, and HPA observability support.

## What belongs here

1. Prometheus scrape and alert configuration.
2. Grafana provisioning and dashboard JSON.
3. Loki and Promtail setup.
4. Jaeger and tracing configuration.
5. HPA manifests and verification scripts.

## Issue order

1. G4-28 Deploy Prometheus and scrape jobs.
2. G4-29 Deploy Grafana and connect Prometheus.
3. G4-30 Build the golden signals dashboard.
4. G4-31 Configure Prometheus alerting rules.
5. G4-32 Deploy Loki and Promtail.
6. G4-33 Deploy Jaeger tracing.
7. G4-34 Configure HPA for four deployments.
8. G4-35 Run the scale-up load test.

## Key references

1. SDD section 8.1 for observability namespace placement.
2. SDD section 8.2 for HPA policy values.
3. SRS requirement FR-G4-04.
4. SRS requirements NFR-SUP-01, NFR-PERF-01, and NFR-PERF-03.

## Start here

1. Keep dashboard and alert changes reproducible.
2. Use the stub services until the full stack is online.
3. Verify target health and metrics visibility before adding new alerts.

## Local Development & Setup

To start the observability stack locally, navigate to this folder and run:
```bash
docker compose up -d
```

### Testing (G4-28)
To verify that Prometheus is running and scraping targets correctly, run the verification script:
```bash
bash tests/verify-metrics.sh
```
Prometheus UI is available at [http://localhost:9090](http://localhost:9090).
