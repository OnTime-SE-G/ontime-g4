# Grafana Dashboards

This directory contains the exported JSON definitions for custom dashboards.

## Dashboards

### `g4-golden-signals.json`
This is the primary operational dashboard for the G4 Platform. It follows the **Four Golden Signals** monitoring philosophy:
1. **Latency**: Time it takes to service a request (e.g., P95 response time).
2. **Traffic**: Demand placed on the system (e.g., HTTP requests per second).
3. **Errors**: Rate of requests that fail (e.g., 5xx error percentage).
4. **Saturation**: How "full" the service is (e.g., CPU and Memory usage).

The dashboard also includes:
- **Kafka Consumer Lag**: Monitoring delay in processing GPS data.
- **MQTT Connected Clients**: Tracking active G1 devices.
- **End-to-End Latency**: The total time from GPS capture to UI update.

## Importing
These files are automatically imported by Grafana via the provisioning configuration in `../provisioning/dashboards/dashboards.yaml`.
