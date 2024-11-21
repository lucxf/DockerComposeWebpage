#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/tailscale_script.log"
# Directorio de backups
DIR_FINAL_BKP="/mnt/nas"
IP_BKP="100.115.56.56"
BKP_MCHN_USER="g4"
MACHINE_BKP_DIR="/sda"

# Función para escribir errores en el log y mostrar el mensaje en rojo
log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    # Detener la ejecución del script
    exit 1
}

# Agregar repositorios de Tailscale
echo -e "\033[34mAgregando repositorios de Tailscale...\033[0m"
if ! curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null; then
    log_error "Error al agregar la clave GPG del repositorio de Tailscale."
fi

if ! curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list; then
    log_error "Error al agregar el archivo de lista de repositorio de Tailscale."
fi


# Instalar Tailscale
echo -e "\033[34mInstalando Tailscale...\033[0m"
if ! sudo apt-get update; then
    log_error "Error al ejecutar 'apt-get update'."
fi

if ! sudo apt-get install tailscale -y; then
    log_error "Error al instalar Tailscale."
fi

# Iniciar Tailscale
echo -e "\033[34mIniciando Tailscale...\033[0m"

echo -e "\033[32mConfigura Manulamente Tailscale porfavor...\033[0m"
if ! sudo tailscale up; then
    log_error "Error al iniciar Tailscale."
fi

# Validación de la respuesta del usuario para continuar
echo -e "\033[32m¿Has configurado manualmente Tailscale? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "Tailscale no se inició correctamente."
fi

# Obtener la IP de Tailscale
echo -e "\033[34mObteniendo IP...\033[0m"
if ! tailscale ip -4; then
    log_error "Error al obtener la IP de Tailscale."
fi

# Crear directorio para montar el NAS
echo -e "\033[34mCreando directorio...\033[0m"
if ! mkdir -p $DIR_FINAL_BKP; then
    log_error "Error al crear el directorio '$DIR_FINAL_BKP'."
fi

# Instalar sshfs
echo -e "\033[34mInstalando sshfs...\033[0m"
if ! sudo apt install sshfs -y; then
    log_error "Error al instalar sshfs."
fi

# Configurar sshfs
echo -e "\033[34mConfigurando sshfs...\033[0m"
if ! sudo sshfs $BKP_MCHN_USER@$IP_BKP:$MACHINE_BKP_DIR $DIR_FINAL_BKP; then
    log_error "Error al montar el directorio remoto con sshfs."
fi

# Comprobar la configuración
echo -e "\033[34mComprobando configuración...\033[0m"
if ! ls -l $DIR_FINAL_BKP; then
    log_error "Error al comprobar los sistemas de archivos."
fi

# Validación final
echo -e "\033[32m¿Aparece la carpeta mapeada correctamente? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "El directorio mapeado no aparece correctamente."
fi

echo -e "\033[32m¡Tunel establecido correctamente!\033[0m"
