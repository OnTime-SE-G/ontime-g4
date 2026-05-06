CREATE INDEX IF NOT EXISTS idx_routes_geometry_gist
    ON routes USING GIST (geometry);

CREATE INDEX IF NOT EXISTS idx_stops_location_gist
    ON stops USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_route_stop_links_route_id
    ON route_stop_links (route_id);

CREATE INDEX IF NOT EXISTS idx_route_stop_links_stop_id
    ON route_stop_links (stop_id);

ANALYZE routes;
ANALYZE stops;
ANALYZE route_stop_links;
