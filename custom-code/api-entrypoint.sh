#!/bin/bash

set -eo pipefail

echo "Generating db..."
CURL_STATUS_CODE=$(curl -L -b /db/cookie.jar -o /db/planet.osm.bz2 -w "%{http_code}" "${OVERPASS_PLANET_URL}")
while [ "$CURL_STATUS_CODE" = "429" ]; do
    echo "Server responded with 429 Too many requests. Trying again in 5 minutes..."
    sleep 300
    CURL_STATUS_CODE=$(curl -L -b /db/cookie.jar -o /db/planet.osm.bz2 -w "%{http_code}" "${OVERPASS_PLANET_URL}")
done

/app/bin/init_osm3s.sh /db/planet.osm.bz2 /app/db /app --meta=yes "--version=$(osmium fileinfo -e -g data.timestamp.last /db/planet.osm.bz2)" &&
/app/bin/osm3s_query --progress --rules --db-dir=/app/db < /app/etc/rules/areas.osm3s

echo "Stopping any existing dispatcher and nginx processes..."
pkill dispatcher || true
pkill nginx || true

echo "Removing stale socket files..."
rm -f /app/db/osm3s_areas || true
rm -f /app/db/osm3s_osm_base || true
rm -f /dev/shm/osm3s_areas || true
rm -f /dev/shm/osm3s_osm_base || true

echo "Starting dispatcher for osm-base..."
/app/bin/dispatcher --osm-base --meta --db-dir=/app/db &
sleep 10

echo "Starting dispatcher for areas..."
/app/bin/dispatcher --areas --allow-duplicate-queries=yes --db-dir=/app/db &
sleep 10

echo "Setting up FastCGI permissions..."
/app/bin/start_fcgiwarp.sh &
sleep 5

echo "Starting Nginx in foreground mode..."
exec nginx

