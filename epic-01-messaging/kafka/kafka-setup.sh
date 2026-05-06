#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# G4-04 — Kafka Topic Setup Script
# Creates all 5 G2 contract topics idempotently.
# Mirrors: k8s/transit-streaming/kafka-topic-creator-job.yaml
#
# Usage (local Docker):
#   docker exec kafka bash /path/to/kafka-setup.sh
#
# Usage (Kubernetes):
#   kubectl exec -n transit-streaming kafka-0 -- bash /path/to/kafka-setup.sh
# ============================================================

BOOTSTRAP="${KAFKA_BOOTSTRAP:-kafka:9092}"

echo "Waiting for Kafka broker at $BOOTSTRAP..."
while ! nc -z "${BOOTSTRAP%%:*}" "${BOOTSTRAP##*:}" 2>/dev/null; do
  sleep 2
done

echo "Kafka is ready. Creating G2's topics..."

kafka-topics --bootstrap-server "$BOOTSTRAP" --create --if-not-exists \
  --topic transport-telemetry-raw --partitions 12 --replication-factor 3 \
  --config retention.ms=7200000 --config min.insync.replicas=2

kafka-topics --bootstrap-server "$BOOTSTRAP" --create --if-not-exists \
  --topic transport-telemetry-cleaned --partitions 6 --replication-factor 3 \
  --config retention.ms=1800000 --config min.insync.replicas=2

kafka-topics --bootstrap-server "$BOOTSTRAP" --create --if-not-exists \
  --topic transport-anomaly-alerts --partitions 3 --replication-factor 3 \
  --config retention.ms=86400000 --config min.insync.replicas=2

kafka-topics --bootstrap-server "$BOOTSTRAP" --create --if-not-exists \
  --topic transport-telemetry-dlq --partitions 3 --replication-factor 3 \
  --config retention.ms=86400000 --config min.insync.replicas=2

kafka-topics --bootstrap-server "$BOOTSTRAP" --create --if-not-exists \
  --topic trip.lifecycle --partitions 3 --replication-factor 3 \
  --config retention.ms=7200000 --config min.insync.replicas=2

echo ""
echo "✅ All G2 topics created. Verifying..."
kafka-topics --bootstrap-server "$BOOTSTRAP" --list
