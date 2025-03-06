init: 
	cp -r custom-code/* overpass/

start:
	docker compose up --build --remove-orphans

clean:
	rm -r ./mounts/db/* 2>/dev/null || echo "No files to remove"
