#!/bin/bash/

# Donde guardamos los backups
DIR_FINAL_BKP="/test/backups"
# Donde guardamos backups en local
DIR_LOCAL_BKP="/etc/backups"
# Directorio de los volumenes originales
DIR_ORIGIONAL="/volums/wordpress-traefik-kuma"
# Directorio temporal por si falla
DIR_TEMP="/etc/temp_volumes"
# Path del fichero docker-compose
DCOMPOSE_PATH="../estructura/mycompose-wordpress-traefik-kuma-server.yml"
# IP de la máquina de backups
IP=100.115.56.56
# Archivo de log
LOGFILE="/var/log/restore.log"

log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    # Detener la ejecución del script
    exit 1
}

# Comenzamos el backup
echo -e "\033[34mComenzando restauración...\033[0m"

# Borramos los contenedores
echo -e "\033[34mDeteniendo contenedores...\033[0m"
if ! docker compose -f $DCOMPOSE_PATH down; then
    log_error "Error al detener los contenedores."
fi

# Movemos a una carpeta temporal los volumenes actuales por si falla el restore
# mv $DIR_ORIGIONAL/* $DIR_TEMP

# Listo Backups
# Obtenemos los archivos del directorio ordenados alfabéticamente
echo -e "\033[34mObteniendo archivos del directorio y ordenándolos...\033[0m"
backups=($(ls -v $DIR_FINAL_BKP))

# Comprobamos si el array está vacío
if [ ${#backups[@]} -eq 0 ]; then
    # Si no se encuentran archivos, mostramos un mensaje informando
    echo -e "\033[31mNo se han encontrado archivos en $DIR_FINAL_BKP\033[0m"
else
    # Si se encuentran archivos, los mostramos en rosa
    echo -e "\033[35mArchivos encontrados:\033[0m"
    for i in "${!backups[@]}"; do
        echo -e "\033[35m[$i]\033[0m ${backups[$i]}"
    done
fi

# Pedir al usuario que ingrese el número de la copia de seguridad desde la cual restaurar
echo -e "\033[32mA partir de que copia quieres restaurar? (Ingresa un número)\033[0m"
read select_backup

# Comprobar si la entrada es un número válido
if ! [[ "$select_backup" =~ ^[0-9]+$ ]]; then
    echo -e "\033[31mError: La entrada no es un número válido.\033[0m"
    exit 1
fi

# Mostrar la opción seleccionada
echo -e "\033[34mHas seleccionado la copia de seguridad número $select_backup para restaurar.\033[0m"

# Deszipeo los volumenes del backup