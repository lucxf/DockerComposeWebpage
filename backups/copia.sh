#!/bin/bash

# MAX copias en total
MAX_NUM_BKPS=10
# Donde guardamos los backups
DIR_FINAL_BKP="/test/backups"
# Donde guardamos backups en local
DIR_LOCAL_BKP="/etc/backups"
# Directorio donde están los volúmenes
DIR_ORIGIONAL="/volums/wordpress-traefik-kuma"
# Path del fichero docker-compose
DCOMPOSE_PATH="/home/sds/estructura/mycompose-wordpress-traefik-kuma-server.yml"
# IP de la máquina de backups
IP=100.115.56.56
# Archivo de log
LOGFILE="/var/log/backup_script.log"

log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    # Detener la ejecución del script
    exit 1
}

# Comenzamos el backup
echo -e "\033[34mComenzando copiado de seguridad...\033[0m"

# Borramos los contenedores
echo -e "\033[34mDeteniendo contenedores...\033[0m"
if ! docker compose -f $DCOMPOSE_PATH down; then
    log_error "Error al detener los contenedores."
fi

# Creamos el directorio local para los backups
echo -e "\033[34mCreando directorio de backup...\033[0m"
if ! mkdir -p $DIR_LOCAL_BKP; then
    log_error "No se pudo crear el directorio de backup local."
fi

# Creamos el archivo comprimido del backup
echo -e "\033[34mCreando archivo comprimido del backup...\033[0m"
date=$(date +"%Y%m%d%H%M")
if ! tar -czpvf $DIR_LOCAL_BKP/$date.tar.gz -C $DIR_ORIGIONAL .; then
    log_error "Error al crear el archivo comprimido."
fi

# Verificamos la conectividad con la máquina de backups
echo -e "\033[34mComprobando conectividad con la máquina de backups...\033[0m"
if ! ping -c 10 $IP; then
    log_error "Error al conectar con la máquina de backups."
fi

# Movemos el archivo comprimido al directorio final de backups
echo -e "\033[34mMoviendo el backup a la ubicación final...\033[0m"
if ! mv $DIR_LOCAL_BKP/$date.tar.gz $DIR_FINAL_BKP; then
    log_error "Error al mover el archivo de backup."
fi

# Levantamos los contenedores de nuevo
echo -e "\033[34mLevantando los contenedores...\033[0m"
if ! docker compose -f $DCOMPOSE_PATH up -d; then
    log_error "Error al levantar los contenedores."
fi

# Mensaje final de éxito
echo -e "\033[32mCopia de seguridad completada exitosamente.\033[0m"

exit 0