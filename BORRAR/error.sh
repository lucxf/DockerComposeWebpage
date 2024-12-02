#!/bin/bash

DIR_TEMP="/etc/temp_volumes"
DOMAIN_PATH="/etc/bind/millionx.sdslab.cat"

rm -r $DOMAIN_PATH

chmod +x ./BORRAR/borrar_docker.sh
sudo ./BORRAR/borrar_docker.sh
chmod +x ./BORRAR/borrar_webmin.sh
sudo ./BORRAR/borrar_webmin.sh
