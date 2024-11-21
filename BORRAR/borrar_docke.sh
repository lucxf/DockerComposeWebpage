#!/bin/bash

# Detener el servicio de Docker
sudo systemctl stop docker

# Eliminar Docker y sus componentes
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Limpiar archivos de configuración y datos
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /etc/docker
sudo rm -rf /etc/apt/sources.list.d/docker.list
sudo rm -rf /etc/apt/keyrings/docker.asc

# Limpiar el sistema de paquetes obsoletos y dependencias
sudo apt-get autoremove -y
sudo apt-get autoclean

# Actualizar la lista de paquetes
sudo apt-get update -y

echo "Docker y sus componentes han sido eliminados correctamente."
