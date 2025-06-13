#!/bin/bash

# Параметры
HUB="DEFAULT"

# Получаем список пользователей
USER_LIST=$(docker exec softethervpn vpncmd /server localhost /adminhub:${HUB} /cmd UserList 2>/dev/null | grep "User Name" | awk -F'|' '{print $2}' | awk '{$1=$1};1' | tr -d '\r')

# Формируем JSON для Zabbix LLD
echo '{"data":['
FIRST=1
for USERNAME in $USER_LIST; do
    USERNAME_CLEAN=$(echo "$USERNAME" | tr -d '[:space:]')
    [ -z "$USERNAME_CLEAN" ] && continue

    [ $FIRST -eq 0 ] && echo ","
    echo -n '    {"{#USERNAME}":"'$USERNAME_CLEAN'"}'
    FIRST=0
done
echo -e '\n]}'
