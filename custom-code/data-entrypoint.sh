#!/bin/bash

set -eo pipefail

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

echo "Generating db..."
if [[ ! -f /app/db/db-done ]]; then
    /app/bin/init_osm3s.sh /data/planet.osm.bz2 /app/db /app --meta=yes "--version=$(osmium fileinfo -e -g data.timestamp.last /data/planet.osm.bz2)" &&
    touch /app/db/db-done
fi
if [[ ! -f /app/db/replicate_id ]]; then
    echo "Initializing replicate_id..."
    echo "${TARGET_SEQUENCE_NUMBER}" > /app/db/replicate_id
    chown overpass:overpass /app/db/replicate_id
    chmod 644 /app/db/replicate_id
fi

echo "Starting updater..."
/app/bin/update_overpass_loop.sh -O /data/planet.osm.bz2 &
/app/bin/rules_loop.sh /app/db "$OVERPASS_RULES_LOAD"
wait
