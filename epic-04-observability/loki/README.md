# Loki Log Aggregation

This directory contains configuration for Grafana Loki, the system used for log aggregation.

## Contents

- `loki-config.yaml`: Configuration for the Loki server (retention, storage, etc.).

## How it works

Loki works in tandem with **Promtail**:
1. **Promtail**: A logging agent that runs on every node in the cluster. it discovers logs from all pods, attaches labels (like namespace, pod name, and service), and "tails" them to Loki.
2. **Loki**: A datastore that indexes the labels but not the log content (making it very efficient and cost-effective).
3. **Grafana**: Used to query Loki logs using **LogQL**.

## Querying
You can view logs in Grafana by going to the **Explore** tab and selecting the `Loki` data source.
Example query: `{service="kong-gateway"}` - shows all logs from the Kong Gateway.
