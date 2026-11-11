-- Shared dataset tables, used by all tasks.
--
-- Define the structure of the database before data insertion
-- Task-specific migrations can reference these tables with views and foreign keys from their own schemas.

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS public.osm_nodes (
    osmid      bigint,
    y          double precision,
    x          double precision,
    street_cou bigint,
    ref        text,
    highway    text,
    geometry   geometry(Point, 4326)
);

CREATE TABLE IF NOT EXISTS public.osm_edges (
    u        bigint,
    v        bigint,
    key      bigint,
    osmid    text,
    oneway   text,
    lanes    text,
    name     text,
    highway  text,
    length   double precision,
    bridge   text,
    ref      text,
    tunnel   text,
    junction text,
    maxspeed text,
    access   text,
    service  text,
    width    text,
    fid      bigint,
    geometry geometry(LineString, 4326)
);

CREATE TABLE IF NOT EXISTS public.trajectories (
    dataset       text,
    taxi_id       text,
    trajectory_id text,
    gps_points    jsonb,
    road_points   jsonb
);

-- Primary keys (the importer upserts on these)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.osm_nodes'::regclass AND contype = 'p') THEN
        ALTER TABLE public.osm_nodes ADD CONSTRAINT osm_nodes_pkey PRIMARY KEY (osmid);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.osm_edges'::regclass AND contype = 'p') THEN
        ALTER TABLE public.osm_edges ADD CONSTRAINT osm_edges_pkey PRIMARY KEY (fid);
    END IF;
END $$;

DROP INDEX IF EXISTS public.osm_edges_fid_idx;

CREATE INDEX IF NOT EXISTS osm_edges_u_idx         ON public.osm_edges (u);
CREATE INDEX IF NOT EXISTS osm_edges_v_idx         ON public.osm_edges (v);
CREATE INDEX IF NOT EXISTS osm_nodes_geometry_gist ON public.osm_nodes USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_edges_geometry_gist ON public.osm_edges USING gist (geometry);
CREATE INDEX IF NOT EXISTS trajectories_trip_idx   ON public.trajectories (dataset, taxi_id, trajectory_id);

-- One road-following line per trip
CREATE OR REPLACE VIEW public.trajectory_lines AS
SELECT
    t.dataset,
    t.taxi_id,
    t.trajectory_id,
    ST_SetSRID(ST_MakeLine(e.geometry ORDER BY p.ordinality), 4326)::geometry(LineString, 4326) AS geometry
FROM public.trajectories t
CROSS JOIN LATERAL jsonb_array_elements(t.road_points)
    WITH ORDINALITY AS p(value, ordinality)
JOIN public.osm_edges e
    ON e.fid = (p.value->>0)::bigint
GROUP BY
    t.dataset,
    t.taxi_id,
    t.trajectory_id;
