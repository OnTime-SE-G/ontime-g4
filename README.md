# 🚉 OnTime: G4 Platform & DevOps Infrastructure
**Group G — SE3080 / SE3070 Software Engineering Project**  
**Increment 1:** Moratuwa–Kadawatha Expressway Corridor

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Kafka](https://img.shields.io/badge/Apache%20Kafka-000?style=for-the-badge&logo=apachekafka)
![Redis](https://img.shields.io/badge/redis-%23DD0031.svg?style=for-the-badge&logo=redis&logoColor=white)
![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)

---

## 📖 Overview

This repository contains the **Infrastructure-as-Code (IaC)** for the OnTime Public Transport Tracking System. Managed by the **G4 Sub-Team**, these Kubernetes manifests define the highly available messaging backbone, databases, security gateways, and CI/CD pipelines that power the entire microservices architecture.

---

## 🔄 End-to-End Data Flow

This diagram shows how data moves across all four sub-teams, and which team owns each component.

```text
[ G1: Edge Systems (ESP32 on Bus) ]
      │
      │ 📡 MQTT Publish
      │ Topic: transport/bus/{busId}/location
      ▼
[ G4: HiveMQ MQTT Broker ]          ◄── G4 Infrastructure
      │
      │ 📥 MQTT Subscribe
      ▼
[ G2: Ingestion Service ]            ◄── G2 Custom Python App
      │
      │ 📨 Kafka Produce
      │ Topic: transport-telemetry-raw
      ▼
[ G4: KRaft Kafka Cluster ]         ◄── G4 Infrastructure
      │
      │ 📤 Kafka Consume
      ▼
[ G2: Flink Stream Processor ]       ◄── G2 ML / Logic Brain
      │
      ├──► 💾 Kafka Produce: transport-telemetry-cleaned   (Enriched Data)
      ├──► 🚨 Kafka Produce: transport-anomaly-alerts      (Breakdowns)
      │
      ├──► ⚡ Redis Publish: fleet:live                    (Live Map Data)
      └──► ⚡ Redis Publish: eta:live                      (Prediction Data)
      │
      ▼
[ G4: Redis Cluster ]               ◄── G4 Infrastructure
      │
      │ 🎧 Redis Subscribe
      ▼
[ G2: WebSocket Service ]            ◄── G2 Custom FastAPI App
      │
      │ 🌐 WebSocket Push
      ▼
[ G4: Kong API Gateway ]            ◄── G4 Security / Auth Layer
      │
      │ 🔐 Secure WebSocket Connection
      │ Route: wss://api.ontime.lk/v1/live
      ▼
[ G3: Commuter & Driver Apps ]       ◄── G3 React Native / Next.js UIs
```

---

## 🏗️ System Architecture (Current State)

The infrastructure has been evolved from the original SDD to seamlessly support G2's Python-based data processing pipelines:

1. **Edge Ingestion (`transit-edge`):** A 3-node **HiveMQ** broker cluster (StatefulSet) receiving 1Hz GPS telemetry from ESP32 devices via TLS 1.3.
2. **Streaming Backbone (`transit-streaming`):** A ZooKeeper-less **KRaft Kafka** cluster (3 brokers). Topics are idempotently initialized via a Kubernetes Job.
3. **Intelligence Layer (`transit-intelligence`):** Hosts G2's custom Python ingestion service which bridges MQTT data into Kafka.
4. **UI Push Layer (`transit-ui`):** A **Redis** cluster managing Pub/Sub channels (`fleet:live`, `eta:live`) and Socket.IO state for G2's FastAPI WebSocket servers.
5. **Data Layer (`transit-data`):** PostgreSQL/PostGIS (Spatial Data) and InfluxDB (Time-series telemetry).

---

## 📁 Repository Structure

```text
k8s/
├── transit-edge/             # MQTT Edge Ingestion
│   ├── hivemq-configmap.yaml # Ports: 1883 (internal), 8883 (external TLS)
│   └── hivemq-statefulset.yaml
├── transit-streaming/        # Core Kafka Backbone
│   ├── kafka-statefulset.yaml
│   └── kafka-topic-creator-job.yaml # Initializes G2 data contracts
├── transit-intelligence/     # ML & Processing Layer
│   └── g2-ingestion-deployment.yaml # G2 Python MQTT->Kafka worker
├── transit-ui/               # Frontend Comm & Cache
│   ├── redis.yaml
│   └── g2-websocket-deployment.yaml # G2 FastAPI WebSocket push
└── transit-platform/         # (Upcoming) Kong Gateway & Keycloak
```
