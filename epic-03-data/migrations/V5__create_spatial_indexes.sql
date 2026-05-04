-- flyway:executeInTransaction=false

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_halts_location_gist
    ON halts
    USING GIST ((location::geography));

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_halts_location_geometry_gist
    ON halts
    USING GIST (location);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_routes_polyline_gist
    ON routes
    USING GIST (route_polyline);

ANALYZE halts;
ANALYZE routes;
