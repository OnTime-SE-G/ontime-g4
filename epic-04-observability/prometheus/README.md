# Prometheus Configuration

This directory contains the core configuration for Prometheus.

## Contents

- `prometheus.yml`: The main configuration file defining scrape jobs and evaluation intervals.
- `alert-rules.yml`: The alerting rules for the local observability stack.

## Scrape Jobs

Prometheus is configured to collect metrics from:
- **Mosquitto**: MQTT broker metrics via sidecar.
- **Kafka**: Messaging throughput and lag.
- **Kong**: API gateway traffic and errors.
- **Keycloak**: Authentication events.
- **PostgreSQL**: Database health and performance.
- **InfluxDB**: Time-series write performance.

## Alerting

Alerts are evaluated every 15 seconds. If a condition (like high latency) persists for the specified duration (e.g., 30s), the alert transitions to the `FIRING` state. In the staging environment, these are managed via the `PrometheusRule` CRD in the `k8s/` folder.
