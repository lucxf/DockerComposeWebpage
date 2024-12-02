#!/bin/bash
#https://github.com/atareao/self-hosted
#https://atareao.es/tutorial/self-hosted/wordpress-en-docker-y-con-redis/
# * Cómo crear una Tienda Online en WordPress y WooCommerce:
#    https://www.youtube.com/watch?v=ZQTBAalJWCU

cd ./estructura

DCOMPOSE_PATH='./mycompose-wordpress-traefik-kuma-server.yml'

apt install apache2-utils
htpasswd -nb admin .123456aA. > users.txt # creació del usuari administrador del panell web 'traefik'

nom_server_fqdn="millionx.sdslab.cat"
nom_server_kuma_fqdn="kuma.millionx.sdslab.cat"
host_name_proxy="traefik.millionx.sdslab.cat"
dir_volum="/volums/wordpress-traefik-kuma"
dir_wp_db="$dir_volum/wp_db"
dir_wp_www="$dir_volum/www_html"
dir_logs_nginx="$dir_volum/logs_nginx"
dir_redis_info="$dir_volum/redis_info"
dir_kuma_info="$dir_volum/kuma_info"
file_traefik_data="$dir_volum/acme.json"

#cp exemple.env .env
echo -e "DIR_WPDB=$dir_wp_db" >.env
echo -e "DIR_WPWWW=$dir_wp_www" >>.env
echo -e "DIR_LOGS_NGINX=$dir_logs_nginx" >>.env
echo -e "DIR_REDIS_INFO=$dir_redis_info" >>.env
echo -e "DIR_KUMA_INFO=$dir_kuma_info" >>.env
echo -e "FILE_TRAEFIK_DATA=$file_traefik_data" >>.env
echo -e "FQDN=$nom_server_fqdn" >>.env
echo -e "HOST_NAME_PROXY=$host_name_proxy" >>.env
echo -e "FQDN_KUMA=$nom_server_kuma_fqdn" >>.env

mysql_root_password=".123456aA."
mysql_user="mysql_user_sds"
mysql_password=".123456aA."
mysql_db="mysql_db_sds"

#cp exemple.wp.env wp.env
echo -e "MYSQL_ROOT_PASSWORD=$mysql_root_password" >wp.env
echo -e "MYSQL_USER=$mysql_user" >>wp.env
echo -e "MYSQL_PASSWORD=$mysql_password" >>wp.env
echo -e "MYSQL_DATABASE=$mysql_db" >>wp.env
echo -e "WORDPRESS_DB_USER=$mysql_user" >>wp.env
echo -e "WORDPRESS_DB_PASSWORD=$mysql_password" >>wp.env
echo -e "WORDPRESS_DB_NAME=$mysql_db" >>wp.env

cp exemle.traefik.yml traefik.yml

docker compose -f $DCOMPOSE_PATH down
#rm -r $file_traefik_data 2>&1 >/dev/null
rm -r $dir_wp_db >/dev/null 2>&1
rm -r $dir_wp_www >/dev/null 2>&1
rm -r $dir_logs_nginx >/dev/null 2>&1
rm -r $dir_redis_info >/dev/null 2>&1
rm -r $dir_kuma_info >/dev/null 2>&1

mkdir -p $dir_volum
touch $file_traefik_data
chmod 600 $file_traefik_data

docker compose -f $DCOMPOSE_PATH build
docker compose -f $DCOMPOSE_PATH up -d

sleep 2
docker compose -f $DCOMPOSE_PATH logs traefik
sleep 2
docker compose -f $DCOMPOSE_PATH logs wp
sleep 2
docker compose -f $DCOMPOSE_PATH logs uptime_kuma


lin1="define('WP_REDIS_HOST', 'wpredis');"
lin2="define('WP_REDIS_PORT', 6379);"
lin3="define('WP_REDIS_TIMEOUT', 1);"
lin4="define('WP_REDIS_READ_TIMEOUT', 1);"
lin5="define('WP_REDIS_DATABASE', 0);"
info_def_redis="\n$lin1\n$lin2\n$lin3\n$lin4\n$lin5\n\n"

# buscar linies amb coincidencies "That.s all. stop editing. Happy publishing" i afegir noves linies al principi de linia amb directives adecuades
temp0=$(sed -r "/That.s all. stop editing. Happy publishing/ s/^/$info_def_redis/" $dir_wp_www/wp-config.php)
# salvar linies al fitxer de configuracio
#echo -e "$temp0"
echo -e "$temp0" >$dir_wp_www/wp-config.php

sleep 3
docker compose -f $DCOMPOSE_PATH restart wpnginx
sleep 3
docker compose -f $DCOMPOSE_PATH logs wpnginx
sleep 3
docker compose -f $DCOMPOSE_PATH logs wpredis
sleep 5
docker compose -f $DCOMPOSE_PATH logs wpdb



