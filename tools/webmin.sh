#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/webmin_installation.log"

# Función para escribir errores en el log
log_error() {
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    echo "\033[31$(date) - ERROR: $1\033[0m"
}

# Antes de instalar la herramienta, actualizamos los paquetes disponibles en los repositorios
echo "Actualizando los paquetes disponibles en los repositorios..."
if ! sudo apt update -y && sudo apt upgrade -y; then
    log_error "Error al ejecutar 'apt update' o 'apt upgrade'."
fi

# Instalamos las dependencias necesarias
echo "Instalando dependencias necesarias..."
if ! sudo apt install software-properties-common apt-transport-https -y; then
    log_error "Error al ejecutar 'apt install' para dependencias."
fi

# Habilitamos el repositorio de Webmin
echo "Añadiendo la clave GPG del repositorio de Webmin..."
if ! sudo wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -; then
    log_error "Error al añadir la clave GPG de Webmin."
fi

# Agregamos el repositorio de Webmin manualmente
echo "Añadiendo el repositorio de Webmin..."
if ! sudo add-apt-repository "deb [arch=amd64] http://download.webmin.com/download/repository sarge contrib"; then
    log_error "Error al agregar el repositorio de Webmin."
fi

# Instalamos Webmin
echo "Instalando Webmin..."
if ! sudo apt install webmin -y; then
    log_error "Error al instalar Webmin."
fi

# Comprobamos el estado de Webmin
echo "Comprobando el estado de Webmin..."
if ! sudo systemctl status webmin; then
    log_error "Error al comprobar el estado de Webmin."
fi

# Comprobamos la versión de Webmin
echo "Comprobando la versión de Webmin..."
if ! dpkg -l | grep webmin; then
    log_error "Error al verificar la versión de Webmin."
fi

# Abrimos el firewall en el puerto que usaremos para Webmin
echo "Abriendo el puerto 10000/tcp en el firewall..."
if ! sudo ufw allow 10000/tcp; then
    log_error "Error al abrir el puerto 10000/tcp en el firewall."
fi

# Actualizamos el firewall
echo "Habilitando y recargando el firewall..."
if ! sudo ufw enable; then
    log_error "Error al habilitar el firewall."
fi

if ! sudo ufw reload; then
    log_error "Error al recargar el firewall."
fi

# Verificamos el estado del firewall
echo "Verificando el estado del firewall..."
if ! sudo ufw status; then
    log_error "Error al verificar el estado del firewall."
fi

echo -e "\033[31mWebmin instalado correctamente\033[0m"
