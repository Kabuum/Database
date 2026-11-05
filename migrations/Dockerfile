FROM python:3.14-slim

WORKDIR /app
RUN pip install --no-cache-dir psycopg2-binary
COPY migrations/ ./migrations/

CMD ["python", "migrations/apply_migrations.py"]
