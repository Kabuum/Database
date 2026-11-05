# aSTEP Data!

## Env stuff

### Must do

```bash
cp .env.example .env
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

This installs everything, sets up the database, downloads the [v1.0.0 release](https://github.com/astep-aau/data/releases/tag/v1.0.0), and imports it into PostGIS. Allow at least 6 GB of disk space for the downloads, plus space for the extracted map and database.

```bash
docker compose up -d --build
```

### Just setup db?

```bash
docker compose up -d --build db
```

### Just get data?

```bash
docker compose up -d --build get-data
```

The importer creates `osm_nodes`, `osm_edges`, and `trajectories`, plus a `trajectory_lines` view. The trajectory table stores `taxi_id` from CSV column 1 and `trajectory_id` from CSV column 2. `trajectory_lines` creates one road-following PostGIS line per trip when queried. Use `dataset = 'traj_train_100'` when viewing the complete training data because the smaller training files overlap. Release files are checksum-verified and cached in the `dataset` Docker volume. The map is extracted into `bj_data/map/`. The importer replaces existing dataset tables when it runs.

### Kubernetes deployment

Pushes to `main` build the importer image and deploy the PostGIS database and import Job in the `main` namespace. The cluster must have the existing `postgres-secret`, access to the GHCR image, enough disk space, and a self-hosted runner with a valid kubeconfig and permission to manage these resources. The PVC requests 100 GiB; the import Job uses up to 10 GiB of temporary download storage. A completed Job prevents re-imports; a failed Job is replaced on the next deployment.

Monitor the import with `kubectl logs -f job/dataset-import -n main`. If the import fails, the next deployment retries it and replaces any partially imported dataset tables.

### Wanna watch?

```bash
docker compose logs -f
```
