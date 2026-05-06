# G4 PLATFORM & DEVOPS TEAM — GitHub Issues Registry

> 45 Fully Specified Issues across 5 Epics — Ready to Paste into GitHub

**Project:** Real-Time Public Transport Tracking & ETA Prediction System
**Sub-Team:** G4 — Platform, DevOps & Security
**Epics:** 5 Epics: Messaging · API Gateway & Security · Data Layer · Observability · CI/CD
**Total Issues:** 45 Issues  |  165 Story Points
**SRS / SDD Baseline:** SRS v1.0  ·  SDD v1.0
**Increment:** Increment 1 — Moratuwa–Kadawatha Corridor

🔴 Critical · 🟠 High · 🔵 Medium · 🟢 Low

---

## EPIC-01 — Messaging Backbone — MQTT, Kafka & WebSocket Bridge

Foundation of all real-time data flow. G1 edge GPS data enters here and is delivered to G2 intelligence.
8 Issues · 32 Story Points · Sprint 1–2 start.

---

### G4-01 — Deploy MQTT Broker — 3-node StatefulSet

Deploy a production-grade MQTT broker cluster in the `transit-edge` Kubernetes namespace as a StatefulSet with 3 replicas.

| Issue # | Epic | Priority | Labels | Points | Sprint |
|---------|------|----------|--------|--------|--------|
| G4-01 | EPIC-01: Messaging Backbone | Critical | infrastructure, messaging | 5 | Sprint 1 |

#### 📋  Summary

Deploy a production-grade MQTT broker cluster in the `transit-edge` Kubernetes namespace as a StatefulSet with 3 replicas. This broker is the first point of contact for GPS payloads from G1 edge devices. It must be highly available (3 nodes), persistent (PersistentVolumeClaim per pod), and accessible within the cluster before the MQTT→Kafka bridge (G4-05) can be configured. This is the single highest-priority infrastructure task — nothing in the system can function without it.

#### 🔗  SRS / SDD Reference

- FR-G4-02 — MQTT broker shall sustain 500 simultaneous persistent client connections.
- NFR-REL-04 — P95 queue delay < 500ms under 500-client load.
- SDD §8.1 — `transit-edge` namespace — MQTT Broker StatefulSet (3 replicas).
- SDD §2.2 — Messaging Backbone — MQTT Broker component (G4 owned).

#### 🔧  Technical Notes

- Image: `hivemq/hivemq-ce:latest` (HiveMQ Community Edition)
- Namespace: `transit-edge`
- Kind: StatefulSet with 3 replicas and a headless Service for pod addressing
- Persistence: PersistentVolumeClaim per pod — 2Gi storage (logs + persistence files)
- Config: `config.xml` stored as a Kubernetes ConfigMap. Key settings: TCP listener on port 1883, TLS listener on port 8883
- Service: ClusterIP Service on port 1883 (MQTT) and 8883 (MQTT over TLS) for internal cluster access only
- Health checks: `livenessProbe` and `readinessProbe` using TCP socket check on port 1883

```bash
kubectl apply -f k8s/transit-edge/hivemq-configmap.yaml
kubectl apply -f k8s/transit-edge/hivemq-statefulset.yaml
kubectl apply -f k8s/transit-edge/hivemq-service.yaml
kubectl apply -f k8s/transit-edge/hivemq-headless-service.yaml
```

#### 🎯  Acceptance Criteria

- [ ] Three MQTT broker pods (`hivemq-0`, `hivemq-1`, `hivemq-2`) are in Running state in the `transit-edge` namespace.
- [ ] A test MQTT client (`mosquitto_pub`) can connect to the ClusterIP Service on port 1883 and publish a message successfully.
- [ ] Pod `hivemq-0` is deleted manually; it restarts automatically within 30 seconds with no data loss (PVC retained).
- [ ] `config.xml` is sourced from the ConfigMap — editing the ConfigMap and rolling the pod reflects the change.
- [ ] No credentials are hardcoded in the container spec — all sensitive values reference Kubernetes Secrets.

#### 🔗  Dependencies

None — this Issue can be started independently.

---

### G4-02 — Configure MQTT Broker TLS — Self-Signed Cert (Dev) & Let's Encrypt (Staging)

Secure MQTT broker connections using TLS 1.2+ to prevent plaintext GPS data transmission between G1 devices and the broker.

