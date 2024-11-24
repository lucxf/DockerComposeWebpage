#!/bin/bash

# Donde guardamos los backups
DIR_FINAL_BKP="/mnt/nas/backups"
# Donde guardamos backups en local
DIR_LOCAL_BKP="/etc/backups"
# Directorio de los volumenes originales
DIR_ORIGINAL="/volums/wordpress-traefik-kuma"
# Directorio temporal por si falla
DIR_TEMP="/etc/temp_volumes"
# Path del fichero docker-compose
DCOMPOSE_PATH="./estructura/mycompose-wordpress-traefik-kuma-server.yml"
# IP de la máquina de backups
IP=100.115.56.56
# Archivo de log
LOGFILE="/var/log/Project/restore.log"

log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    # Detener la ejecución del script
    exit 1
}

# Comprobar si el usuario es root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\033[31mERROR: Este script debe ejecutarse como usuario root.\033[0m"
    exit 1
fi

# Comenzamos el backup
echo -e "\033[34mComenzando restauración...\033[0m"

# Verificamos la conectividad con la máquina de backups
echo -e "\033[34mComprobando conectividad con la máquina de backups...\033[0m"
if ! ping -c 10 $IP; then
    log_error "Error al conectar con la máquina de backups."
fi

# Borramos los contenedores
echo -e "\033[34mDeteniendo contenedores...\033[0m"
if ! docker compose -f $DCOMPOSE_PATH down; then
    log_error "Error al detener los contenedores."
fi

# Directorio temporal donde moveremos los volúmenes actuales por si falla el restore
echo -e "\033[34mMoviendo volúmenes actuales a la carpeta temporal...\033[0m"
if ! mv $DIR_ORIGINAL/* $DIR_TEMP; then
    log_error "Error al mover los volúmenes actuales de $DIR_ORIGINAL a $DIR_TEMP."
fi

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

# # Validar que la posición esté dentro de los límites del array
# if [ "$select_backup" -ge 0 ] && [ "$select_backup" -lt "${#backups[@]}" ]; then
#     # Acceder al archivo en la posición $select_backup
#     archivo_seleccionado="${backups[$select_backup]}"
#     echo -e "\033[34mHas seleccionado la copia de seguridad número\033[0m \033[35m$select_backup\033[0m $archivo_seleccionado \033[34m para restaurar.\033[0m"
# else
#     echo -e "\033[31mError: La posición seleccionada está fuera de rango.\033[0m"
#     exit 1
# fi

total_backups=$(( ${#backups[@]} - 1 ))
 
# Solicitar la selección de copia de seguridad
echo "Por favor, selecciona una copia de seguridad (0 - $total_backups):"
read -r select_backup

# Bucle hasta que se seleccione una copia de seguridad válida
until [ "$select_backup" -ge 0 ] && [ "$select_backup" -lt "${#backups[@]}" ]; do
    # Si la entrada no es válida, mostrar error y pedir de nuevo
    echo "Error: La posición seleccionada está fuera de rango. Por favor, selecciona un número válido."
    echo "Por favor, selecciona una copia de seguridad (0 - $total_backups):"
    read -r select_backup
done

# Cuando la entrada es válida, se selecciona el archivo
archivo_seleccionado="${backups[$select_backup]}"
echo -e "\033[34mHas seleccionado la copia de seguridad número\033[0m \033[35m$select_backup\033[0m $archivo_seleccionado \033[34m para restaurar.\033[0m"

# Deszipear los backups
echo -e "\033[34mExtrayendo copia de seguridad...\033[0m"
if ! tar -xzpvf $DIR_FINAL_BKP/$archivo_seleccionado -C $DIR_ORIGINAL; then
    log_error "Error al extraer la copia de seguridad."
fi

# Levanta contenedores
echo -e "\033[34mCreando contenedores...\033[0m"
if ! docker compose -f $DCOMPOSE_PATH up -d; then
    log_error "Error al crear los contenedores."
fi

# Pedimos confirmación al usuario
echo -e "\033[32m¿Está todo correcto? (sí/no)\033[0m"
read confirmacion

# Validar la respuesta del usuario
if [[ "$confirmacion" =~ ^[sS][iI]$ ]]; then
    # Si la respuesta es sí, finalizar el script
    echo -e "\033[34mRestauración completada correctamente. Finalizando...\033[0m"
    echo -e "\033[34mEliminando archivos temporales en $DIR_TEMP...\033[0m"
    if ! rm -r $DIR_TEMP/*; then
        log_error "Error al eliminar los archivos de $DIR_TEMP."
    fi
    exit 0
else
    # Si la respuesta es no, restaurar el estado previo
    echo -e "\033[32mRestaurando el estado previo al restore...\033[0m"
    
    # Suponiendo que ha fallado el restore, vuelve al estado inicial

    echo -e "\033[34mRestaurando contenedores...\033[0m"
    if ! docker compose -f $DCOMPOSE_PATH down; then
        log_error "Error al restaurar los contenedores."
    fi
    echo -e "\033[34mBorrando estado actual...\033[0m"
    if ! rm -r $DIR_ORIGINAL/*; then
        log_error "Error al eliminar los archivos de $DIR_ORIGINAL."
    fi
    # Directorio temporal donde moveremos los volúmenes actuales por si falla el restore
    echo -e "\033[34mMoviendo volúmenes del directorio temporal a el original...\033[0m"
    if ! mv $DIR_TEMP/* $DIR_ORIGINAL; then
        log_error "Error al mover los volúmenes actuales de $DIR_TEMP a $DIR_ORIGINAL."
    fi

    # Levantamos los contenedores nuevamente
    echo -e "\033[34mRestaurando contenedores...\033[0m"
    if ! docker compose -f $DCOMPOSE_PATH up -d; then
        log_error "Error al restaurar los contenedores."
    fi

    echo -e "\033[34mEstado restaurado correctamente.\033[0m"
    exit 0
fi
