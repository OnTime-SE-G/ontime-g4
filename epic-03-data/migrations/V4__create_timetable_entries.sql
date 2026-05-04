CREATE TABLE timetable_entries (
    entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id VARCHAR(20) NOT NULL,
    halt_id VARCHAR(30) NOT NULL,
    scheduled_arrival TIME NOT NULL,
    scheduled_departure TIME NOT NULL,
    day_mask SMALLINT NOT NULL DEFAULT 127 CHECK (day_mask BETWEEN 1 AND 127),
    effective_from DATE NOT NULL,
    effective_to DATE,
    CONSTRAINT fk_timetable_route
        FOREIGN KEY (route_id)
        REFERENCES routes(route_id),
    CONSTRAINT fk_timetable_halt
        FOREIGN KEY (halt_id)
        REFERENCES halts(halt_id),
    CONSTRAINT ck_timetable_effective_dates
        CHECK (effective_to IS NULL OR effective_to >= effective_from)
);
