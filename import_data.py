import ast
import csv
import io
import json
import os

import geopandas as gpd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


from download_data import DATA_DIR, download_data
TRAJECTORY_FILES = [
    "traj_train_20.csv",
    "traj_train_40.csv",
    "traj_train_60.csv",
    "traj_train_80.csv",
    "traj_train_100.csv",
    "traj_valid.csv",
    "traj_test.csv",
]


def upsert_geodataframe(engine, frame, table, key):
    """Load frame into an existing table, matching rows on its primary key.

    The table is owned by the migrations (migrations/files/0002_dataset_tables.sql)
    and may be referenced by views and foreign keys in task schemas, so it is
    never dropped. Rows are loaded into a staging table and upserted.
    """
    staging = f"_staging_{table}"
    frame.to_postgis(staging, engine, if_exists="replace", index=False)

    columns = ", ".join(f'"{column}"' for column in frame.columns)
    updates = ", ".join(
        f'"{column}" = EXCLUDED."{column}"' for column in frame.columns if column != key
    )
    with engine.begin() as connection:
        connection.execute(
            text(
                f"INSERT INTO {table} ({columns}) SELECT {columns} FROM {staging} "
                f'ON CONFLICT ("{key}") DO UPDATE SET {updates}'
            )
        )
        # Remove rows no longer in the dataset. Fails (on purpose) if a task schema
        # still references them with a foreign key.
        connection.execute(
            text(
                f"DELETE FROM {table} t WHERE NOT EXISTS "
                f'(SELECT 1 FROM {staging} s WHERE s."{key}" = t."{key}")'
            )
        )
        connection.execute(text(f"DROP TABLE {staging}"))


def insert_nodes(engine):
    print("Inserting nodes...")
    nodes = gpd.read_file(f"{DATA_DIR}/map/nodes.shp")
    upsert_geodataframe(engine, nodes, "osm_nodes", "osmid")


def insert_edges(engine):
    print("Inserting edges...")
    edges = gpd.read_file(f"{DATA_DIR}/map/edges.shp")
    upsert_geodataframe(engine, edges, "osm_edges", "fid")


def insert_rows(cursor, query, rows):
    file = io.StringIO()
    csv.writer(file, lineterminator="\n").writerows(rows)
    file.seek(0)
    cursor.copy_expert(query, file)


def insert_trajectories(engine):
    print("Inserting trajectories...")
    connection = engine.raw_connection()
    cursor = connection.cursor()
    # Table, index and the trajectory_lines view are created by the migrations
    cursor.execute("TRUNCATE trajectories")

    trajectory_query = (
        "COPY trajectories (dataset, taxi_id, trajectory_id, gps_points, road_points) "
        "FROM STDIN WITH CSV"
    )

    for filename in TRAJECTORY_FILES:
        print(f"  {filename}")
        rows = []
        with open(f"{DATA_DIR}/{filename}", newline="") as file:
            for row in csv.reader(file):
                gps_points = ast.literal_eval(row[2])
                rows.append(
                    (
                        filename[:-4],
                        row[0],
                        row[1],
                        json.dumps(gps_points, separators=(",", ":")),
                        json.dumps(ast.literal_eval(row[3]), separators=(",", ":")),
                    )
                )
                if len(rows) == 5000:
                    insert_rows(cursor, trajectory_query, rows)
                    rows = []

        if rows:
            insert_rows(cursor, trajectory_query, rows)

    connection.commit()
    connection.close()


def main():
    load_dotenv()
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        database_url = URL.create(
            "postgresql+psycopg2",
            username=os.environ["POSTGRES_USER"],
            password=os.environ["POSTGRES_PASSWORD"],
            host=os.environ["POSTGRES_HOST"],
            database=os.environ["POSTGRES_DB"],
        )

    engine = create_engine(database_url)
    download_data()
    with engine.begin() as connection:
        connection.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))

    insert_nodes(engine)
    insert_edges(engine)
    insert_trajectories(engine)
    print("Done")


if __name__ == "__main__":
    main()
