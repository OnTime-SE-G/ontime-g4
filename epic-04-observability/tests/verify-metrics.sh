#!/bin/bash
set -e

echo "Checking Prometheus Targets Status..."

# We wait for Prometheus to be ready
echo "Waiting for Prometheus to be up..."
for i in {1..15}; do
    STATUS=$(curl -s http://localhost:9090/-/ready || echo "Not Ready")
    if [[ "$STATUS" == *"Prometheus is Ready."* || "$STATUS" == *"Prometheus Server is Ready"* ]]; then
        echo "Prometheus is ready."
        break
    fi
    sleep 2
done

# Query the targets endpoint
echo "Querying Prometheus active targets..."
TARGETS_OUTPUT=$(curl -s http://localhost:9090/api/v1/targets)

# Check if at least one target is UP
PROM_UP=$(echo "$TARGETS_OUTPUT" | grep -o '"health":"up"' | wc -l || echo 0)

if [ "$PROM_UP" -gt 0 ]; then
    echo "SUCCESS: $PROM_UP target(s) are UP."
else
    echo "FAILURE: No targets are UP."
    echo "Targets output: $TARGETS_OUTPUT"
    exit 1
fi
