BEGIN;
SET CONSTRAINTS ALL DEFERRED;

CREATE TABLE IF NOT EXISTS system_geofences (
    fence_name VARCHAR(50) PRIMARY KEY,
    boundary GEOMETRY(Polygon, 4326) NOT NULL,
    description TEXT
);

DELETE FROM timetable_entries
WHERE route_id IN ('255-MORA-KADA', '255-KADA-MORA');

DELETE FROM vehicles
WHERE route_id IN ('255-MORA-KADA', '255-KADA-MORA');

DELETE FROM halts
WHERE route_id IN ('255-MORA-KADA', '255-KADA-MORA');

DELETE FROM routes
WHERE route_id IN ('255-MORA-KADA', '255-KADA-MORA');

DELETE FROM system_geofences
WHERE fence_name = 'KAHATHUDUWA_ENTRY';

INSERT INTO system_geofences (fence_name, boundary, description)
VALUES (
    'KAHATHUDUWA_ENTRY',
    ST_Buffer(ST_SetSRID(ST_MakePoint(80.087, 6.820), 4326)::geography, 200)::geometry,
    'Approximate 200m Kahathuduwa expressway entry geofence for G2 enrichment.'
);

INSERT INTO routes (
    route_id,
    route_number,
    origin_halt_id,
    destination_halt_id,
    direction,
    highway_entry_halt_id,
    route_polyline,
    name_en,
    name_si
) VALUES
(
    '255-MORA-KADA',
    '255',
    'HALT-MORA-KADA-001',
    'HALT-MORA-KADA-009',
    'OUTBOUND',
    'HALT-MORA-KADA-007',
    ST_GeomFromText(
        'LINESTRING(79.8830 6.7730, 79.8845 6.7890, 79.8790 6.8130, 79.9220 6.8010, 79.9860 6.8380, 80.0460 6.8610, 80.0870 6.8200, 79.9500 7.0010, 79.9540 7.0050)',
        4326
    ),
    'Moratuwa - Kadawatha',
    'මොරටුව - කඩවත'
),
(
    '255-KADA-MORA',
    '255',
    'HALT-KADA-MORA-001',
    'HALT-KADA-MORA-009',
    'RETURN',
    'HALT-KADA-MORA-003',
    ST_GeomFromText(
        'LINESTRING(79.9540 7.0050, 79.9500 7.0010, 80.0870 6.8200, 80.0460 6.8610, 79.9860 6.8380, 79.9220 6.8010, 79.8790 6.8130, 79.8845 6.7890, 79.8830 6.7730)',
        4326
    ),
    'Kadawatha - Moratuwa',
    'කඩවත - මොරටුව'
);

