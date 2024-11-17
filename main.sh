#!/bin/bash

# Definir las rutas
ZIP_PATH='../202411111707.tar.gz'
VOLUMES_PATH='/volums/wordpress-traefik-kuma'
COMPOSE_PATH='./estructura/mycompose-wordpress-traefik-kuma-server.yml'

DIR_FINAL_BKP="/test/backups"
# Donde guardamos backups en local
DIR_LOCAL_BKP="/etc/backups"
# Directorio temporal por si falla
DIR_TEMP="/etc/temp_volumes"

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

# Comprobar si el usuario es root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[31mERROR: Este script debe ejecutarse como usuario root.\033[0m"
    exit 1
fi

# Creamos los directorios necesarios
mkdir -p /var/log/Project
mkdir -p $DIR_FINAL_BKP
mkdir -p $DIR_LOCAL_BKP
mkdir -p $DIR_TEMP

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

log_info "Iniciando proceso de creación..."
chmod +x ./estructura/config-wordpress-traefik-kuma-server.sh
if ! ./estructura/config-wordpress-traefik-kuma-server.sh; then
    log_error "Error al iniciar el proceso de creación."
fi

echo -e "\033[32mEstructura creada correctamente\033[0m"

# Creare el tunel VPN y luego hago un restore a partir de una copia

log_info "Iniciando proceso de restauración..."
chmod +x ./backups/restore.sh
if ! ./backups/restore.sh; then
    log_error "Error al iniciar el proceso de restauración."
fi

echo -e "\033[32mRestauración realizada correctamente\033[0m"
