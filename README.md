# overpass-k8s

## Overview

This repository provides a Helm-based Kubernetes deployment for running an Overpass API instance with custom code and regularly updated OSM data.  
It supports running locally on a kind (Kubernetes in Docker) cluster, with Docker image building, loading, and deployment streamlined via a `Makefile`.

---

## Prerequisites

- Docker Desktop  
- kind (Kubernetes in Docker)  
- Helm  
- wget  

---

## Project Structure

```
.
├── custom-code/          # Your custom Overpass scripts and configurations
├── overpass/             # Overpass API Docker build context
├── mounts/
│   ├── db/               # Persistent database storage
│   └── data/             # OSM data storage
├── helm/                 # Helm chart for Kubernetes deployment
├── Makefile
└── README.md
```

---

## Makefile Commands

All commands are available via the provided `Makefile`.

### Initialize Project
Copies custom code and downloads the latest PBF file:
```bash
make init
```

### Copy Custom Code
Re-copies your custom code into the Overpass directory (useful after changes):
```bash
make copy
```

### Download Latest PBF
Downloads the most recent OSM data (default: Missouri):
```bash
make download-pbf
```
> Default URL: `https://download.geofabrik.de/north-america/us/missouri-latest.osm.bz2`

### Clean Database
Removes existing local database files:
```bash
make clean
```

### Build Docker Image
Builds the Overpass API Docker image:
```bash
make build
```

### Deploy to kind via Helm
Builds the image, loads it into kind, and deploys the Helm chart:
```bash
make install
```

### Uninstall from Kubernetes
Uninstalls the Helm release:
```bash
make uninstall
```

---

## Configuration

The following enviroment variables can be used to customize the setup:

* `OVERPASS_MODE` - takes the value of either `init` or `clone`. Defaults to `clone`.
* `OVERPASS_META` - (`init` mode only) `yes`, `no` or `attic` - passed to Overpass as `--meta` or `--keep-attic`.
* `OVERPASS_PLANET_URL` - (`init` mode only) url to a "planet" file (e.g. https://planet.openstreetmap.org/planet/planet-latest.osm.bz2)
* `OVERPASS_CLONE_SOURCE` - (`clone` mode only) the url to clone a copy of Overpass from. Defaults to https://dev.overpass-api.de/api_drolbr/, which uses minute diffs.
* `OVERPASS_DIFF_URL` - url to a diff directory for updating the instance (e.g. https://planet.openstreetmap.org/replication/minute/).
* `OVERPASS_COMPRESSION` - (`init` mode only) takes values of `no`, `gz` or `lz4`. Specifies compression mode of the Overpass database. Defaults to `gz`.
* `OVERPASS_RULES_LOAD` - integer, desired load from area generation. Controls the ratio of sleep to work. A value of 1 will make the system sleep 99x times longer than it works, a value of 50 will result in sleep and work in equal measure, and a value of 100 will only sleep 3 seconds between each execution. Defaults to 1.
* `OVERPASS_UPDATE_SLEEP` - integer, the delay between updates (seconds).
* `OVERPASS_COOKIE_JAR_CONTENTS` - cookie-jar compatible content to be used when fetching planet.osm files and updates.
* `OVERPASS_PLANET_PREPROCESS` - commands to be run before passing the planet.osm file to `update_database`, e.g. conversion from pbf to osm.bz2 using osmium.
* `USE_OAUTH_COOKIE_CLIENT` - set to `yes` if you want to use oauth_cookie_client to update cookies before each update. Settings are read from /secrets/oauth-settings.json. Read the documentation [here](https://github.com/geofabrik/sendfile_osm_oauth_protector/blob/master/doc/client.md).
* `OVERPASS_FASTCGI_PROCESSES` - number of fcgiwarp processes. Defaults to 4. Use higher values if you notice performance problems.
* `OVERPASS_RATE_LIMIT` - set the maximum allowed number of concurrent accesses from a single IP address.
* `OVERPASS_TIME` - set the maximum amount of time units (available time).
* `OVERPASS_SPACE` - set the maximum amount of RAM (available space) in bytes.
* `OVERPASS_MAX_TIMEOUT` - set the maximum timeout for queries (default: 1000s). Translates to send/recv timeout for fastcgi_wrap.
* `OVERPASS_USE_AREAS` - if `false` initial area generation and the area updater process will be disabled. Default `true`.
* `OVERPASS_HEALTHCHECK` - shell commands to execute to verify that image is healthy. `exit 1` in case of failures, `exit 0` when container is healthy. Default healthcheck queries overpass and verifies that there is reponse returned
* `OVERPASS_STOP_AFTER_INIT` - if `false` the container will keep runing after init is complete. Otherwise container will be stopped after initialization process is complete. Default `true`
* `OVERPASS_ALLOW_DUPLICATE_QUERIES` - if `yes`, duplicate queries (same query from the same IP address) will be allowed. Default `no`.

## Kubernetes Deployment Details

### Service
- **Service Name**: `api` (or `overpass-service` if changed in chart)
- **Type**: `NodePort`
- **Port**: exposed on a random high port (check with `kubectl get svc`)

### Accessing the Overpass API
After deploying:
```bash
kubectl get svc
```
Example output:
```
NAME    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
api     NodePort   10.110.60.10   <none>        80:31416/TCP    2m
```
You can access it at:
```
http://localhost:<nodeport>/
```
In the above example:
```
http://localhost:31416/api/interpreter
```

Or use port-forwarding (recommended for local development):
```bash
kubectl port-forward svc/api 8080:80
```
Then access at:
```
http://localhost:8080/api/interpreter
```

---

## Example Usage Flow

```bash
make init
make build
kind load docker-image overpass-k8s:latest
make install
kubectl get svc
```
> Visit the API endpoint at `http://localhost:<nodeport>/api/interpreter`.

---

## Maintenance Tips

- Run `make download-pbf` periodically to update the OSM data.
- Use `make clean` to reset the database if needed.
- Use `make uninstall` to remove the Helm deployment from your kind cluster.