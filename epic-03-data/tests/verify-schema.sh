#!/usr/bin/env bash
set -euo pipefail

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-transit_db}"
export PGUSER="${PGUSER:-transit_admin}"

psql -v ON_ERROR_STOP=1 <<'SQL'
SELECT PostGIS_Version();
SELECT ST_AsText(ST_MakePoint(79.8820, 6.7730));

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('routes', 'halts', 'vehicles', 'timetable_entries')
ORDER BY table_name;

SELECT indexname
FROM pg_indexes
WHERE tablename = 'halts'
  AND indexname = 'idx_halts_location_gist';

SELECT COUNT(*) AS outbound_halts
FROM halts
WHERE route_id = '255-MORA-KADA';

SELECT ST_AsText(location) AS katubedda_location
FROM halts
WHERE halt_name_en = 'Katubedda Junction'
  AND route_id = '255-MORA-KADA';

SELECT ST_AsText(boundary) AS kahathuduwa_geofence
FROM system_geofences
WHERE fence_name = 'KAHATHUDUWA_ENTRY';
SQL
