-- TODO: Implement according to G4 guide and issue assignment.

-- Create the additional Keycloak database
CREATE DATABASE keycloak_db;

-- Connect to the main transit database (created automatically by the container env vars)
\c transit_db

-- Install the spatial extensions for geo-fencing and route mapping
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;