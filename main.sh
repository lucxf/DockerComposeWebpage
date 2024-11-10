#!/bin/bash

ZIP_PATH='/home/lucxf/202411061643.tar.gz'
VOLUMES_PATH='/volums/wordpress-traefik-kuma'
COMPOSE_PATH='home/lucxf/DockerComposeWebpage/estructura/mycompose-wordpress-traefik-kuma-server.yml'


# # Instalaremos Webmin
# chmod +x ./tools/webmin.sh
# sudo ./tools/webmin.sh

# # Creamos la zona de DNS
# chmod +x ./tools/bindDNS.sh
# sudo ./tools/bindDNS.sh

# # Instalamos Docker y docker compose
# chmod +x ./tools/docker.sh
# sudo ./tools/docker.sh

# # Crearemos la estructura inicial
# chmod +x ./estructura/config-wordpress-traefik-kuma-server.sh
# sudo ./estructura/config-wordpress-traefik-kuma-server.sh

# Substituyo los volumenes por los del backup
docker compose -f $COMPOSE_PATH down
sudo rm -r $VOLUMES_PATH/*
tar -xzpvf $ZIP_PATH -C $VOLUMES_PATH
docker compose -f $COMPOSE_PATH up -d
