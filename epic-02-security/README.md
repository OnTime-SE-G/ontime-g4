# Epic 02 Security

This folder is for API gateway, identity, and service mesh work. It covers Kong, Keycloak, Istio, and the security tests that protect all public access.

## What belongs here

1. Kong declarative configuration and plugins.
2. Keycloak realm, clients, and themes.
3. Istio ingress and mTLS configuration.
4. Security test scripts and role checks.
5. Stub upstream services for local testing.

## Issue order

1. G4-09 Deploy Kong Gateway.
2. G4-10 Deploy Keycloak with PostgreSQL backend.
3. G4-11 Configure the transit-system realm and roles.
4. G4-12 Configure the three Keycloak clients.
5. G4-13 Install JWT validation in Kong.
6. G4-14 Configure Kong rate limiting.
7. G4-15 Deploy Istio with STRICT mTLS.
8. G4-16 Configure all Kong API routes.
9. G4-17 Configure TLS for external endpoints.
10. G4-18 Run the security integration tests.

## Key references

1. SDD section 7.1 for the token lifecycle.
2. SDD section 7.2 for Keycloak settings.
3. SDD section 7.3 for route security and rate limits.
4. SRS requirements FR-G4-01 and NFR-SEC-01 through NFR-SEC-03.

## Start here

1. Keep all gateway and identity changes in this folder.
2. Use the mock upstream services until G3 is ready.
3. Verify JWT, role, and mTLS behaviour before merging.


