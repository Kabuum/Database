-- feature_set_feature: multivalued attribute feature_list
CREATE TABLE attribute_prediction.feature_set_feature (
    feature_set_id int  NOT NULL REFERENCES attribute_prediction.feature_set (feature_set_id) ON DELETE CASCADE,
    feature_name   text NOT NULL,
    PRIMARY KEY (feature_set_id, feature_name)
);
