CREATE TABLE halts (
    halt_id VARCHAR(30) PRIMARY KEY,
    route_id VARCHAR(20) NOT NULL,
    halt_name_en VARCHAR(100) NOT NULL,
    halt_name_si VARCHAR(100) NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    halt_sequence INT NOT NULL CHECK (halt_sequence >= 0),
    is_expressway_halt BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_halts_route_sequence UNIQUE (route_id, halt_sequence),
    CONSTRAINT fk_halts_route
        FOREIGN KEY (route_id)
        REFERENCES routes(route_id)
        DEFERRABLE INITIALLY DEFERRED
);

ALTER TABLE routes
    ADD CONSTRAINT fk_routes_origin_halt
    FOREIGN KEY (origin_halt_id)
    REFERENCES halts(halt_id)
    DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE routes
    ADD CONSTRAINT fk_routes_destination_halt
    FOREIGN KEY (destination_halt_id)
    REFERENCES halts(halt_id)
    DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE routes
    ADD CONSTRAINT fk_routes_highway_entry_halt
    FOREIGN KEY (highway_entry_halt_id)
    REFERENCES halts(halt_id)
    DEFERRABLE INITIALLY DEFERRED;