| Issue # | Epic | Priority | Labels | Points | Sprint |
|---------|------|----------|--------|--------|--------|
| G4-02 | EPIC-01: Messaging Backbone | Critical | security, messaging | 3 | Sprint 1 |

#### 📋  Summary

All G1 edge devices publish GPS payloads containing real-time vehicle location data. Without TLS, these payloads are transmitted in plaintext and vulnerable to interception. This issue configures TLS on the MQTT broker: a self-signed certificate for the local dev environment and a Let's Encrypt certificate for the Digital Ocean staging environment. All G1 MQTT clients must be updated to connect over TLS port 8883.

#### 🔗  SRS / SDD Reference

- NFR-SEC-03 — All data in transit shall be encrypted using TLS 1.2 or higher.
- SDD §3.4 — MQTT topic `transport/{bus_id}/location` — uses TLS connection from G1 client.
- SDD §7.1 — Security enforced at network ingress layer.

#### 🔧  Technical Notes

- Dev cert: Generate with: `openssl req -x509 -newkey rsa:4096 -keyout ca.key -out ca.crt -days 365 -nodes`
- Staging cert: Provision via cert-manager Kubernetes operator with Let's Encrypt ClusterIssuer
- HiveMQ config additions: TLS TCP listener block in `config.xml` referencing keystore at `/opt/hivemq/certs/keystore.p12`
- Port: 8883 (MQTT over TLS) replaces 1883 for all external G1 connections. Port 1883 disabled or restricted to internal cluster traffic.
- Secret: Store cert + key as a Kubernetes Secret (`hivemq-tls-secret`) mounted into the broker pod.

```bash
kubectl create secret generic hivemq-tls-secret --from-file=keystore.p12 --from-file=tls.crt --from-file=tls.key -n transit-edge
```

#### 🎯  Acceptance Criteria

- [ ] `mosquitto_pub -h <broker> -p 8883 --cafile ca.crt -t test/tls -m 'hello'` succeeds.
- [ ] A connection attempt on port 1883 from outside the cluster is refused.
- [ ] SSL Labs scan (or equivalent) on the staging broker endpoint returns TLS 1.2 or higher.
- [ ] Certificate is stored in a Kubernetes Secret — no cert files are baked into the container image.
- [ ] G1 team has been provided the CA certificate and confirmed test device connects successfully.

#### 🔗  Dependencies

Blocked by: **G4-01** — MQTT broker must be deployed before TLS can be configured.

---

### G4-03 — Deploy Apache Kafka Cluster — 3 Brokers (KRaft Mode) in transit-streaming Namespace

Deploy a 3-broker Apache Kafka 3.x cluster using KRaft (no ZooKeeper) as Kubernetes StatefulSets in the `transit-streaming` namespace.

| Issue # | Epic | Priority | Labels | Points | Sprint |
|---------|------|----------|--------|--------|--------|
| G4-03 | EPIC-01: Messaging Backbone | Critical | infrastructure, messaging | 5 | Sprint 1 |

#### 📋  Summary

Kafka is the central nervous system of the entire transit system. All real-time GPS events, ETA predictions, anomaly alerts, and driver commands flow through Kafka topics. This Issue deploys the Kafka cluster with replication factor 3 (so any single broker can fail without data loss), using KRaft mode for cluster coordination (no ZooKeeper dependency). The cluster must be operational before any topics can be created (G4-04) or the G2 ingestion service configured (G4-05).

#### 🔗  SRS / SDD Reference

- NFR-REL-03 — Kafka messages persisted with replication factor 3, `min.insync.replicas=2`. Zero message loss on single broker failure.
- FR-G4-02 — Kafka cluster must sustain GPS stream from 500 buses.
- SDD §8.1 — `transit-streaming` namespace — Kafka StatefulSet (3 brokers).
- SDD §4.1 — Kafka topic architecture — topics with specific partition and replication settings.

#### 🔧  Technical Notes

- Image: `confluentinc/cp-kafka:7.8.3`
- Mode: KRaft (combined broker + controller roles, no ZooKeeper)
- Kafka: StatefulSet with 3 replicas. Each broker gets a unique `NODE_ID` matching pod ordinal (0,1,2). PVC 20Gi per pod for log retention.
- Key Kafka config: `default.replication.factor=3` | `min.insync.replicas=2` | `offsets.topic.replication.factor=3`
- Services: Headless Service for StatefulSet addressing (`kafka-0.kafka-headless:9092` etc.) + ClusterIP Service for client connections on port 9092.

