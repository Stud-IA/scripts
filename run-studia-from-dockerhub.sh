#! /bin/bash

echo 'Removing containers...'
podman container stop studia-postgres
podman container stop studia-core
podman container stop studia-ml
podman container rm studia-postgres
podman container rm studia-core
podman container rm studia-ml

echo 'Removing pod...'
podman pod stop studia-pod
podman pod rm studia-pod

echo 'Removing images...'
podman image rm studia-core-image
podman image rm studia-ml-image
podman image rm postgres

echo 'Downloading base images...'
podman pull mipardo/studia-ml-image:latest
podman pull mipardo/studia-core-image:latest
podman pull postgres:latest

echo 'Creating pod...'
podman pod create --name studia-pod -p 8080:8080 -p 8181:8181

echo 'Creating studia-postgres...'
podman run --name studia-postgres -d --pod studia-pod -e POSTGRES_PASSWORD=12345678 -e "TZ=GMT+1" postgres:latest
sleep 3
podman exec -it studia-postgres su postgres -c 'psql -c "create database studia_db;"'
podman exec -it studia-postgres su postgres -c 'psql -c "create user hibernate with password '\''hibernate'\'';"'
podman exec -it studia-postgres su postgres -c 'psql -c "grant all privileges on database studia_db to hibernate;"'
podman exec -it studia-postgres su postgres -c 'psql -c "\\c studia_db postgres;" -c "grant all on schema public to hibernate;"'

echo 'Creating studia-core...'
podman run -i -d --pod studia-pod --name studia-core studia-core-image:latest

echo 'Creating studia-ml...'
podman run -i -td --pod studia-pod --name studia-ml studia-ml-image:latest

