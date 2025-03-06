#!/bin/bash

set -eo pipefail

echo "Waiting for db to exist..."
while [ ! -f "/app/db/db-done" ]; do
    sleep 1
done

echo "Removing stale socket files..."
rm -f /app/socket/osm3s_areas || true
rm -f /app/socket/osm3s_osm_base || true
rm -f /dev/shm/osm3s_areas || true
rm -f /dev/shm/osm3s_osm_base || true

echo "Starting dispatcher for osm-base..."
/app/bin/dispatcher --osm-base --socket-dir=/app/socket --meta --db-dir=/app/db &
sleep 10

echo "Starting dispatcher for areas..."
/app/bin/dispatcher --areas --socket-dir=/app/socket --allow-duplicate-queries=yes --db-dir=/app/db &
sleep 10


echo "Setting up FastCGI permissions..."
/app/bin/start_fcgiwarp.sh &
sleep 5

echo "Starting Nginx in foreground mode..."
exec nginx 

