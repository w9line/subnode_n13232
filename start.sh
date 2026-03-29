#!/bin/bash

# Запускаем nginx (слушает порт 10000, роутит по путям)
nginx &
sleep 1

# Запускаем gost на локальном порту 10001 (SOCKS5 over WS)
# nginx будет роутить /socks5 → localhost:10001
gost -L "socks5+ws://127.0.0.1:10001" &
sleep 2

# Запускаем proxy на локальном порту 8080
# nginx будет роутить /ws/client → localhost:8080
PORT=8080 ./proxy &

# client не нужен, т.к. proxy сам подключается к main-серверу
# Если нужен client для управления этим контейнером - раскомментируй:
./client &

wait
