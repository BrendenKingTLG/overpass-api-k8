init: 
	cp -r custom-code/* overpass/
	make download-pbf

start:
	docker compose up --build --remove-orphans

stop:
	docker compose down

copy:
	cp -r custom-code/* overpass/

download-pbf:
	wget -O ./mounts/data/planet.osm.bz2 https://download.geofabrik.de/north-america/us/missouri-latest.osm.bz2

clean:
	rm -r ./mounts/db/* 2>/dev/null || echo "No files to remove"


