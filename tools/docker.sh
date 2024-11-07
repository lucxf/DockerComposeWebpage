#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/docker_installation.log"

# Función para escribir errores en el log
log_error() {
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
}

# Eliminar archivos de paquetes .deb que ya no se pueden descargar
echo "Limpiando paquetes obsoletos..."
if ! sudo apt-get autoclean -y; then
    log_error "Error al ejecutar 'apt-get autoclean'."
fi

# Eliminar versiones antiguas de Docker o paquetes conflictivos
echo "Eliminando versiones antiguas de Docker..."
if ! sudo apt-get remove -y docker docker-engine docker.io containerd runc; then
    log_error "Error al ejecutar 'apt-get remove' para Docker."
fi

# Limpiar cualquier paquete obsoleto o dependencias innecesarias
echo "Limpiando dependencias obsoletas..."
if ! sudo apt-get autoremove -y; then
    log_error "Error al ejecutar 'apt-get autoremove'."
fi

# Actualizar el sistema
echo "Actualizando el sistema..."
if ! sudo apt update -y && sudo apt upgrade -y; then
    log_error "Error al ejecutar 'apt update' o 'apt upgrade'."
fi

# Instalar certificados y herramienta de transferencia de datos
echo "Instalando certificados y herramientas de transferencia de datos..."
if ! sudo apt-get install -y ca-certificates curl; then
    log_error "Error al ejecutar 'apt-get install' para ca-certificates o curl."
fi

# Crear un directorio seguro para llaves de repositorios APT
echo "Creando directorio para llaves de repositorios..."
if ! sudo install -m 0755 -d /etc/apt/keyrings; then
    log_error "Error al crear el directorio '/etc/apt/keyrings'."
fi

# Descargar y guardar la clave GPG de Docker
echo "Descargando la clave GPG de Docker..."
if ! sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; then
    log_error "Error al descargar la clave GPG de Docker."
fi

# Otorgar permisos de lectura a todos los usuarios para la clave GPG de Docker
echo "Asignando permisos a la clave GPG de Docker..."
if ! sudo chmod a+r /etc/apt/keyrings/docker.asc; then
    log_error "Error al cambiar los permisos de '/etc/apt/keyrings/docker.asc'."
fi

# Agregar el repositorio de Docker a las fuentes de Apt
echo "Agregando el repositorio de Docker a las fuentes de APT..."
if ! echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
    log_error "Error al agregar el repositorio Docker en '/etc/apt/sources.list.d/docker.list'."
fi

# Actualizar lista de paquetes después de agregar el repositorio Docker
echo "Actualizando la lista de paquetes después de agregar Docker..."
if ! sudo apt-get update -y; then
    log_error "Error al ejecutar 'apt-get update' después de agregar el repositorio Docker."
fi

# Instalar Docker Engine, CLI, Containerd, Buildx y Compose plugins
echo "Instalando Docker..."
if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    log_error "Error al ejecutar 'apt-get install' para Docker."
fi

# Verificar que Docker esté correctamente instalado
echo "Verificando la instalación de Docker..."
if ! sudo docker --version; then
    log_error "Docker no se instaló correctamente o el comando 'docker --version' falló."
else
    echo "Docker se ha instalado correctamente."
fi

echo -e "\033[31mDocker instalado correctamente\033[0m"
