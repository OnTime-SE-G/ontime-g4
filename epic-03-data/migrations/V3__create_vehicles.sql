CREATE TABLE vehicles (
    vehicle_id VARCHAR(20) PRIMARY KEY,
    route_id VARCHAR(20) NOT NULL,
    registration_plate VARCHAR(12) UNIQUE NOT NULL,
    operator_name VARCHAR(100) NOT NULL,
    keycloak_username VARCHAR(100) UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'DEPOT', 'MAINTENANCE')),
    last_seen_utc TIMESTAMPTZ,
    CONSTRAINT fk_vehicle_route
        FOREIGN KEY (route_id)
        REFERENCES routes(route_id)
);