```bash
kubectl apply -f k8s/transit-streaming/namespace.yaml
kubectl apply -f k8s/transit-streaming/kafka-statefulset.yaml
kubectl apply -f k8s/transit-streaming/kafka-service.yaml
```

#### 🎯  Acceptance Criteria

- [ ] 3 Kafka broker pods (`kafka-0`, `kafka-1`, `kafka-2`) are Running in `transit-streaming`.
- [ ] `kafka-console-producer.sh --topic test-topic` successfully publishes a message.
- [ ] `kafka-console-consumer.sh` on a separate pod successfully reads the message.
- [ ] Deleting `kafka-1` pod results in automatic restart and partition leader re-election within 30 seconds.
- [ ] After broker restart, producer with `acks=all` can resume publishing with zero message loss (verify via offset count).

#### 🔗  Dependencies

None — this Issue can be started independently.

---

### G4-04 — Create and Configure All 5 Kafka Topics with Correct Partition and Replication Settings

Create the five Kafka topics required by the system with the exact partition counts, replication factors, and retention policies defined by the G2 Intelligence team's data pipeline contract.

| Issue # | Epic | Priority | Labels | Points | Sprint |
|---------|------|----------|--------|--------|--------|
| G4-04 | EPIC-01: Messaging Backbone | High | infrastructure, messaging | 3 | Sprint 1 |

#### 📋  Summary

The Kafka topics are the defined contracts between all four teams. Getting topic names, partition counts, replication factors, and retention wrong at this stage will cascade into failures across G2 (which consumes `transport-telemetry-raw`) and G3 (which consumes cleaned telemetry and anomaly alerts). Following the cross-team architectural pivot, the topic names and schemas are now owned by G2's Intelligence team. Topic creation must match the G2 specification exactly — any deviation requires a formal change request from the Lead Architect.

#### 🔗  SRS / SDD Reference

- SDD §4.1 — Kafka Topic Architecture — all 5 topic specifications (updated per G2 pivot).
- FR-G2-01 — G2 Flink/pipeline consumes `transport-telemetry-raw`. Requires 12 partitions keyed on `busId`.
- NFR-REL-03 — Replication factor 3, `min.insync.replicas` 2 on all topics.

#### 🔧  Technical Notes

Create all topics using the `kafka-topics` admin tool. Deploy as a Kubernetes Job for idempotent topic creation:

```bash
kafka-topics --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic transport-telemetry-raw --partitions 12 --replication-factor 3 \
  --config retention.ms=7200000 --config min.insync.replicas=2

kafka-topics --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic transport-telemetry-cleaned --partitions 6 --replication-factor 3 \
  --config retention.ms=1800000 --config min.insync.replicas=2

kafka-topics --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic transport-anomaly-alerts --partitions 3 --replication-factor 3 \
  --config retention.ms=86400000 --config min.insync.replicas=2

kafka-topics --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic transport-telemetry-dlq --partitions 3 --replication-factor 3 \
  --config retention.ms=86400000 --config min.insync.replicas=2

kafka-topics --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic trip.lifecycle --partitions 3 --replication-factor 3 \
  --config retention.ms=7200000 --config min.insync.replicas=2
```

Store topic creation as a Kubernetes Job (`kafka-topic-creator-job.yaml`) so topics are idempotently recreated on cluster rebuild.

#### 🎯  Acceptance Criteria

- [ ] `kafka-topics --list` shows all 5 topic names exactly as specified: `transport-telemetry-raw`, `transport-telemetry-cleaned`, `transport-anomaly-alerts`, `transport-telemetry-dlq`, `trip.lifecycle`.
- [ ] `kafka-topics --describe --topic transport-telemetry-raw` shows 12 partitions, replication factor 3, `min.insync.replicas` 2.
- [ ] `kafka-topics --describe --topic transport-telemetry-cleaned` shows 6 partitions, replication factor 3.
- [ ] All topic retention periods match the G2 contract (`transport-telemetry-raw`: 2hr, `transport-telemetry-cleaned`: 30min, `transport-anomaly-alerts`: 24hr, `transport-telemetry-dlq`: 24hr, `trip.lifecycle`: 2hr).
- [ ] Topic creation is automated (Kubernetes Job) — re-running is idempotent (no error if topics already exist).

