-- trip: one GPS trajectory
CREATE TABLE attribute_prediction.trip (
    trip_id    bigint    PRIMARY KEY,
    start_time timestamp NOT NULL,
    end_time   timestamp NOT NULL,
    start_pos  public.geometry(Point, 4326),
    end_pos    public.geometry(Point, 4326),
    CHECK (end_time >= start_time)
);
