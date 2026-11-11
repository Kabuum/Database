-- label_rule: a versioned rule set for deriving labels of an attribute
CREATE TABLE attribute_prediction.label_rule (
    attribute_id int  NOT NULL REFERENCES attribute_prediction.attribute (attribute_id),
    version      int  NOT NULL,
    description  text,
    created_at   timestamp NOT NULL DEFAULT now(),
    PRIMARY KEY (attribute_id, version)
);
