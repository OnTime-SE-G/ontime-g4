#!/bin/bash
set -e
sleep 5
influx bucket create -n gps-aggregates -o transit-org -r 2160h -t "$DOCKER_INFLUXDB_INIT_ADMIN_TOKEN"
