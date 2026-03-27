#!/bin/bash

# Запускаем клиент в фоне
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
echo "Client started with PID $!"

# Запускаем прокси в фоне
./proxy &
echo "Proxy started with PID $!"

# Ждем пару секунд, чтобы фоновые процессы успели стартовать
sleep 2

# Запускаем gost как основной процесс (через exec)
# Важно: убедись, что gost.yaml лежит в /app/
exec gost -C /app/gost.yaml
