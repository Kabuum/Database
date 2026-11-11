-- Enum types used across the schema
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE attribute_prediction.partition    AS ENUM ('train', 'val', 'test');
CREATE TYPE attribute_prediction.task_type    AS ENUM ('classification', 'regression');
-- fine = per class; coarse = classes grouped by attribute_class.category (regression metrics use fine)
CREATE TYPE attribute_prediction.metric_level AS ENUM ('fine', 'coarse');
CREATE TYPE attribute_prediction.run_status   AS ENUM ('running', 'finished', 'failed');
