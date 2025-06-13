# Zabbix Monitoring Template for SoftEther VPN

## Overview

This template provides comprehensive monitoring for SoftEther VPN users, including:
- Real-time traffic speed monitoring (RX/TX)
- User inactivity tracking
- Alerting for abnormal traffic patterns
- Long-term inactivity detection

## Features

### Metrics Collected

1. **User Traffic Speed**
   - `softether.rx_speed[{#USERNAME}]` - Download speed in Mbps
   - `softether.tx_speed[{#USERNAME}]` - Upload speed in Mbps

2. **User Activity**
   - `softether.user.inactivity[{#USERNAME}]` - Seconds since last activity

### Configuration Files

**/etc/zabbix/zabbix_agent2.d/userparameter_softether.conf**
```conf
UserParameter=softether.rx_speed[*],/etc/zabbix/scripts/softether_user_speed.sh "$1" RX
UserParameter=softether.tx_speed[*],/etc/zabbix/scripts/softether_user_speed.sh "$1" TX
UserParameter=softether.user.inactivity[*],/etc/zabbix/scripts/softether_user_inactivity.sh "$1"
```

### Triggers

| Severity | Trigger Description | Condition |
|----------|----------------------|-----------|
| 🔵 | High traffic for user (last 1m) | `max(last(/SoftEther by Zabbix agent 2/softether.rx_speed[{#USERNAME}]), last(/SoftEther by Zabbix agent 2/softether.tx_speed[{#USERNAME}])) > 20` |
| 🟡🟡 | High continuous traffic for user (last 5m) | `max(avg(/SoftEther by Zabbix agent 2/softether.rx_speed[{#USERNAME}],#5), avg(/SoftEther by Zabbix agent 2/softether.tx_speed[{#USERNAME}],#5)) > 20` |
| 🟠🟠🟠 | Very high continuous traffic for user (last 5m) | `max(avg(/SoftEther by Zabbix agent 2/softether.rx_speed[{#USERNAME}],#5), avg(/SoftEther by Zabbix agent 2/softether.tx_speed[{#USERNAME}],#5)) > 100` |
| 🟡🟡 | User inactive > 6 hours | `last(/SoftEther by Zabbix agent 2/softether.user.inactivity[{#USERNAME}])>21600` |
| ⚪ | User inactive > 90 days | `last(/SoftEther by Zabbix agent 2/softether.user.inactivity[{#USERNAME}])>7776000` |

### Scripts
1. **softether_user_enum.sh**
   - Discovery softether users

2. **softether_user_speed.sh**
   - Calculates RX/TX speeds in Mbps
   - Uses temporary log files to track traffic changes
   - Handles counter resets
   - Requires `bc` for calculations

3. **softether_user_inactivity.sh**
   - Detects active sessions
   - Calculates inactivity time in seconds
   - Handles date conversion from SoftEther format
   - Works with Docker container implementation

## Requirements

1. SoftEther VPN server running in Docker (adjustable for native installs)
2. Zabbix Agent 2 on the VPN server host
3. `bc` package installed on the host: `apt-get install bc` or `yum install bc`
4. Proper permissions for Zabbix agent to execute scripts

## Installation

1. Place both scripts in the Zabbix agent external scripts directory (typically `/etc/zabbix/scripts/`):
   ```bash
   mkdir -p /etc/zabbix/scripts && \
   cp softether_user_enum.sh softether_user_speed.sh softether_user_inactivity.sh /etc/zabbix/scripts/
   ```

2. Set proper ownership and permissions:
   ```bash
   chown zabbix:zabbix /etc/zabbix/scripts/softether_*.sh && \
   chmod 755 /etc/zabbix/scripts/softether_*.sh
   ```

3. Create the log directory with correct permissions:
   ```bash
   mkdir -p /tmp/zabbix/softether_traffic && \
   chown -R zabbix:zabbix /tmp/zabbix && \
   chmod -R 775 /tmp/zabbix
   ```

4. Copy the userparameter configuration file userparameter_softether.conf
   ```bash
   cp userparameter_softether.conf /etc/zabbix/zabbix_agent2.d/userparameter_softether.conf
   ```

6. Restart Zabbix Agent 2:
   ```bash
   sudo systemctl restart zabbix-agent2.service
   ```

7. Import the template into Zabbix server
  
8. Configure host with the template and proper macros

## Configuration Notes

- Adjust `HUB="DEFAULT"` in scripts if using different hub names
- Modify Docker container name in scripts if different from `softethervpn`
- Thresholds in triggers can be adjusted based on your needs
- For production use, consider using a more permanent location than `/tmp` for log files

## Troubleshooting

1. **Script permissions**: Verify with:
   ```bash
   sudo -u zabbix /etc/zabbix/scripts/softether_user_speed.sh testuser RX
   ```

2. **bc not found**: Install with:
   ```bash
   apt-get install bc || yum install bc
   ```

3. **Docker access**: Ensure Zabbix user is in docker group:
   ```bash
   usermod -aG docker zabbix
   ```

4. **Log directory**: Verify permissions:
   ```bash
   ls -ld /tmp/zabbix /tmp/zabbix/softether_traffic
   ```

5. **Debugging**: Check Zabbix agent log:
   ```bash
   tail -f /var/log/zabbix/zabbix_agent2.log
   ```


## Author
Sergey Haeniken
me@haeniken.com
