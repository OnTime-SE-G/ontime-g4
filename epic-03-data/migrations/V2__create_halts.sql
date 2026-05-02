-- TODO: Implement according to G4 guide and issue assignment.

CREATE TABLE halts (
    halt_id VARCHAR(30) PRIMARY KEY,
    halt_name_en VARCHAR(100) NOT NULL,
    halt_name_si VARCHAR(100) NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    halt_sequence INT NOT NULL,
    is_expressway_halt BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE routes ADD CONSTRAINT fk_origin_halt FOREIGN KEY (origin_halt_id) REFERENCES halts(halt_id);
ALTER TABLE routes ADD CONSTRAINT fk_dest_halt FOREIGN KEY (destination_halt_id) REFERENCES halts(halt_id);
ALTER TABLE routes ADD CONSTRAINT fk_hw_entry_halt FOREIGN KEY (highway_entry_halt_id) REFERENCES halts(halt_id);