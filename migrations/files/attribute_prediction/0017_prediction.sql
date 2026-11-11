-- prediction: ternary relationship "predicts" (run x segment x class/value)
-- classification -> predicted_class_id (+ probabilities), regression -> predicted_value
CREATE TABLE attribute_prediction.prediction (
    run_id             int    NOT NULL REFERENCES attribute_prediction.model_run (run_id) ON DELETE CASCADE,
    segment_id         bigint NOT NULL REFERENCES public.osm_edges (fid),
    predicted_class_id int    REFERENCES attribute_prediction.attribute_class (class_id),
    predicted_value    double precision,
    probabilities      double precision[],
    PRIMARY KEY (run_id, segment_id),
    CHECK ((predicted_class_id IS NULL) <> (predicted_value IS NULL))
);

CREATE INDEX prediction_segment_idx ON attribute_prediction.prediction (segment_id);
