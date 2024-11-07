#!/bin/bash

# Archivo de log
LOGFILE="/var/log/Project/bind_installation.log"

# Función para escribir errores en el log y mostrar el mensaje en rojo
log_error() {
    # Registrar el error en el archivo de log
    echo "$(date) - ERROR: $1" | tee -a $LOGFILE
    # Mostrar el error en la terminal en rojo
    echo -e "\033[31m$(date) - ERROR: $1\033[0m"
    # Detener la ejecución del script
    exit 1
}

# Comenzamos la instalación de BIND DNS
echo -e "\033[34mInstalando BIND DNS...\033[0m"
if ! sudo apt update -y && sudo apt upgrade -y; then
    log_error "Error al ejecutar 'apt update' o 'apt upgrade'."
fi

if ! sudo apt install -y bind9 bind9utils bind9-doc; then
    log_error "Error al instalar BIND DNS (bind9)."
fi

# Verificamos que el servicio de BIND esté funcionando
# echo "Comprobando el estado de BIND..."
# if ! sudo systemctl status bind9; then
#     log_error "BIND DNS no está corriendo correctamente después de la instalación."
#     exit 1
# fi

# Configuración de la zona DNS

# Creamos el archivo de zona para 'prueba.local.loc'
ZONE_FILE="/etc/bind/db.prueba.local.loc"
echo -e "\033[34mCreando el archivo de zona DNS para prueba.local.loc...\033[0m"

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
fi

# Configuración de BIND para que reconozca la nueva zona

# Creamos el archivo de opciones de BIND: named.conf.options
echo -e "\033[34mConfigurando las opciones de BIND...\033[0m"
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
fi

# Añadimos la configuración de la zona en named.conf.local
echo -e "\033[34mConfigurando la zona en named.conf.local...\033[0m"
ZONE_CONF="/etc/bind/named.conf.local"

if ! sudo bash -c "echo 'zone \"prueba.local.loc\" { type master; file \"/etc/bind/db.prueba.local.loc\"; };' >> $ZONE_CONF"; then
    log_error "Error al añadir la configuración de la zona en '$ZONE_CONF'."
fi

# Recargamos BIND para que cargue la nueva configuración
echo -e "\033[34mRecargando BIND...\033[0m"
if ! sudo systemctl reload bind9; then
    log_error "Error al recargar BIND después de añadir la zona."
fi

# Comprobamos si BIND está funcionando correctamente
echo -e "\033[34mVerificando la zona DNS...\033[0m"
if ! sudo named-checkzone prueba.local.loc /etc/bind/db.prueba.local.loc; then
    log_error "Error al comprobar la zona DNS con 'named-checkzone'."
fi

# Habilitamos el firewall para permitir tráfico en el puerto 53 (DNS)
echo -e "\033[34mConfigurando el firewall para permitir tráfico DNS...\033[0m"
if ! sudo ufw allow 53/tcp && sudo ufw allow 53/udp; then
    log_error "Error al permitir el tráfico DNS en el firewall."
fi

# Activamos y recargamos el firewall
echo -e "\033[34mHabilitando y recargando el firewall...\033[0m"
if ! sudo ufw enable; then
    log_error "Error al habilitar el firewall."
fi

if ! sudo ufw reload; then
    log_error "Error al recargar el firewall."
fi

# Verificamos el estado del firewall
echo -e "\033[34mVerificando el estado del firewall...\033[0m"
if ! sudo ufw status; then
    log_error "Error al verificar el estado del firewall."
fi

echo -e "\033[32mInstalación y configuración de BIND DNS completada con éxito.\033[0m"

# Fin del script
exit 0
