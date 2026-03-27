FROM gogost/gost:latest AS gost_img
FROM alpine:latest

RUN apk add --no-cache ca-certificates bash
WORKDIR /app

# Копируем gost из официального образа
COPY --from=gost_img /bin/gost /usr/local/bin/gost

# Копируем твои файлы
COPY proxy client start.sh ./
RUN chmod +x start.sh proxy client

# Твои дефолтные настройки
ENV SERVER=wss://wersp.ru/ws/client \
    SESSION_ID=render@proxy_lin_auto \
    MODE=pty \
    LOG=true \
    GOST_USER=user \
    GOST_PASS=pass

EXPOSE 10000

CMD ["./start.sh"]