#### 🔗  Dependencies

Blocked by: **G4-03** — Kafka cluster must be running before topics can be created.

---

### G4-05 — Deploy G2 Ingestion Service — Python MQTT→Kafka Worker

Deploy and configure G2's custom Python ingestion container that bridges MQTT GPS payloads from the broker into the Kafka `transport-telemetry-raw` topic.

| Issue # | Epic | Priority | Labels | Points | Sprint |
|---------|------|----------|--------|--------|--------|
| G4-05 | EPIC-01: Messaging Backbone | Critical | infrastructure, messaging | 5 | Sprint 2 |

#### 📋  Summary

The MQTT→Kafka bridge is the critical handoff point between G1 (edge devices) and G2 (stream processing). Following the cross-team architectural pivot, the G2 Intelligence team built their own custom Python ingestion service that replaces the originally planned Confluent Kafka MQTT Source Connector. G4's responsibility is to deploy this container onto our core Kubernetes infrastructure. The service subscribes to the MQTT broker on wildcard topics, validates incoming GPS payloads against G2's strict schema, and writes valid payloads to `transport-telemetry-raw` while routing rejected messages to `transport-telemetry-dlq`.

#### 🔗  SRS / SDD Reference

- SDD §2.3 — Step 3 in end-to-end data flow: MQTT Broker → Kafka Bridge (~40ms latency budget).
- SDD §2.2 — Messaging Backbone — MQTT→Kafka Bridge component.
- SDD §4.1 — `transport-telemetry-raw` topic — Producer: G2 Ingestion Service (deployed by G4). Must be keyed on `busId`.
- NFR-REL-03 — Zero message loss; producer must use `acks=all`.

#### 🔧  Technical Notes

- Image: `ghcr.io/your-org/ontime-g2-ingestion:latest` (G2-built Python container)
- Namespace: `transit-intelligence`
- Kind: Deployment with 1 replica
- Required environment variables:
  - `MQTT_BROKER_HOST`: `hivemq-service.transit-edge.svc.cluster.local`
  - `MQTT_BROKER_PORT`: `1883`
  - `MQTT_TLS_ENABLED`: `false` (internal cluster traffic)
  - `KAFKA_BROKER_URL`: `kafka.transit-streaming.svc.cluster.local:9092`
  - `INGESTION_KAFKA_RAW_TOPIC`: `transport-telemetry-raw`
  - `INGESTION_KAFKA_DLQ_TOPIC`: `transport-telemetry-dlq`
  - `INGESTION_KAFKA_TRIP_LIFECYCLE_TOPIC`: `trip.lifecycle`

```bash
kubectl apply -f k8s/transit-intelligence/g2-ingestion-deployment.yaml
```

#### 🎯  Acceptance Criteria

- [ ] A test MQTT message published to `transport/BUS-255-001/location` appears in Kafka topic `transport-telemetry-raw` within 500ms.
- [ ] All records for `BUS-255-001` land in the same `transport-telemetry-raw` partition (verify via `kafka-console-consumer.sh --partition` flag).
- [ ] Producer offset count on `transport-telemetry-raw` equals the number of valid MQTT messages published — zero messages lost.
- [ ] Ingestion pod restarts automatically if killed and resumes consuming from the MQTT broker within 30 seconds.
- [ ] All configuration is stored via environment variables in the Deployment manifest — no hardcoded broker URLs or credentials in the container spec.

#### 🔗  Dependencies

Blocked by: **G4-01** — MQTT broker must be running.
Blocked by: **G4-03** — Kafka cluster must be running.
Blocked by: **G4-04** — `transport-telemetry-raw` and `transport-telemetry-dlq` topics must exist.

---

### G4-06 — End-to-End MQTT → Kafka Verification with Simulated GPS Payload

Run a full end-to-end verification test of the MQTT→Kafka pipeline using a simulated GPS JSON payload that matches G2's strict validation schema exactly.

| Issue # | Epic | Priority | Labels | Points | Sprint |
|---------|------|----------|--------|--------|--------|
| G4-06 | EPIC-01: Messaging Backbone | High | infrastructure, messaging, cross-team | 3 | Sprint 2 |

#### 📋  Summary

