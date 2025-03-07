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
CURL_STATUS_CODE=$(curl -L -b /app/db/cookie.jar -o /db/planet.osm.bz2 -w "%{http_code}" "${OVERPASS_PLANET_URL}")
while [ "$CURL_STATUS_CODE" = "429" ]; do
    echo "Server responded with 429 Too many requests. Trying again in 5 minutes..."
    sleep 300
    CURL_STATUS_CODE=$(curl -L -b /app/db/cookie.jar -o /db/planet.osm.bz2 -w "%{http_code}" "${OVERPASS_PLANET_URL}")
done

if [[ ! -f /app/db/db-done ]]; then
    /app/bin/init_osm3s.sh /db/planet.osm.bz2 /app/db /app --meta=yes "--version=$(osmium fileinfo -e -g data.timestamp.last /db/planet.osm.bz2)" &&
    touch /app/db/db-done
fi
if [[ ! -f /app/db/replicate_id ]]; then
    echo "Initializing replicate_id..."
    echo "${TARGET_SEQUENCE_NUMBER}" > /app/db/replicate_id
    chown overpass:overpass /app/db/replicate_id
    chmod 644 /app/db/replicate_id
fi
/app/bin/update_overpass_loop.sh -O /db/planet.osm.bz2 &
# /app/bin/osm3s_query --progress --rules --db-dir=/app/db < /app/etc/rules/areas.osm3s &
wait
