CREATE TABLE cities (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  location GEOMETRY (Point, 4326)
);
