# Horizontal Pod Autoscalers (HPA)

This directory contains the auto-scaling policies for the critical components of the OnTime G4 platform.

## HPAs

### `commuter-nextjs-hpa.yaml`
Scales the G3 frontend based on CPU utilization (>70%) and concurrent WebSocket connections (>1000/pod).

### `socket-io-hpa.yaml`
Scales the Socket.IO adapter based on CPU utilization (>65%).

### `flink-hpa.yaml`
Scales the G2 Flink TaskManagers based on CPU (>75%) and Kafka consumer lag (>10000 messages). High lag triggers scaling to ensure real-time data processing.

### `eta-grpc-hpa.yaml`
Scales the ETA prediction service based on CPU (>70%) and P95 gRPC latency (>400ms).

## How it works
The HPA controller in Kubernetes periodically polls the **Metrics Server** (for CPU/Memory) and the **Prometheus Adapter** (for custom metrics like socket connections or Kafka lag). If a threshold is exceeded, it increases the replica count of the corresponding deployment.