INSERT INTO halts (
    halt_id,
    route_id,
    halt_name_en,
    halt_name_si,
    location,
    halt_sequence,
    is_expressway_halt
) VALUES
('HALT-MORA-KADA-001', '255-MORA-KADA', 'Moratuwa Bus Stand', 'මොරටුව බස් නැවතුම', ST_SetSRID(ST_MakePoint(79.8830, 6.7730), 4326), 1, FALSE),
('HALT-MORA-KADA-002', '255-MORA-KADA', 'Rawathawatte', 'රාවතාවත්ත', ST_SetSRID(ST_MakePoint(79.8845, 6.7890), 4326), 2, FALSE),
('HALT-MORA-KADA-003', '255-MORA-KADA', 'Katubedda Junction', 'කටුබැද්ද හන්දිය', ST_SetSRID(ST_MakePoint(79.8790, 6.8130), 4326), 3, FALSE),
('HALT-MORA-KADA-004', '255-MORA-KADA', 'Angulana', 'අඟුලාන', ST_SetSRID(ST_MakePoint(79.8725, 6.7895), 4326), 4, FALSE),
('HALT-MORA-KADA-005', '255-MORA-KADA', 'Piliyandala', 'පිළියන්දල', ST_SetSRID(ST_MakePoint(79.9220, 6.8010), 4326), 5, FALSE),
('HALT-MORA-KADA-006', '255-MORA-KADA', 'Kottawa', 'කොට්ටාව', ST_SetSRID(ST_MakePoint(79.9860, 6.8380), 4326), 6, FALSE),
('HALT-MORA-KADA-007', '255-MORA-KADA', 'Kahathuduwa Entrance', 'කහතුඩුව පිවිසුම', ST_SetSRID(ST_MakePoint(80.0870, 6.8200), 4326), 7, FALSE),
('HALT-MORA-KADA-008', '255-MORA-KADA', 'Kadawatha Exit', 'කඩවත පිටවීම', ST_SetSRID(ST_MakePoint(79.9500, 7.0010), 4326), 8, TRUE),
('HALT-MORA-KADA-009', '255-MORA-KADA', 'Kadawatha Bus Stand', 'කඩවත බස් නැවතුම', ST_SetSRID(ST_MakePoint(79.9540, 7.0050), 4326), 9, FALSE),
('HALT-KADA-MORA-001', '255-KADA-MORA', 'Kadawatha Bus Stand', 'කඩවත බස් නැවතුම', ST_SetSRID(ST_MakePoint(79.9540, 7.0050), 4326), 1, FALSE),
('HALT-KADA-MORA-002', '255-KADA-MORA', 'Kadawatha Exit', 'කඩවත පිටවීම', ST_SetSRID(ST_MakePoint(79.9500, 7.0010), 4326), 2, TRUE),
('HALT-KADA-MORA-003', '255-KADA-MORA', 'Kahathuduwa Entrance', 'කහතුඩුව පිවිසුම', ST_SetSRID(ST_MakePoint(80.0870, 6.8200), 4326), 3, FALSE),
('HALT-KADA-MORA-004', '255-KADA-MORA', 'Kottawa', 'කොට්ටාව', ST_SetSRID(ST_MakePoint(79.9860, 6.8380), 4326), 4, FALSE),
('HALT-KADA-MORA-005', '255-KADA-MORA', 'Piliyandala', 'පිළියන්දල', ST_SetSRID(ST_MakePoint(79.9220, 6.8010), 4326), 5, FALSE),
('HALT-KADA-MORA-006', '255-KADA-MORA', 'Angulana', 'අඟුලාන', ST_SetSRID(ST_MakePoint(79.8725, 6.7895), 4326), 6, FALSE),
('HALT-KADA-MORA-007', '255-KADA-MORA', 'Katubedda Junction', 'කටුබැද්ද හන්දිය', ST_SetSRID(ST_MakePoint(79.8790, 6.8130), 4326), 7, FALSE),
('HALT-KADA-MORA-008', '255-KADA-MORA', 'Rawathawatte', 'රාවතාවත්ත', ST_SetSRID(ST_MakePoint(79.8845, 6.7890), 4326), 8, FALSE),
('HALT-KADA-MORA-009', '255-KADA-MORA', 'Moratuwa Bus Stand', 'මොරටුව බස් නැවතුම', ST_SetSRID(ST_MakePoint(79.8830, 6.7730), 4326), 9, FALSE);

INSERT INTO timetable_entries (
    route_id,
    halt_id,
    scheduled_arrival,
    scheduled_departure,
    day_mask,
    effective_from
) VALUES
('255-MORA-KADA', 'HALT-MORA-KADA-001', '06:00', '06:00', 127, CURRENT_DATE),
('255-MORA-KADA', 'HALT-MORA-KADA-007', '06:45', '06:46', 127, CURRENT_DATE),
('255-MORA-KADA', 'HALT-MORA-KADA-009', '07:30', '07:30', 127, CURRENT_DATE),
('255-KADA-MORA', 'HALT-KADA-MORA-001', '06:00', '06:00', 127, CURRENT_DATE),
('255-KADA-MORA', 'HALT-KADA-MORA-003', '06:45', '06:46', 127, CURRENT_DATE),
('255-KADA-MORA', 'HALT-KADA-MORA-009', '07:30', '07:30', 127, CURRENT_DATE);

COMMIT;
