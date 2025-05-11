#!/bin/bash

log() { echo "$(date --utc -Iseconds) INFO [entrypoint] $*"; }

if [  -n "$UXP_TOKEN_PIN" ]
then
    echo "UXP_TOKEN_PIN variable set, writing to /etc/uxp/autologin"
    echo "$UXP_TOKEN_PIN" > /etc/uxp/autologin
    unset UXP_TOKEN_PIN
fi

if [  -n "$UXPADMIN_PASS" ]
then
   echo "UXPADMIN_PASS variable set, changing pass"
   echo "uxpadmin:$UXPADMIN_PASS" | chpasswd
   unset UXPADMIN_PASS
fi

#exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

log "Starting supervisord"
supervisord -c /etc/supervisor/supervisord.conf &

SUP_PID=$!

log "Locking down root access"

# Удаляем shell у root и блокируем root-пароль
usermod -s /usr/sbin/nologin root || true
passwd -l root || true

wait "$SUP_PID"