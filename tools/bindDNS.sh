#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/bind_installation.log"

# Función para escribir errores en el log
log_error() {
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
}

# Comenzamos la instalación de BIND DNS
echo "Instalando BIND DNS..."
if ! sudo apt update -y && sudo apt upgrade -y; then
    log_error "Error al ejecutar 'apt update' o 'apt upgrade'."
    exit 1
fi

if ! sudo apt install -y bind9 bind9utils bind9-doc; then
    log_error "Error al instalar BIND DNS (bind9)."
    exit 1
fi

# Verificamos que el servicio de BIND esté funcionando
echo "Comprobando el estado de BIND..."
if ! sudo systemctl status bind9; then
    log_error "BIND DNS no está corriendo correctamente después de la instalación."
    exit 1
fi

# Configuración de la zona DNS

# Creamos el archivo de zona para 'prueba.local.loc'
ZONE_FILE="/etc/bind/db.prueba.local.loc"
echo "Creando el archivo de zona DNS para prueba.local.loc..."

cat <<EOF | sudo tee $ZONE_FILE > /dev/null
\$TTL 38400  ; Temps (seg) de vida per defecte (TIME TO LIVE GLOBAL, TEMPS QUE ES GUARDEN EN CACHE ELS REGISTRES)
prueba.local.loc. IN SOA ns1.prueba.local.loc. lucxf.prueba.local.loc. (
    2010120416 ; Serial
    10800      ; Refresh
    3600       ; Retry
    604800     ; Expire
    38400      ; Minimum TTL
)

; DNS Servers
prueba.local.loc. IN NS ns1.prueba.local.loc.

; Direcciones IP
prueba.local.loc. IN A 192.168.0.155
ns1.prueba.local.loc. IN A 192.168.0.155
www.prueba.local.loc. IN A 192.168.0.155
kuma.prueba.local.loc. IN A 192.168.0.155
traefic.prueba.local.loc. IN A 192.168.0.155
nextcloud.prueba.local.loc. IN A 192.168.0.155
EOF

if [ $? -ne 0 ]; then
    log_error "Error al crear el archivo de zona '$ZONE_FILE'."
    exit 1
fi

# Configuración de BIND para que reconozca la nueva zona

# Creamos el archivo de opciones de BIND: named.conf.options
echo "Configurando las opciones de BIND..."
cat <<EOF | sudo tee /etc/bind/named.conf.options > /dev/null
options {
    directory "/var/cache/bind";

    // Si hay un firewall entre tu servidor y los servidores de nombres que deseas utilizar,
    // es posible que debas configurar el firewall para permitir múltiples puertos.
    // Más detalles en: http://www.kb.cert.org/vuls/id/800113

    // Si tu ISP te ha proporcionado uno o más servidores DNS estables,
    // puedes usar estos servidores como forwarders.
    forwarders {
        1.1.1.1;
        8.8.8.8;
    };

    // Si BIND muestra mensajes de error sobre la clave raíz expirando,
    // necesitarás actualizar tus claves. Más detalles en:
    // https://www.isc.org/bind-keys
    dnssec-validation auto;

    listen-on-v6 { any; };
};
EOF

if [ $? -ne 0 ]; then
    log_error "Error al crear el archivo de opciones de BIND '/etc/bind/named.conf.options'."
    exit 1
fi

# Añadimos la configuración de la zona en named.conf.local
echo "Configurando la zona en named.conf.local..."
ZONE_CONF="/etc/bind/named.conf.local"

if ! sudo bash -c "echo 'zone \"prueba.local.loc\" { type master; file \"/etc/bind/db.prueba.local.loc\"; };' >> $ZONE_CONF"; then
    log_error "Error al añadir la configuración de la zona en '$ZONE_CONF'."
    exit 1
fi

# Recargamos BIND para que cargue la nueva configuración
echo "Recargando BIND..."
if ! sudo systemctl reload bind9; then
    log_error "Error al recargar BIND después de añadir la zona."
    exit 1
fi

# Comprobamos si BIND está funcionando correctamente
echo "Verificando la zona DNS..."
if ! sudo named-checkzone prueba.local.loc /etc/bind/db.prueba.local.loc; then
    log_error "Error al comprobar la zona DNS con 'named-checkzone'."
    exit 1
fi

# Habilitamos el firewall para permitir tráfico en el puerto 53 (DNS)
echo "Configurando el firewall para permitir tráfico DNS..."
if ! sudo ufw allow 53/tcp && sudo ufw allow 53/udp; then
    log_error "Error al permitir el tráfico DNS en el firewall."
    exit 1
fi

# Activamos y recargamos el firewall
echo "Habilitando y recargando el firewall..."
if ! sudo ufw enable; then
    log_error "Error al habilitar el firewall."
    exit 1
fi

if ! sudo ufw reload; then
    log_error "Error al recargar el firewall."
    exit 1
fi

# Verificamos el estado del firewall
echo "Verificando el estado del firewall..."
if ! sudo ufw status; then
    log_error "Error al verificar el estado del firewall."
    exit 1
fi

echo -e "\033[31mInstalación y configuración completada con éxito.\033[0m"

# Fin del script
exit 0
