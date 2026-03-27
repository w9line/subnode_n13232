#!/bin/bash

# 1. Запускаем туннельный клиент (в фоне)
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
sleep 2

# 2. Запускаем твой прокси-мост на порту 8080 (в фоне)
PORT=8080 ./proxy &
sleep 2

# 3. Запускаем gost на порту 10000 (Вход для тебя)
# Используем ws (не wss), потому что Render сам снимет TLS.
# Перенаправляем (forward) весь трафик на внутренний прокси (127.0.0.1:8080)
exec gost -L "socks5+ws://${GOST_USER}:${GOST_PASS}@:10000" -F "socks5://127.0.0.1:8080"
