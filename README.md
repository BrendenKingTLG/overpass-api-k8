# overpass-api-k8

## Overview

This repository provides a Dockerized setup for running an Overpass API instance with custom code and regularly updated OSM data. The setup includes services for both the Overpass API and a dedicated data management container.

## Prerequisites

- Docker
- Docker Compose
- wget

## Project Structure

```markdown
.
├── custom-code/          # Your custom scripts and configurations
├── overpass/             # Overpass API Docker build context
├── mounts/
│   ├── db/               # Persistent database storage
│   └── data/             # OSM data storage
├── docker-compose.yml
├── Makefile
└── README.md
```

## Commands

All commands are available via the Makefile for convenience.

### Initialize Project

Copies custom code into the Overpass build context and downloads the initial PBF data file.

```bash
make init
```

### Start Services

Builds and starts the Overpass API and data services.

```bash
make start
```

### Stop Services

Stops and removes the running containers.

```bash
make stop
```

### Copy Custom Code

Re-copies your custom code into the Overpass directory (useful after updates).

```bash
make copy
```

### Download Latest PBF

Downloads the latest OSM data for Missouri.

```bash
make download-pbf
```

### Clean Database

Removes all existing database files.

```bash
make clean
```

## Docker Services

### overpass

- **Purpose**: Hosts the Overpass API server.
- **Ports**: Exposes port `12345` mapped to container port `80`.
- **Volumes**:
  - `./mounts/db:/app/db`
  - `./mounts/data:/data`
- **Environment Variables**:
  - `OVERPASS_META=no`
  - `OVERPASS_MODE=init`
  - `OVERPASS_UPDATE_SLEEP=3600`
  - `OVERPASS_RULES_LOAD=-1`
  - `OVERPASS_STOP_AFTER_INIT=false`
  - `OVERPASS_USE_AREAS=true`

### data-service

- **Purpose**: Handles data updates and loading of diffs.
- **Volumes**:
  - `./mounts/db:/app/db`
  - `./mounts/data:/data`
- **Environment Variables**:
  - `OVERPASS_META=no`
  - `OVERPASS_MODE=init`
  - `OVERPASS_DIFF_URL=https://download.geofabrik.de/north-america/us/missouri-updates/`
  - `OVERPASS_UPDATE_SLEEP=3600`
  - `OVERPASS_RULES_LOAD=-1`
  - `OVERPASS_STOP_AFTER_INIT=false`
  - `OVERPASS_USE_AREAS=true`
  - `TARGET_SEQUENCE_NUMBER=4237`

## Example Usage

1. Initialize the project:

```bash
make init
```

2. Start the containers:

```bash
make start
```

3. Access the Overpass API at: [http://localhost:12345/api/interpreter](http://localhost:12345/api/interpreter)

## Maintenance

- Periodically run `make download-pbf` to refresh local data.
- Use `make clean` if you need to reset the database.
