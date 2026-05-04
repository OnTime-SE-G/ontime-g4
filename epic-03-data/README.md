# Epic 03 Data

This folder is for the data layer deployment. It covers PostgreSQL, PostGIS, InfluxDB, Redis, migrations, seeding, and internal database access for other teams.

## What belongs here

1. PostgreSQL container and init scripts.
2. PostGIS installation and spatial indexing.
3. Flyway migrations and seed data.
4. InfluxDB setup and bucket creation.
5. Schema and connectivity tests.

## Issue order

1. G4-19 Deploy PostgreSQL.
2. G4-20 Install PostGIS and create transit_db.
3. G4-21 Apply the initial schema migrations.
4. G4-22 Create the spatial index on halts.location.
5. G4-23 Seed the Moratuwa to Kadawatha route data.
6. G4-24 Deploy InfluxDB and create the telemetry buckets.
7. G4-25 Configure database credentials as Kubernetes Secrets.
8. G4-26 Expose internal ClusterIP connectivity.
9. G4-27 Run the spatial performance test.

## Internal service names

These names support both EPIC-03 acceptance checks and the database Docker Compose used by the database-owning group.

1. PostgreSQL: `postgresql-service.transit-data.svc.cluster.local:5432`
2. InfluxDB: `influxdb-service.transit-data.svc.cluster.local:8086`
3. Redis: `redis.transit-data.svc.cluster.local:6379`

G2-compatible aliases are also available in-cluster:

1. PostgreSQL: `postgres.transit-data.svc.cluster.local:5432`
2. InfluxDB: `influxdb.transit-data.svc.cluster.local:8086`
3. Redis: `redis.transit-data.svc.cluster.local:6379`

The PostgreSQL init script creates `transit_db`, `ontime_db`, `fleet_db`, `ontime_test_db`, and `keycloak_db`.
InfluxDB creates EPIC-03 buckets under `transit-org` and the G2-compatible `telemetry` bucket under `ontime`.

## Key references

1. SDD section 5.1 for the PostgreSQL schema.
2. SDD section 5.2 for the InfluxDB schema.
3. SRS requirements FR-G4-03 and NFR-PERF-05.
4. SRS constraints AC-06 and AC-07.

## Start here

1. Keep migrations versioned and reproducible.
2. Do not hardcode credentials.
3. Verify spatial queries before seeding large data sets.

## Required secrets

Create these Kubernetes Secrets before applying `epic-03-data/k8s`:

```bash
kubectl create namespace transit-data --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic postgres-credentials \
  -n transit-data \
  --from-literal=username=transit_admin \
  --from-literal=password='<POSTGRES_PASSWORD>'

kubectl create secret generic influxdb-credentials \
  -n transit-data \
  --from-literal=password='<INFLUXDB_PASSWORD>' \
  --from-literal=admin-token='<INFLUXDB_ADMIN_TOKEN>'
```

Keep the real values in GitHub Actions secrets or the team password manager, never in Git.
