-- segment_label: M:N relationship "labelled as" (segment x attribute x rule version)
-- classification -> class_id, regression -> value
CREATE TABLE attribute_prediction.segment_label (
    segment_id         bigint NOT NULL REFERENCES public.osm_edges (fid) ON DELETE CASCADE,
    attribute_id       int    NOT NULL,
    label_rule_version int    NOT NULL,
    class_id           int,
    value              double precision,
    PRIMARY KEY (segment_id, attribute_id, label_rule_version),
    FOREIGN KEY (attribute_id, label_rule_version)
        REFERENCES attribute_prediction.label_rule (attribute_id, version),
    FOREIGN KEY (attribute_id, class_id)
        REFERENCES attribute_prediction.attribute_class (attribute_id, class_id),
    CHECK ((class_id IS NULL) <> (value IS NULL))      -- exactly one of class_id / value
);

CREATE INDEX segment_label_attr_idx ON attribute_prediction.segment_label (attribute_id, label_rule_version);
