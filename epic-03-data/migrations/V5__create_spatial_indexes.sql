-- TODO: Implement according to G4 guide and issue assignment.

-- GIST index on halt locations for proximity searches
CREATE INDEX idx_halts_location_gist ON halts USING GIST (location);

-- GIST index on route polylines for route rendering
CREATE INDEX idx_routes_polyline_gist ON routes USING GIST (route_polyline);


ANALYZE halts;
ANALYZE routes;