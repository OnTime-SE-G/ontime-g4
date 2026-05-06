# Jaeger Distributed Tracing

This directory contains configuration for Jaeger, the system used for distributed tracing.

## Contents

- `jaeger-values.yaml`: Helm values for deploying Jaeger on the Kubernetes cluster.

## Purpose

Jaeger helps team members understand the lifecycle of a request as it flows through multiple microservices. 
- **G4-33** implementation provides a central collector for OpenTelemetry (OTLP) traces.
- It allows pinpointing bottlenecks in the data pipeline (e.g., if a GPS update takes > 2s to reach the UI, Jaeger can show exactly which service was slow).

## Deployment
Jaeger is deployed using the official Helm chart in the `transit-platform` namespace. For Increment 1, we use the `all-in-one` strategy which includes the collector, query UI, and memory storage in a single pod.
