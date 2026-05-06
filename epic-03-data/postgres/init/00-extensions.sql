CREATE DATABASE fleet_db;
CREATE DATABASE ontime_test_db;
CREATE DATABASE keycloak_db;

\connect ontime_db
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

\connect ontime_test_db
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
