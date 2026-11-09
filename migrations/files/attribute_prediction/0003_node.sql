-- node: view over public.osm_nodes in the logical schema's shape (no data copied)
CREATE VIEW attribute_prediction.node AS
SELECT osmid                     AS osm_id,
       geometry                  AS geom,          -- Point, 4326
       street_cou::int           AS street_count,
       NULLIF(highway, '')       AS highway_tag    -- e.g. traffic_signals, motorway_junction
FROM public.osm_nodes;
