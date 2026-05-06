# Grafana Configuration

This directory contains the configuration and dashboard definitions for Grafana.

## Contents

- `dashboards/`: Contains JSON definitions for custom G4 dashboards.
- `provisioning/`: Contains YAML files that tell Grafana how to automatically load data sources and dashboards.

## How it works

In this project, we use Grafana's **Provisioning** feature. Instead of manually creating dashboards and data sources in the UI, we define them as code. 
- When the Grafana container starts (either in Docker Compose or Kubernetes), it reads the files in the `provisioning/` folder.
- It automatically connects to the **Prometheus** data source defined in `provisioning/datasources/`.
- It automatically imports all dashboards found in the `dashboards/` folder.

This ensures that the observability setup is reproducible and version-controlled.
