#!/bin/bash

./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
CLIENT_PID=$!

echo "$CLIENT_PID"

./proxy &
PROXY_PID=$!

echo "$PROXY_PID"

exec gost -L "socks5+ws://${GOST_USER}:${GOST_PASS}@:10000"
