#!/bin/bash

# Параметры
USERNAME="$1"  # Получаем из первого аргумента
METRIC="$2"    # RX или TX из второго аргумента
HUB="DEFAULT"
LOG_DIR="/tmp/zabbix/softether_traffic"
RX_LOG_FILE="${LOG_DIR}/${USERNAME}_rx.log"
TX_LOG_FILE="${LOG_DIR}/${USERNAME}_tx.log"

# Проверка аргументов
if [ -z "$USERNAME" ] || [ -z "$METRIC" ]; then
    echo "Usage: $0 <username> <RX|TX>"
    exit 1
fi

# Проверка наличия bc
if ! command -v bc &> /dev/null; then
    echo "ERROR: bc not installed"
    exit 1
fi

# Создаем директорию для логов
mkdir -p "$LOG_DIR"

# Получаем текущий трафик
CURRENT_STATS=$(docker exec softethervpn vpncmd /server localhost /adminhub:${HUB} /cmd UserGet "${USERNAME}" 2>/dev/null)

# Извлекаем трафик
RX_BYTES=$(echo "$CURRENT_STATS" | awk -F'|' '/Incoming Unicast Total Size/ {print $2}' | awk '{print $1}' | tr -d ',')
TX_BYTES=$(echo "$CURRENT_STATS" | awk -F'|' '/Outgoing Unicast Total Size/ {print $2}' | awk '{print $1}' | tr -d ',')

# Проверка полученных значений
if [ -z "$RX_BYTES" ] || [ -z "$TX_BYTES" ]; then
    echo "ERROR: Could not get traffic stats"
    exit 1
fi

# Функция для обработки метрики
process_metric() {
    local METRIC=$1
    local CURRENT_BYTES=$2
    local LOG_FILE=$3
    local METRIC_NAME=$4

    if [ -f "$LOG_FILE" ]; then
        PREV_STATS=$(cat "$LOG_FILE")
        PREV_BYTES=$(echo "$PREV_STATS" | awk '{print $1}')
        TIMESTAMP=$(echo "$PREV_STATS" | awk '{print $2}')

        # Проверка на сброс счетчика
        if [ "$CURRENT_BYTES" -lt "$PREV_BYTES" ]; then
            BYTES_DIFF=$CURRENT_BYTES
        else
            BYTES_DIFF=$((CURRENT_BYTES - PREV_BYTES))
        fi

        TIME_DIFF=$(( $(date +%s) - TIMESTAMP ))

        if [ "$TIME_DIFF" -ge 1 ]; then
            SPEED=$(echo "scale=2; ($BYTES_DIFF * 8) / (1024 * 1024 * $TIME_DIFF)" | bc)
            printf "%.2f\n" "$SPEED" | awk '{if ($1 ~ /^\./) print "0"$1; else print $1}'
        else
            echo "0.00"
        fi
    else
        echo "0.00"
    fi

    # Сохраняем текущие значения
    echo "$CURRENT_BYTES $(date +%s)" > "$LOG_FILE"
}

# Обработка в зависимости от запрошенной метрики
case "$METRIC" in
    "RX")
        process_metric "$METRIC" "$RX_BYTES" "$RX_LOG_FILE" "RX"
        ;;
    "TX")
        process_metric "$METRIC" "$TX_BYTES" "$TX_LOG_FILE" "TX"
        ;;
    *)
        echo "ERROR: Invalid metric. Use RX or TX"
        exit 1
        ;;
esac
