PBF_URL ?= https://download.geofabrik.de/north-america/us/missouri-latest.osm.bz2
PBF_FILE = ./mounts/data/planet.osm.bz2
IMAGE_NAME = overpass-k8s:latest

.PHONY: init copy download-pbf clean build kind-load deploy helm-delete

init: copy download-pbf

copy:
	cp -r custom-code/* overpass/

download-pbf:
	wget -O $(PBF_FILE) $(PBF_URL)

clean:
	rm -rf ./mounts/db/* 2>/dev/null || echo "No files to remove"

build: copy
	docker build --progress=plain -t $(IMAGE_NAME) ./overpass

install: copy build
	helm upgrade --install overpass-k8s ./helm

uninstall:
	helm uninstall overpass-k8s
