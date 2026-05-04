# Epic 03 Data

This folder is for the relational and time-series data layer. It covers PostgreSQL, PostGIS, InfluxDB, migrations, seeding, and internal database access for other teams.

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

## Key references

1. SDD section 5.1 for the PostgreSQL schema.
2. SDD section 5.2 for the InfluxDB schema.
3. SRS requirements FR-G4-03 and NFR-PERF-05.
4. SRS constraints AC-06 and AC-07.

## Start here

1. Keep migrations versioned and reproducible.
2. Do not hardcode credentials.
3. Verify spatial queries before seeding large data sets.


