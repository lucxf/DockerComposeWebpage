#!/bin/bash

DIR_TEMP="/etc/temp_volumes"
DOMAIN_PATH="/etc/bind/prueba.local.loc"

rm -r $DOMAIN_PATH

chmod +x ./borrar_docker.sh
sudo ./borrar_docker.sh
chmod +x ./borrar_webmin.sh
sudo ./borrar_webmin.sh
