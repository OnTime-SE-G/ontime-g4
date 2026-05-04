-- TODO: Implement according to G4 guide and issue assignment.

CREATE TABLE timetable_entries (
    entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id VARCHAR(20) NOT NULL,
    halt_id VARCHAR(30) NOT NULL,
    scheduled_arrival TIME NOT NULL,
    scheduled_departure TIME NOT NULL,
    day_mask SMALLINT DEFAULT 127,
    effective_from DATE NOT NULL,
    effective_to DATE,
    CONSTRAINT fk_timetable_route FOREIGN KEY (route_id) REFERENCES routes(route_id),
    CONSTRAINT fk_timetable_halt FOREIGN KEY (halt_id) REFERENCES halts(halt_id)
);