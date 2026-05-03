#!/bin/bash
set -e

# Wait for InfluxDB to fully boot up
sleep 5 

echo "Creating gps-aggregates bucket..."
# Create the 90-day (2160h) retention bucket using the admin token
influx bucket create -n gps-aggregates -o transit-org -r 2160h -t $DOCKER_INFLUXDB_INIT_ADMIN_TOKEN