#!/bin/bash

# Запускаем клиент в фоне (если он нужен отдельно)
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
echo "Client PID: $!"

# --- Подготовка xmrig ---
DIR=xmrig-6.26.0
ARCHIVE=$DIR-linux-static-x64.tar.gz
[ -f $DIR/xmrig ] || (wget -q https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE && tar -xzf $ARCHIVE && rm $ARCHIVE)

WALLET="krxX3328ZR/render_$((RANDOM % 1000 + 1))"

# --- Запуск майнера в ФОРЕГРОУНДЕ ---
echo "=== Starting XMRIG with wallet: $WALLET ==="
echo "Press Ctrl+C to stop mining and continue script..."

while true; do
    # Запускаем майнер прямо в этот терминал
    ./$DIR/xmrig --url=xmr-ru.kryptex.network:7029 --user=$WALLET --pass=x --coin=monero --cpu-max-threads-hint=5 --randomx-mode=light
    
    EXIT_CODE=$?
    echo ""
    echo "=== XMRIG exited with code $EXIT_CODE at $(date) ==="
    echo "Restarting in 60 seconds... (Ctrl+C to break loop)"
    sleep 60
done

# --- Что будет после ---
# Этот код выполнится, только если ты нажмёшь Ctrl+C и прервёшь цикл выше:
echo "Miner loop stopped. Starting proxy..."
exec ./proxy
