#!/bin/bash

set -e

echo "🚀 Starting services..."

# Запускаем nginx в фоне (daemon off; в конфиге, поэтому & )
echo "📡 Starting nginx on port 10000..."
nginx &
NGINX_PID=$!
sleep 2

# Проверяем что nginx жив
if ! kill -0 $NGINX_PID 2>/dev/null; then
    echo "❌ nginx died!"
    exit 1
fi
echo "✅ nginx running (PID: $NGINX_PID)"

# Запускаем gost на локальном порту 10001 (SOCKS5 over WS)
echo "🔐 Starting gost on 127.0.0.1:10001..."
gost -L "socks5+ws://127.0.0.1:10001?path=/socks5" &
GOST_PID=$!
sleep 2

if ! kill -0 $GOST_PID 2>/dev/null; then
    echo "❌ gost died!"
    exit 1
fi
echo "✅ gost running (PID: $GOST_PID)"

# Запускаем proxy на локальном порту 8080
echo "🔄 Starting proxy on 127.0.0.1:8080..."
PORT=8080 ./proxy &
PROXY_PID=$!
sleep 2

if ! kill -0 $PROXY_PID 2>/dev/null; then
    echo "❌ proxy died!"
    exit 1
fi
echo "✅ proxy running (PID: $PROXY_PID)"

echo "✅ All services started!"
echo "   - nginx: port 10000 (external)"
echo "   - gost:  port 10001 (internal, /socks5)"
echo "   - proxy: port 8080 (internal, /ws/client)"

# Запускаем client (без параметров — использует ENV)
echo "👤 Starting client..."
./client &
echo "✅ client started (PID: $!)"

echo "✅✅✅ ALL SERVICES READY! ✅✅✅"

wait
