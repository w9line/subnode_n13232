#!/bin/bash

./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &

PORT=8080 ./proxy &

exec gost -L "socks5+wss://${GOST_USER}:${GOST_PASS}@:10000"
