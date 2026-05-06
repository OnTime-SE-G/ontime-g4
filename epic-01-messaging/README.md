# Epic 01 Messaging

This folder is for the messaging backbone of OnTime G4. It covers HiveMQ MQTT broker, Kafka (KRaft mode), G2's Python ingestion service, and G2's FastAPI WebSocket service.

> **Architectural Pivot:** G2 built their own MQTT→Kafka ingestion service and FastAPI WebSocket service. G4 deploys their containers onto our core infrastructure. All Kafka topic names have been updated to G2's new naming convention.

## What belongs here

1. HiveMQ broker configuration and TLS certificates.
2. Kafka cluster configuration (KRaft mode, no ZooKeeper) and topic setup.
3. G2 Ingestion Service deployment (Python MQTT→Kafka worker).
4. G2 WebSocket Service deployment (FastAPI live push for G3).
5. Redis deployment for WebSocket pub/sub.
6. Stubs and smoke tests for local verification.

## Issue order

1. G4-01 Deploy HiveMQ MQTT broker (3-node StatefulSet).
2. G4-02 Configure MQTT broker TLS.
3. G4-03 Deploy Apache Kafka cluster (KRaft mode).
4. G4-04 Create and configure the five Kafka topics (G2 naming).
5. G4-05 Deploy G2 Ingestion Service (Python MQTT→Kafka worker).
6. G4-06 Verify the end-to-end MQTT to Kafka flow (G2 schema).
7. G4-07 Deploy G2 WebSocket Service (FastAPI live push).
8. G4-08 Load test the MQTT broker.

## Kafka Topics (G2 Contract)

| Topic | Partitions | Replication | Retention |
|-------|-----------|-------------|-----------|
| `transport-telemetry-raw` | 12 | 3 | 2 hours |
| `transport-telemetry-cleaned` | 6 | 3 | 30 mins |
| `transport-anomaly-alerts` | 3 | 3 | 24 hours |
| `transport-telemetry-dlq` | 3 | 3 | 24 hours |
| `trip.lifecycle` | 3 | 3 | 2 hours |

## Key references

1. SDD section 2.2 for the messaging backbone.
2. SDD section 4.1 for the Kafka topic contract (updated per G2 pivot).
3. SDD section 6.3 for the WebSocket push design.
4. SRS requirements FR-G4-02 and NFR-REL-03.

## Start here

1. Work only inside this folder.
2. Create the epic branch before feature work.
3. Use the local Docker Compose stack for validation.
4. Run the smoke test before opening a PR.

