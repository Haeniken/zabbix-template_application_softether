# Шаблон мониторинга SoftEther VPN для Zabbix 7.2

## Обзор

Данный шаблон предоставляет комплексный мониторинг пользователей SoftEther VPN, включая:
- Мониторинг скорости трафика в реальном времени (RX/TX)
- Отслеживание неактивности пользователей
- Оповещения об аномальных паттернах трафика
- Выявление долгой неактивности

## Возможности

### Собираемые метрики

1. **Скорость трафика пользователей**
   - `softether.rx_speed[{#USERNAME}]` - Скорость загрузки в Mbps
   - `softether.tx_speed[{#USERNAME}]` - Скорость отдачи в Mbps

2. **Активность пользователей**
   - `softether.user.inactivity[{#USERNAME}]` - Время неактивности в секундах

### Конфигурационные файлы

**/etc/zabbix/zabbix_agent2.d/userparameter_softether.conf**
```conf
UserParameter=softether.rx_speed[*],/etc/zabbix/scripts/softether_user_speed.sh "$1" RX
UserParameter=softether.tx_speed[*],/etc/zabbix/scripts/softether_user_speed.sh "$1" TX
UserParameter=softether.user.inactivity[*],/etc/zabbix/scripts/softether_user_inactivity.sh "$1"
```

### Триггеры

| Важность | Описание триггера | Условие |
|----------|-------------------|---------|
| 🔵 | Высокий трафик пользователя (за 1 мин) | `max(last(/SoftEther by Zabbix agent 2/softether.rx_speed[{#USERNAME}]), last(/SoftEther by Zabbix agent 2/softether.tx_speed[{#USERNAME}])) > 20` |
| 🟡🟡 | Высокий постоянный трафик (за 5 мин) | `max(avg(/SoftEther by Zabbix agent 2/softether.rx_speed[{#USERNAME}],#5), avg(/SoftEther by Zabbix agent 2/softether.tx_speed[{#USERNAME}],#5)) > 20` |
| 🟠🟠🟠 | Очень высокий постоянный трафик (за 5 мин) | `max(avg(/SoftEther by Zabbix agent 2/softether.rx_speed[{#USERNAME}],#5), avg(/SoftEther by Zabbix agent 2/softether.tx_speed[{#USERNAME}],#5)) > 100` |
| 🟡🟡 | Пользователь неактивен > 6 часов | `last(/SoftEther by Zabbix agent 2/softether.user.inactivity[{#USERNAME}])>21600` |
| ⚪ | Пользователь неактивен > 90 дней | `last(/SoftEther by Zabbix agent 2/softether.user.inactivity[{#USERNAME}])>7776000` |

### Скрипты

1. **softether_user_enum.sh**
   - Обнаружение пользователей SoftEther

2. **softether_user_speed.sh**
   - Вычисление скорости RX/TX в Mbps
   - Использует временные файлы логов для отслеживания трафика
   - Обрабатывает сброс счетчиков
   - Требует установленного `bc` для расчетов

3. **softether_user_inactivity.sh**
   - Определяет активные сессии
   - Вычисляет время неактивности в секундах
   - Конвертирует даты из формата SoftEther
   - Работает с реализацией через Docker-контейнер

## Требования

1. Сервер SoftEther VPN в Docker (можно адаптировать для обычной установки)
2. Zabbix Agent 2 на хосте с VPN сервером
3. Установленный пакет `bc`: `apt-get install bc` или `yum install bc`
4. Правильные права для выполнения скриптов агентом Zabbix

## Установка

1. Разместите скрипты в директории внешних скриптов Zabbix (обычно `/etc/zabbix/scripts/`):
   ```bash
   mkdir -p /etc/zabbix/scripts && \
   cp softether_user_enum.sh softether_user_speed.sh softether_user_inactivity.sh /etc/zabbix/scripts/
   ```

2. Установите правильные права:
   ```bash
   chown zabbix:zabbix /etc/zabbix/scripts/softether_*.sh && \
   chmod 755 /etc/zabbix/scripts/softether_*.sh
   ```

3. Создайте директорию для логов с нужными правами:
   ```bash
   mkdir -p /tmp/zabbix/softether_traffic && \
   chown -R zabbix:zabbix /tmp/zabbix && \
   chmod -R 775 /tmp/zabbix
   ```

4. Скопируйте конфигурационный файл:
   ```bash
   cp userparameter_softether.conf /etc/zabbix/zabbix_agent2.d/userparameter_softether.conf
   ```

5. Перезапустите Zabbix Agent 2:
   ```bash
   sudo systemctl restart zabbix-agent2.service
   ```

6. Импортируйте шаблон в сервер Zabbix
7. Настройте хост с шаблоном и соответствующими макросами

## Примечания по конфигурации

- Измените `HUB="DEFAULT"` в скриптах, если используете другие имена хаба
- Измените имя Docker-контейнера в скриптах, если отличается от `softethervpn`
- Пороги срабатывания триггеров можно настроить под свои нужды
- Для production-использования рекомендуется выбрать более постоянное место для логов, чем `/tmp`

## Поиск проблем

1. **Права скриптов**: Проверьте командой:
   ```bash
   sudo -u zabbix /etc/zabbix/scripts/softether_user_speed.sh testuser RX
   ```

2. **bc не найден**: Установите пакет:
   ```bash
   apt-get install bc || yum install bc
   ```

3. **Доступ к Docker**: Убедитесь, что пользователь zabbix в группе docker:
   ```bash
   usermod -aG docker zabbix
   ```

4. **Директория логов**: Проверьте права:
   ```bash
   ls -ld /tmp/zabbix /tmp/zabbix/softether_traffic
   ```

5. **Отладка**: Проверьте лог агента Zabbix:
   ```bash
   tail -f /var/log/zabbix/zabbix_agent2.log
   ```

## Автор
Sergey Haeniken
me@haeniken.com
