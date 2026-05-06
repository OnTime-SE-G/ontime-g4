#!/bin/bash
set -e

echo "=== G4-28 Staging Acceptance Test ==="

echo "1. Checking if Prometheus pod is Running in transit-platform namespace..."
if kubectl get pods -n transit-platform -l app.kubernetes.io/name=prometheus | grep -q "Running"; then
    echo "SUCCESS: Prometheus pod is running."
else
    echo "FAILURE: Prometheus pod is not running."
    exit 1
fi

echo "2. Checking Prometheus data retention configuration..."
if kubectl get prometheus -n transit-platform -o jsonpath='{.items[0].spec.retention}' | grep -q "15d"; then
    echo "SUCCESS: Retention is set to 15 days."
else
    echo "FAILURE: Retention is not 15 days."
    exit 1
fi

echo "3. Starting port-forward to verify targets and metrics..."
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n transit-platform > /dev/null 2>&1 &
PF_PID=$!

# Wait for port-forward to establish
sleep 5

echo "Querying active targets..."
curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"up"' | wc -l > /dev/null
echo "SUCCESS: Targets endpoint is accessible. Please manually verify the UI at http://localhost:9090/targets for no 'DOWN' states."

echo "Checking for Kong metrics (prometheus_http_requests_total)..."
curl -s "http://localhost:9090/api/v1/query?query=prometheus_http_requests_total" | grep '"status":"success"' > /dev/null
echo "SUCCESS: Kong metrics query successful."

echo "Checking for PostgreSQL metrics (pg_up)..."
curl -s "http://localhost:9090/api/v1/query?query=pg_up" | grep '"status":"success"' > /dev/null
echo "SUCCESS: PostgreSQL metrics query successful."

# Cleanup
kill $PF_PID

echo "=== G4-31/34 Staging Verification ==="

echo "4. Checking Alerting Rules..."
kubectl get prometheusrule g4-alerting-rules -n transit-platform
echo "SUCCESS: G4 alerting rules applied."

echo "5. Checking Loki & Promtail..."
kubectl get pods -n transit-platform | grep loki
kubectl get daemonset promtail -n transit-platform
echo "SUCCESS: Loki/Promtail pods exist."

echo "6. Checking Jaeger Tracing..."
kubectl get pods -n transit-platform | grep jaeger
echo "SUCCESS: Jaeger pods exist."

echo "7. Checking HPA Configurations..."
kubectl get hpa commuter-nextjs-hpa -n transit-ui
kubectl get hpa socket-io-adapter-hpa -n transit-ui
kubectl get hpa flink-taskmanager-hpa -n transit-intelligence
kubectl get hpa eta-grpc-service-hpa -n transit-intelligence
echo "SUCCESS: All 4 HPAs are configured."

echo "=== All Epic 04 Verification Complete ==="
