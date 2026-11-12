# aSTEP Data!

## Env stuff

### Must do
Run

```bash
cp .env.example .env
```
or if on windows
```bash
copy .env.example .env
```


### Nice to do (mostly if you want nice syntax sugar)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip3 install -r requirements.txt
```

## Setup

For now it is running in Docker.
Make sure you have the latest Docker version and compose plugin.
btw if you find Docker slow, i would suggest using a different runtime like Colima.
Also, we might modify these scripts, when this is deployed with Kubernetes (it's not right now).

### Wanna setup everything

This sets up the database, runs migrations, downloads the [v1.0.0 release](https://github.com/astep-aau/data/releases/tag/v1.0.0), and imports it into PostGIS. Allow at least 6 GB of disk space for the downloads, plus space for the extracted map and database.

```bash
docker compose up -d --build
```

### Just setup db?

```bash
docker compose up -d --build db
```

### Run migrations

```bash
docker compose run --rm migrate
```

Migrations are tracked in `schema_migrations` by their path relative to `migrations/files/`, so each file runs once.

- **Shared migrations** go directly in `migrations/files/` (e.g. `0002_dataset_tables.sql`). They run first, in filename order.
- **Task-specific migrations** go in `migrations/files/<task>/`, a folder named after the subject or task (e.g. `attribute_prediction`), numbered from `0001` within the folder. They create their objects in a schema with the same name as the folder. Task folders run after the shared files, alphabetically.

`0002_dataset_tables.sql` creates the dataset tables (`osm_nodes`, `osm_edges`, `trajectories`) and the `trajectory_lines` view. The importer only loads rows into them, so task-specific migrations can safely build views and foreign keys on them (`osm_nodes.osmid` and `osm_edges.fid` are primary keys). Migrations always run before the import.

### Just get data?

```bash
docker compose up -d --build get-data
```

The importer fills `osm_nodes`, `osm_edges`, and `trajectories` (created by the migrations, together with the `trajectory_lines` view). The trajectory table stores `taxi_id` from CSV column 1 and `trajectory_id` from CSV column 2. `trajectory_lines` creates one road-following PostGIS line per trip when queried. Use `dataset = 'traj_train_100'` when viewing the complete training data because the smaller training files overlap. Release files are checksum-verified and cached in the `dataset` Docker volume. The map is extracted into `bj_data/map/`. On re-import, nodes and edges are upserted on their primary key and trajectories are reloaded; the tables themselves are never dropped.

### Kubernetes deployment

Pushes to `main` build the importer and migration images, deploy the PostGIS database, and run migrations and the import Job in the `main` namespace. The cluster must have the existing `postgres-secret`, access to the GHCR image, enough disk space, and a self-hosted runner with a valid kubeconfig and permission to manage these resources. The PVC requests 100 GiB; the import Job uses up to 10 GiB of temporary download storage. A completed Job prevents re-imports; a failed Job is replaced on the next deployment.

Monitor the import with `kubectl logs -f job/dataset-import -n main`. If the import fails, the next deployment retries it and replaces any partially imported dataset tables.

### Wanna watch?

```bash
docker compose logs -f
```
