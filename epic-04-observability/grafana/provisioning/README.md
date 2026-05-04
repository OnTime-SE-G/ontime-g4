# Grafana Provisioning

This directory contains the "infrastructure-as-code" configuration for Grafana.

## Structure

- `datasources/`: Contains YAML files defining the external data sources (Prometheus, Loki, Jaeger).
- `dashboards/`: Contains YAML files defining where Grafana should look for dashboard JSON files to auto-import.

## Key Files

### `datasources/datasources.yaml`
Registers **Prometheus** as the default data source. It also connects to **Loki** for logs and **Jaeger** for traces.

### `dashboards/dashboards.yaml`
Configures a "provider" that scans the `epic-04-observability/grafana/dashboards` directory every 10 seconds and keeps Grafana in sync with the JSON files there.

## Implementation Detail
In Kubernetes, these files are typically mounted into the Grafana pod via a ConfigMap or handled by the `kube-prometheus-stack` operators. Locally, they are mounted via Docker Compose volumes.
