INSERT INTO stops (id, name, location)
VALUES
    (25501, 'Moratuwa Bus Stand', ST_SetSRID(ST_MakePoint(79.882, 6.773), 4326)),
    (25502, 'Katubedda', ST_SetSRID(ST_MakePoint(79.886, 6.796), 4326)),
    (25503, 'Piliyandala', ST_SetSRID(ST_MakePoint(79.922, 6.801), 4326)),
    (25504, 'Kahathuduwa Entrance', ST_SetSRID(ST_MakePoint(80.086, 6.821), 4326)),
    (25505, 'Kadawatha Exit', ST_SetSRID(ST_MakePoint(79.950, 7.001), 4326)),
    (25506, 'Kadawatha Bus Stand', ST_SetSRID(ST_MakePoint(79.954, 7.005), 4326))
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    location = EXCLUDED.location;

INSERT INTO routes (id, route_number, name, color, destination, geometry)
VALUES (
    255,
    '255',
    'Moratuwa - Kadawatha',
    '#2563eb',
    'Kadawatha',
    ST_GeomFromText(
        'LINESTRING(79.882 6.773, 79.886 6.796, 79.922 6.801, 80.086 6.821, 79.950 7.001, 79.954 7.005)',
        4326
    )
)
ON CONFLICT (id) DO UPDATE
SET
    route_number = EXCLUDED.route_number,
    name = EXCLUDED.name,
    color = EXCLUDED.color,
    destination = EXCLUDED.destination,
    geometry = EXCLUDED.geometry;

DELETE FROM route_stop_links
WHERE route_id = 255;

INSERT INTO route_stop_links (route_id, stop_id, stop_order)
VALUES
    (255, 25501, 1),
    (255, 25502, 2),
    (255, 25503, 3),
    (255, 25504, 4),
    (255, 25505, 5),
    (255, 25506, 6);

SELECT setval(pg_get_serial_sequence('routes', 'id'), GREATEST((SELECT MAX(id) FROM routes), 1));
SELECT setval(pg_get_serial_sequence('stops', 'id'), GREATEST((SELECT MAX(id) FROM stops), 1));
SELECT setval(pg_get_serial_sequence('route_stop_links', 'id'), GREATEST((SELECT MAX(id) FROM route_stop_links), 1));
