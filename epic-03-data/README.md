# Epic 03 Data

This folder owns the Kubernetes data layer used by `ontime-g2`.

It now matches the G2 service expectations:

1. PostgreSQL/PostGIS service `postgres` with database `ontime_db`.
2. PostgreSQL database `fleet_db` for fleet-management-service.
3. Redis service `redis` on port `6379`.
4. InfluxDB service `influxdb` with org `ontime` and bucket `telemetry`.
5. Flyway migrations for both PostgreSQL databases.

## Kubernetes Files

Apply these files to a DigitalOcean Kubernetes cluster:

```bash
kubectl apply -f k8s/database-secrets.yaml
kubectl apply -f k8s/postgres-statefulset.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/redis-statefulset.yaml
kubectl apply -f k8s/influxdb-statefulset.yaml
kubectl wait -n transit-data --for=condition=ready pod -l app=postgresql --timeout=180s
kubectl apply -f k8s/flyway-job.yaml
```

The StatefulSets use `do-block-storage`, which is the DigitalOcean block storage class.

## G2 Application Wiring

For route-service, map `DATABASE_URL` from:

```text
g2-data-connection-secrets.ROUTE_DATABASE_URL
```

For fleet-management-service, map `DATABASE_URL` from:

```text
g2-data-connection-secrets.FLEET_DATABASE_URL
```

For stream-processing and websocket-service, use:

```text
g2-data-connection-config.REDIS_HOST
g2-data-connection-config.REDIS_PORT
g2-data-connection-config.REDIS_URL
g2-data-connection-config.INFLUXDB_URL
g2-data-connection-config.INFLUXDB_ORG
g2-data-connection-config.INFLUXDB_BUCKET
g2-data-connection-secrets.INFLUXDB_TOKEN
```

The included secret values match G2's local defaults so the services can connect immediately. Replace them before a real public deployment.

## Migrations

`migrations/ontime` creates the route-service schema:

1. `routes`
2. `stops`
3. `route_stop_links`
4. spatial indexes
5. timetable table
6. seed route 255, Moratuwa to Kadawatha

`migrations/fleet` creates the fleet-management-service schema:

1. `buses`

The Kubernetes Flyway Job mounts the same SQL content through ConfigMaps and migrates `ontime_db` first, then `fleet_db`.

## Local Check

Run:

```bash
./tests/verify-schema.sh
```

This checks the expected files, key schema names, G2-compatible service names, and performs a local Kubernetes manifest dry-run when `kubectl` is installed.
