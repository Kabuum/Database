import os
from pathlib import Path

import psycopg2

connection = psycopg2.connect(
    host=os.environ["POSTGRES_HOST"],
    database=os.environ["POSTGRES_DB"],
    user=os.environ["POSTGRES_USER"],
    password=os.environ["POSTGRES_PASSWORD"],
)

cursor = connection.cursor()

cursor.execute("CREATE EXTENSION IF NOT EXISTS postgis")
cursor.execute("CREATE TABLE IF NOT EXISTS schema_migrations (name text PRIMARY KEY)")

migrations_dir = Path(__file__).resolve().parent / "files"

# Shared migrations live directly in files/; task-specific migrations in files/<task>/,
# a folder named after the subject or task.
# A migration is identified by its path relative to files/
# (e.g. "0002_dataset_tables.sql", "attribute_prediction/0001_schema.sql"),
# so each task folder can be numbered independently.
# Order: files/ first, then each task folder alphabetically, each in filename order.
migrations = sorted(
    (file.relative_to(migrations_dir).as_posix(), file)
    for file in migrations_dir.rglob("*.sql")
)

for name, file in migrations:
    cursor.execute("SELECT name FROM schema_migrations WHERE name = %s", (name,))
    if cursor.fetchone():
        continue

    print(f"Applying: {name}...", flush=True)
    cursor.execute(file.read_text())
    cursor.execute("INSERT INTO schema_migrations (name) VALUES (%s)", (name,))

connection.commit()
print("All migrations successfully applied!")
connection.close()
