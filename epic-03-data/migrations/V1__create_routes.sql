-- TODO: Implement according to G4 guide and issue assignment.

CREATE TABLE routes (
    route_id VARCHAR(20) PRIMARY KEY,
    route_number VARCHAR(10) NOT NULL,
    origin_halt_id VARCHAR(30),
    destination_halt_id VARCHAR(30),
    direction CHAR(8) CHECK (direction IN ('OUTBOUND','RETURN')),
    highway_entry_halt_id VARCHAR(30),
    route_polyline GEOMETRY(LineString, 4326) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    name_en VARCHAR(100) NOT NULL,
    name_si VARCHAR(100) NOT NULL
);