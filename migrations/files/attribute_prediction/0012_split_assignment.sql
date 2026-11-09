-- split_assignment: M:N relationship "assigned to" (label masks)
CREATE TABLE attribute_prediction.split_assignment (
    split_id   int       NOT NULL REFERENCES attribute_prediction.split (split_id) ON DELETE CASCADE,
    segment_id bigint    NOT NULL REFERENCES public.osm_edges (fid) ON DELETE CASCADE,
    partition  attribute_prediction.partition NOT NULL,
    PRIMARY KEY (split_id, segment_id)
);
