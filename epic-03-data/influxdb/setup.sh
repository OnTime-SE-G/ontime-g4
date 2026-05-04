#!/bin/bash
set -e

influx bucket create \
  --name gps-aggregates \
  --org "${DOCKER_INFLUXDB_INIT_ORG:-ontime}" \
  --retention 2160h \
  --token "$DOCKER_INFLUXDB_INIT_ADMIN_TOKEN" || true
