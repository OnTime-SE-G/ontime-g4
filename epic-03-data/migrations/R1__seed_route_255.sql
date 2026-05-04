-- TODO: Implement according to G4 guide and issue assignment.

-- this a placeholder file to see whether its working correctly data might not be fully accurate
-- ==========================================
-- 1. CLEANUP (Because this is a Repeatable file)
-- ==========================================
-- We delete existing data so if we run this file twice, it doesn't create duplicates.
DELETE FROM timetable_entries;
DELETE FROM vehicles;
DELETE FROM routes;
DELETE FROM halts;

-- ==========================================
-- 2. CREATE GEOFENCES CONFIG TABLE
-- ==========================================
-- The schema didn't have this, but DR-02 requires it. 
CREATE TABLE IF NOT EXISTS system_geofences (
    fence_name VARCHAR(50) PRIMARY KEY,
    boundary GEOMETRY(Polygon, 4326) NOT NULL
);

-- Insert the Kahathuduwa Toll Gate (200m radius around 6.820 N, 80.087 E)
-- We use ST_Buffer to automatically draw a 200-meter circle around the center point.
INSERT INTO system_geofences (fence_name, boundary)
VALUES (
    'KAHATHUDUWA_ENTRY',
    ST_Buffer(ST_SetSRID(ST_MakePoint(80.087, 6.820), 4326)::geography, 200)::geometry
) ON CONFLICT (fence_name) DO NOTHING;

-- ==========================================
-- 3. SEED HALTS (Bus Stops)
-- ==========================================
-- Note: ST_MakePoint takes (Longitude, Latitude)
INSERT INTO halts (halt_id, halt_name_en, halt_name_si, location, halt_sequence, is_expressway_halt) VALUES
('HALT-MORA-01', 'Moratuwa Bus Stand', 'මොරටුව බස් නැවතුම', ST_SetSRID(ST_MakePoint(79.882, 6.773), 4326), 0, FALSE),
('HALT-KATU-02', 'Katubedda', 'කටුබැද්ද', ST_SetSRID(ST_MakePoint(79.886, 6.796), 4326), 1, FALSE),
('HALT-PILI-03', 'Piliyandala', 'පිළියන්දල', ST_SetSRID(ST_MakePoint(79.922, 6.801), 4326), 2, FALSE),
('HALT-KAHA-04', 'Kahathuduwa Entrance', 'කහතුඩුව පිවිසුම', ST_SetSRID(ST_MakePoint(80.086, 6.821), 4326), 3, FALSE),
('HALT-KADA-05', 'Kadawatha Exit', 'කඩවත පිටවීම', ST_SetSRID(ST_MakePoint(79.950, 7.001), 4326), 4, TRUE),
('HALT-KADA-06', 'Kadawatha Bus Stand', 'කඩවත බස් නැවතුම', ST_SetSRID(ST_MakePoint(79.954, 7.005), 4326), 5, FALSE);

-- ==========================================
-- 4. SEED ROUTES
-- ==========================================
-- We use a simple straight LineString from Moratuwa to Kadawatha for testing.
INSERT INTO routes (route_id, route_number, origin_halt_id, destination_halt_id, direction, highway_entry_halt_id, name_en, name_si, route_polyline) VALUES
(
    '255-MORA-KADA', 
    '255', 
    'HALT-MORA-01', 
    'HALT-KADA-06', 
    'OUTBOUND', 
    'HALT-KAHA-04', 
    'Moratuwa - Kadawatha', 
    'මොරටුව - කඩවත',
    ST_GeomFromText('LINESTRING(79.882 6.773, 80.086 6.821, 79.954 7.005)', 4326)
);

-- ==========================================
-- 5. LINK FOREIGN KEYS
-- ==========================================
-- Now that the route exists, we can assign the route_id to the halts if you have that column, 
-- or you are good to go based on your current schema!