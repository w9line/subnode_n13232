#!/bin/bash

./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
CLIENT_PID=$!

echo "$CLIENT_PID"

exec ./proxy
