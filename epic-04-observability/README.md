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

## Local Development (Phase 1)

For local development without a Kubernetes cluster, we use `docker-compose`. This spins up the full stack alongside placeholder/stub metrics endpoints for testing the dashboards independently.

To start the observability stack locally, navigate to this folder and run:
```bash
docker compose up -d
```

### Testing Local Setup (G4-28)
To verify that Prometheus is running and scraping targets correctly locally:
```bash
bash tests/verify-metrics.sh
```
Prometheus UI is available at [http://localhost:9090](http://localhost:9090).

## Kubernetes Deployment (Phase 2 Integration)

For integration and deployment to the Digital Ocean cluster, the Observability stack uses the `kube-prometheus-stack` Helm chart along with custom `ServiceMonitor` CRDs for cross-team scraping.

### Prometheus Installation (G4-28)

1. Add the Helm repository and install the stack. We pass the 15-day retention policy and selector rules via inline flags to strictly maintain the G4 folder structure:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  -n transit-platform --create-namespace \
  --set prometheus.prometheusSpec.retention=15d \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false
```

2. Apply the custom ServiceMonitors to scrape G1/G2/G3 targets (Mosquitto, Kafka, Kong, Keycloak, PostgreSQL, InfluxDB):
```bash
kubectl apply -f k8s/prometheus-servicemonitor.yaml
```

3. Verification: Port-forward Prometheus and check the UI for the targets:
```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n transit-platform
# Open http://localhost:9090/targets
```
