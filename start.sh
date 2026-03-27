#!/bin/bash

# 1. Сначала gost — чтобы Render схватил порт 10000
gost -L "socks5+ws://${GOST_USER}:${GOST_PASS}@:10000" &
sleep 3

# 2. Потом клиент
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &

# 3. Потом прокси на другом порту
PORT=8080 ./proxy &

# Ждём все процессы
wait
