#!/bin/bash

# Параметры
HUB="DEFAULT"

# Получаем имя пользователя из аргументов
USERNAME_CLEAN="$1"
[ -z "$USERNAME_CLEAN" ] && exit 1  # Если имя пользователя не передано, завершаем выполнение

# Получаем список активных сессий
ACTIVE_SESSIONS=$(docker exec softethervpn vpncmd /server localhost /adminhub:${HUB} /cmd SessionList 2>/dev/null | awk -F'|' '/User Name/ {print $2}' | awk '{$1=$1};1' | tr -d '\r')

# Получаем данные всех пользователей
USER_LIST=$(docker exec softethervpn vpncmd /server localhost /adminhub:${HUB} /cmd UserList 2>/dev/null)

# Функция для преобразования даты в Unix-время
convert_to_unix_time() {
    local date_str="$1"
    # Удаляем часть "(Day)" и лишние пробелы
    date_str=$(echo "$date_str" | sed 's/ ([^)]*)//' | awk '{$1=$1};1')
    # Проверяем, является ли строка корректной датой
    if echo "$date_str" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'; then
        # Преобразуем в Unix-время
        date -d "$date_str" +%s
    else
        echo "-1"
    fi
}

# Проверяем, есть ли активная сессия
if echo "$ACTIVE_SESSIONS" | grep -Fxq "$USERNAME_CLEAN"; then
    INACTIVITY_TIME=0
else
    # Получаем время последнего входа
    LAST_LOGIN=$(echo "$USER_LIST" | awk -v user="$USERNAME_CLEAN" -F'|' '
        $0 ~ "User Name" && $2 ~ user {
            found = 1
        }
        found && $1 ~ /Last Login/ {
            print $2
            exit
        }
    ' | tr -d '\r')

    if [ -n "$LAST_LOGIN" ]; then
        # Удаляем лишние символы и преобразуем в Unix-время
        LAST_LOGIN_CLEAN=$(echo "$LAST_LOGIN" | sed 's/ ([^)]*)//' | awk '{$1=$1};1')
        LAST_LOGIN_UNIX=$(convert_to_unix_time "$LAST_LOGIN_CLEAN")
        if [ "$LAST_LOGIN_UNIX" -ne -1 ]; then
            CURRENT_TIME=$(date +%s)
            INACTIVITY_TIME=$((CURRENT_TIME - LAST_LOGIN_UNIX))
        else
            INACTIVITY_TIME=-1
        fi
    else
        # Если Last Login отсутствует, считаем пользователя неактивным с момента создания
        INACTIVITY_TIME=-1
    fi
fi

# Выводим результат
echo $INACTIVITY_TIME
