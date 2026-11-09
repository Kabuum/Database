-- traversal: weak entity owned by trip (map-matched segment sequence)
CREATE TABLE attribute_prediction.traversal (
    trip_id    bigint NOT NULL REFERENCES attribute_prediction.trip (trip_id) ON DELETE CASCADE,
    seq        int    NOT NULL,                        -- position in the trip (partial key)
    segment_id bigint NOT NULL REFERENCES public.osm_edges (fid),
    enter_time timestamp        NOT NULL,
    duration_s double precision NOT NULL CHECK (duration_s >= 0),
    speed_mps  double precision NOT NULL CHECK (speed_mps >= 0),
    PRIMARY KEY (trip_id, seq)
);

CREATE INDEX traversal_segment_idx ON attribute_prediction.traversal (segment_id);
