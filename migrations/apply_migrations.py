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

for file in sorted(migrations_dir.glob("*.sql")):
    cursor.execute("SELECT name FROM schema_migrations WHERE name = %s", (file.name,))
    if cursor.fetchone():
        continue

    print(f"Applying: {file.name}...", flush=True)
    cursor.execute(file.read_text())
    cursor.execute("INSERT INTO schema_migrations (name) VALUES (%s)", (file.name,))

connection.commit()
print("All migrations successfully applied!")
connection.close()
