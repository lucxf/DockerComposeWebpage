#!/bin/bash

# MAX copias en total
MAX_NUM_BKPS=5
# Donde guardamos los backups
DIR_FINAL_BKP="/test/backups"
# Donde guardamos backups en local
DIR_LOCAL_BKP="/etc/backups"
# Directorio donde están los volúmenes
DIR_ORIGINAL="/volums/wordpress-traefik-kuma"
# Path del fichero docker-compose
DCOMPOSE_PATH="./estructura/mycompose-wordpress-traefik-kuma-server.yml"
# IP de la máquina de backups
IP=100.115.56.56
# Archivo de log
LOGFILE="/var/log/Project/backup.log"

MAIL_PATH="./mail/send_mail.py"

log_error() {
    # Registrar el error en el archivo de log
    # error_message="$(date) - ERROR: $1"
    # echo "$error_message" | tee -a "$LOGFILE"
    echo $(date) - ERROR: $1 | tee -a $LOGFILE
    error_message=$(cat $LOGFILE)
    
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    
    # Levantamos los contenedores de nuevo
    echo -e "\033[34mLevantando los contenedores...\033[0m"
    docker compose -f "$DCOMPOSE_PATH" up -d
    
    # Enviar el correo de error
    send_mail "Failed" "$error_message"

    # Detener la ejecución del script
    exit 1
}

send_mail() {
    echo "enviando correo..."
    # apt install python3.12-venv -y
    # Instalar dependencias y crear un entorno virtual si es necesario (evitar hacerlo cada vez)
    if [[ ! -d "myenv" ]]; then
        python3 -m venv myenv
    fi

    source myenv/bin/activate

    if [[ ! $(pip show python-dotenv) ]]; then
        pip install python-dotenv
    fi

    if [[ $1 == "Failed" ]]; then
        subject="⚠️🟥 Copia de seguridad fallida 🟥⚠️"
        body="La copia de seguridad ha fallado. Detalles: $2"
    else
        subject="🟩 Copia de seguridad exitosa 🟩"
        body="La copia de seguridad ha sido realizada con exito. Detalles: $(date)"
    fi

    # Ejecutar script Python para enviar el correo
    python3 $MAIL_PATH "$subject" "$body"

    # Desactivar el entorno virtual
    deactivate
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
if ! tar -czpvf $DIR_LOCAL_BKP/$date.tar.gz -C $DIR_ORIGINAL .; then
    log_error "Error al crear el archivo comprimido."
fi

# Verificamos la conectividad con la máquina de backups
echo -e "\033[34mComprobando conectividad con la máquina de backups...\033[0m"
if ! ping -c 10 $IP; then
    log_error "Error al conectar con la máquina de backups."
fi

# Comprobamos si hay archivos en el directorio de origen
echo -e "\033[34mComprobando si hay copias de seguridad en local...\033[0m"
if [ "$(ls -A $DIR_LOCAL_BKP)" ]; then
    echo -e "\033[34mArchivos encontrados, moviendo a $DIR_FINAL_BKP...\033[0m"
    if ! mv $DIR_LOCAL_BKP/* $DIR_FINAL_BKP; then
        log_error "Error al mover los archivos del directorio de origen a $DIR_FINAL_BKP."
    fi
else
    echo -e "\033[33mNo se encontraron copias de seguridad en local .\033[0m"
fi

# Levantamos los contenedores de nuevo
echo -e "\033[34mLevantando los contenedores...\033[0m"
if ! docker compose -f $DCOMPOSE_PATH up -d; then
    log_error "Error al levantar los contenedores."
fi

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

# Comprobamos si el número de archivos supera el máximo permitido
if [ ${#backups[@]} -gt $MAX_NUM_BKPS ]; then
    # Calculamos cuántos archivos eliminar
    archivos_a_eliminar=$(( ${#backups[@]} - $MAX_NUM_BKPS ))

    echo -e "\033[33mSe han encontrado más de $MAX_NUM_BKPS copias de seguridad. Eliminando los $archivos_a_eliminar archivos más antiguos...\033[0m"

    # Eliminamos los archivos más antiguos
    for ((i=0; i<archivos_a_eliminar; i++)); do
        archivo_a_eliminar="${backups[$i]}"
        echo -e "\033[31mEliminando archivo: $archivo_a_eliminar\033[0m"
        rm -f "$DIR_FINAL_BKP/$archivo_a_eliminar"
    done
fi


# Mensaje final de éxito
echo -e "\033[32mCopia de seguridad completada exitosamente.\033[0m"

    send_mail "Success" 

exit 0