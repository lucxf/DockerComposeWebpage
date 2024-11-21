#!/bin/bash

DIR_TEMP="/etc/temp_volumes"
DOMAIN_PATH="/etc/bind/prueba.local.loc"

rm -r $DOMAIN_PATH

chmod +x ./BORRAR/borrar_docker.sh
sudo ./BORRAR/borrar_docker.sh
chmod +x ./BORRAR/borrar_webmin.sh
sudo ./BORRAR/borrar_webmin.sh
