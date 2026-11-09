-- segment: view over public.osm_edges in the logical schema's shape (no data copied)
-- segment_id = osm_edges.fid; u/v = osm_nodes.osmid
CREATE VIEW attribute_prediction.segment AS
SELECT fid                                                AS segment_id,
       u,                                                 -- start node
       v,                                                 -- end node
       length                                             AS length_m,
       -- OSMnx writes oneway as 'True'/'False'; also accept raw OSM values
       COALESCE(lower(oneway) IN ('true', 'yes', '1', '-1'), false) AS oneway,
       geometry                                           AS geom,   -- LineString, 4326
       -- osm_tags (composite attribute, flattened)
       highway, lanes, maxspeed, ref, name, bridge, tunnel
FROM public.osm_edges;
