#!/bin/bash

# Definir las rutas
ZIP_PATH='../202411111707.tar.gz'
VOLUMES_PATH='/volums/wordpress-traefik-kuma'
COMPOSE_PATH='./estructura/mycompose-wordpress-traefik-kuma-server.yml'

# Definir archivo de log
LOGFILE="/var/log/Project/installation.log"

# Función para registrar mensajes en el log y mostrar los errores en pantalla
log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    # Detener la ejecución del script
    exit 1
}

log_info() {
    # Registrar el mensaje informativo en el archivo de log
    echo "$(date) - INFO: $1" | tee -a $LOGFILE
    # Mostrar el mensaje en la terminal en azul
    echo -e "\033[34m$(date) - INFO: $1\033[0m"
}


mkdir -p /var/log/Project

sudo ufw allow 22/tcp

# Empezamos la instalación de Webmin
log_info "Instalando Webmin..."
chmod +x ./tools/webmin.sh
if ! sudo ./tools/webmin.sh; then
    log_error "Error al instalar Webmin."
fi

# Creamos la zona de DNS
log_info "Creando la zona de DNS..."
chmod +x ./tools/bindDNS.sh
if ! sudo ./tools/bindDNS.sh; then
    log_error "Error al crear la zona de DNS."
fi

sudo ufw disable

# Instalamos Docker y Docker Compose
log_info "Instalando Docker y Docker Compose..."
chmod +x ./tools/docker.sh
if ! sudo ./tools/docker.sh; then
    log_error "Error al instalar Docker y Docker Compose."
fi


log_info "Comprovando resoluciónbn de DNS..."
if ! nslookup $DOMAIN; then
    log_error "La zona de DNS no resuleve correctamente"
fi

