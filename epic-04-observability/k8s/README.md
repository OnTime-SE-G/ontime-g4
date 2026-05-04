# Kubernetes Manifests (Observability)

This directory contains the Kubernetes Custom Resource Definitions (CRDs) and deployment manifests for the G4 observability stack.

## Contents

- `hpa/`: Subdirectory containing Horizontal Pod Autoscaler policies.
- `prometheus-values.yaml`: Helm overrides for the `kube-prometheus-stack` (sets retention to 15 days).
- `prometheus-servicemonitor.yaml`: ServiceMonitor CRDs that tell Prometheus which G1/G2/G3 services to scrape.
- `alerting-rules.yaml`: PrometheusRule CRDs defining critical alerts (G4-31).
- `grafana-deployment.yaml`: Manifests for Grafana admin secrets and Kong Ingress routing.
- `loki-values.yaml`: Helm overrides for Loki log aggregation.

## How it works

The observability stack is primarily managed via the **Prometheus Operator**. 
- **ServiceMonitors**: Instead of editing a central `prometheus.yml`, we create `ServiceMonitor` objects. The operator detects these and automatically reconfigures Prometheus to scrape the new targets.
- **PrometheusRules**: Similarly, alerting rules are managed as Kubernetes objects.

This allows individual teams to manage their own monitoring configuration without touching the core infrastructure files.