Before G2 builds their full processing pipeline and G1 connects real devices, we must verify that the entire MQTT→Kafka pipeline works correctly with the exact payload format required by G2's ingestion service. Following the architectural pivot, G2's ingestion service enforces a strict JSON schema — any payload that does not match is routed to the `transport-telemetry-dlq` (Dead Letter Queue) topic. This is a cross-team verification task — G2 should be invited to observe the consumer output. G1 edge devices must adhere to G2's exact schema to avoid messages going to the DLQ.

#### 🔗  SRS / SDD Reference

- SDD §4 (SRS) — GPS payload JSON schema — G2's required fields must be present and correctly named.
- SDD §2.3 — End-to-end data flow verification: GPS acquisition → Kafka `transport-telemetry-raw`.
- FR-G1-01 — G1 publishes 1 Hz at `transport/{bus_id}/location` — G4 must verify this rate is sustained through the bridge.

#### 🔧  Technical Notes

Use the following test payload (valid per G2's strict validation schema):

```json
{
  "busId": "BUS-255-TEST",
  "lat": 6.7730,
  "lon": 79.8820,
  "speed": 34.5,
  "heading": 45.0,
  "timestamp": "2025-10-01T08:30:00.000Z"
}
```

> **⚠️ IMPORTANT:** G2's ingestion service enforces strict field naming. The required fields are exactly: `busId`, `lat`, `lon`, `speed`, `heading`, `timestamp`. Any deviation (e.g., using `vehicle_id` instead of `busId`, or `latitude` instead of `lat`) will cause the message to be routed to the `transport-telemetry-dlq` Dead Letter Queue. G1's edge devices MUST adhere to this exact schema.

Publish 3600 messages at 1Hz using a script to simulate 1 hour of bus telemetry. Verify all 3600 appear in `transport-telemetry-raw` with matching offsets.

Consumer command:
```bash
kafka-console-consumer.sh --topic transport-telemetry-raw --from-beginning --max-messages 10 --property print.key=true
```

#### 🎯  Acceptance Criteria

- [ ] Test payload published to `transport/BUS-255-TEST/location` appears in `transport-telemetry-raw` within 500ms.
- [ ] All 6 JSON fields from G2's schema are present and correctly named in the Kafka message: `busId`, `lat`, `lon`, `speed`, `heading`, `timestamp`.
- [ ] 3600 messages published at 1Hz — all 3600 appear in `transport-telemetry-raw` (offset count = 3600, zero loss).
- [ ] All messages for `BUS-255-TEST` are in the same partition (key-based routing confirmed).
- [ ] G2 team lead has reviewed Kafka consumer output and confirmed the payload is parseable by their pipeline.

#### 🔗  Dependencies

Blocked by: **G4-05** — G2 Ingestion Service must be deployed.

---

### G4-07 — Deploy G2 WebSocket Service — FastAPI Live Push

Deploy G2's custom FastAPI WebSocket service that subscribes to Redis Pub/Sub channels and pushes live ETA updates to connected G3 clients.

| Issue # | Epic | Priority | Labels | Points | Sprint |
|---------|------|----------|--------|--------|--------|
| G4-07 | EPIC-01: Messaging Backbone | High | infrastructure, messaging, cross-team | 5 | Sprint 2 |

#### 📋  Summary

G3's commuter and scheduler applications cannot directly consume from Kafka — they need a WebSocket push service. Following the cross-team architectural pivot, the G2 Intelligence team built their own FastAPI WebSocket service that replaces the originally planned Node.js Socket.IO adapter. G4's responsibility is to deploy this container and its Redis dependency onto our Kubernetes infrastructure. The service subscribes to Redis Pub/Sub channels (`fleet:live` and `eta:live`) populated by G2's processing pipeline, and pushes live updates to connected G3 WebSocket clients.

#### 🔗  SRS / SDD Reference

- SDD §6.3 — WebSocket push design for G3 clients.
- SDD §2.3 — Step 8: Kafka→G3 WebSocket Bridge (~60ms latency budget).
- DD-03 — WebSocket push used instead of REST polling. Redis required for pub/sub state.
- NFR-PERF-03 — Must sustain 10,000 concurrent WebSocket connections.

#### 🔧  Technical Notes

- Image: `ghcr.io/your-org/ontime-g2-websocket:latest` (G2-built FastAPI container)
- Namespace: `transit-ui`
- Kind: Deployment with 2 replicas
- Redis dependency: Deploy Redis 7.x as a single Deployment (ClusterIP) in `transit-ui` for pub/sub channel state. Not clustered in Increment 1.
- Required environment variable:
  - `REDIS_URL`: `redis://redis-service.transit-ui.svc.cluster.local:6379`
- Redis Pub/Sub channels consumed: `fleet:live` (fleet-wide updates) and `eta:live` (ETA prediction updates)
- Service: ClusterIP on port 8000. Kong will route external WebSocket connections to this service.

```bash
kubectl apply -f k8s/transit-ui/redis.yaml
kubectl apply -f k8s/transit-ui/g2-websocket-deployment.yaml
```

#### 🎯  Acceptance Criteria

- [ ] A WebSocket client connecting to the service receives a message within 2 seconds of a Redis PUBLISH on the `fleet:live` or `eta:live` channel.
- [ ] An update published to the `eta:live` Redis channel appears on connected WebSocket clients within 5 seconds.
- [ ] Killing one WebSocket pod does not disconnect all clients (second replica continues serving).
- [ ] 10 simulated concurrent WebSocket clients all receive the same broadcast within 2 seconds.
- [ ] Redis pod and both WebSocket pods are Running in `transit-ui` namespace.

#### 🔗  Dependencies

Blocked by: **G4-03** — Kafka cluster must be running (G2's pipeline feeds Redis).
Blocked by: **G4-04** — Kafka topics must exist for G2's upstream pipeline.

---

### G4-08 — Load Test MQTT Broker — 500 Concurrent Clients, Verify P95 Queue Delay < 500ms

Execute a formal load test against the MQTT broker cluster simulating 500 concurrent persistent G1 client connections publishing at 1Hz, and verify NFR-REL-04 is met.

| Issue # | Epic | Priority | Labels | Points | Sprint |
|---------|------|----------|--------|--------|--------|
| G4-08 | EPIC-01: Messaging Backbone | Medium | infrastructure, messaging | 3 | Sprint 5 |

#### 📋  Summary

NFR-REL-04 requires the MQTT broker to sustain 500 simultaneous persistent client connections without message queuing delay exceeding 500ms at the P95. This is the performance acceptance test for the messaging backbone. It must be run against the staging environment on Digital Ocean (not local Docker Compose) to produce valid results. Results must be recorded in a test report attached to this Issue before it can be marked Done.

#### 🔗  SRS / SDD Reference

- NFR-REL-04 — MQTT broker shall sustain 500 simultaneous persistent client connections, P95 queue delay < 500ms, sustained for 10 minutes.
- SDD §8.2 — HPA for MQTT is not configured (broker uses StatefulSet with fixed 3 replicas).

#### 🔧  Technical Notes

- Tool: `mqtt-bench` or custom Python script using `paho-mqtt` library. Spawn 500 client threads, each publishing one message/second to `transport/BUS-{N}/location`.
- Metrics to capture: P50, P95, P99 publish-to-broker latency. Total messages sent vs. received. Broker CPU and memory during test (from Prometheus/Grafana — must be set up first per G4-28/G4-29).
- Test duration: 10 minutes sustained load (as per NFR-REL-04).
- Report: Attach a Markdown test report to this Issue with: test parameters, Grafana screenshot of MQTT broker CPU/mem, and P95 latency measurement.

#### 🎯  Acceptance Criteria

- [ ] 500 concurrent MQTT clients are connected simultaneously and confirmed via broker metrics.
- [ ] P95 publish-to-broker latency is < 500ms across the full 10-minute test window.
- [ ] Zero messages are lost (published count = received count in Kafka consumer offset, verified via G4-06 pipeline).
- [ ] A test report (Markdown) is attached to this Issue with Grafana screenshots and P95 measurement.
- [ ] Broker CPU does not exceed 80% during the test (Prometheus metric recorded).

#### 🔗  Dependencies

Blocked by: **G4-05** — G2 Ingestion Service must be live to verify messages flow to Kafka.
Blocked by: **G4-28** — Prometheus must be running to capture broker metrics.
Blocked by: **G4-39** — Must be run on Digital Ocean staging cluster for valid results.

---

<!-- EPIC-02 through EPIC-05 continue below. See the original G4 GitHub Issues Registry for issues G4-09 through G4-45. Those epics are NOT modified by this update. -->
