#!/bin/bash

# Archivo de log
LOGFILE="/var/log/tailscale_script.log"

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

# Validación de la respuesta del usuario para continuar
echo -e "\033[32m¿Está todo correcto después de agregar los repositorios de Tailscale? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "El repositorio de Tailscale no se agregó correctamente."
fi

# Instalar Tailscale
echo -e "\033[34mInstalando Tailscale...\033[0m"
if ! sudo apt-get update; then
    log_error "Error al ejecutar 'apt-get update'."
fi

if ! sudo apt-get install tailscale -y; then
    log_error "Error al instalar Tailscale."
fi

# Validación de la respuesta del usuario para continuar
echo -e "\033[32m¿Está todo correcto después de instalar Tailscale? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "La instalación de Tailscale no se completó correctamente."
fi

# Iniciar Tailscale
echo -e "\033[34mIniciando Tailscale...\033[0m"
if ! sudo tailscale up; then
    log_error "Error al iniciar Tailscale."
fi

# Validación de la respuesta del usuario para continuar
echo -e "\033[32m¿Está Tailscale funcionando correctamente? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "Tailscale no se inició correctamente."
fi

# Obtener la IP de Tailscale
echo -e "\033[34mObteniendo IP...\033[0m"
if ! tailscale ip -4; then
    log_error "Error al obtener la IP de Tailscale."
fi

# Validación de la respuesta del usuario para continuar
echo -e "\033[32m¿La IP de Tailscale se obtuvo correctamente? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "No se pudo obtener la IP de Tailscale."
fi

# Crear directorio para montar el NAS
echo -e "\033[34mCreando directorio...\033[0m"
if ! mkdir -p /mnt/nas; then
    log_error "Error al crear el directorio '/mnt/nas'."
fi

# Validación de la respuesta del usuario para continuar
echo -e "\033[32m¿El directorio /mnt/nas fue creado correctamente? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "No se pudo crear el directorio '/mnt/nas'."
fi

# Instalar sshfs
echo -e "\033[34mInstalando sshfs...\033[0m"
if ! sudo apt install sshfs -y; then
    log_error "Error al instalar sshfs."
fi

# Validación de la respuesta del usuario para continuar
echo -e "\033[32m¿Se instaló sshfs correctamente? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "No se pudo instalar sshfs."
fi

# Configurar sshfs
echo -e "\033[34mConfigurando sshfs...\033[0m"
if ! sudo sshfs g4@100.115.56.56:/sda /mnt/nas; then
    log_error "Error al montar el directorio remoto con sshfs."
fi

# Validación de la respuesta del usuario para continuar
echo -e "\033[32m¿El directorio se montó correctamente? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "No se pudo montar el directorio con sshfs."
fi

# Comprobar la configuración
echo -e "\033[34mComprobando configuración...\033[0m"
if ! df -h; then
    log_error "Error al comprobar los sistemas de archivos."
fi

# Validación final
echo -e "\033[32m¿Aparece la carpeta mapeada correctamente? (si/no)\033[0m"
read confirmacion
if [[ ! "$confirmacion" =~ ^[sS][iI]$ ]]; then
    log_error "El directorio mapeado no aparece correctamente."
fi

echo -e "\033[32m¡Todo ha funcionado correctamente!\033[0m"
