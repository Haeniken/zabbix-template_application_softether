Скриптам необходимы права на запуск, и корректные права:
chmod +x script.sh
chown zabbix:zabbix script.sh

Также необходимо создать директорию с корректными правами для временных операций:
mkdir -p /tmp/zabbix/{softether_inactivity,softether_traffic}
chmod -R 755 /tmp/zabbix/
chown -R zabbix:zabbix /tmp/zabbix/
