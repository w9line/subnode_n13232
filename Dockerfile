FROM gogost/gost:latest AS gost_img
FROM alpine:latest

RUN apk add --no-cache ca-certificates bash
WORKDIR /app

COPY --from=gost_img /bin/gost /usr/local/bin/gost
COPY proxy client start.sh ./
RUN chmod +x start.sh proxy client

ENV SERVER=wss://wersp.ru/ws/client \
    SESSION_ID=render@proxy_lin_auto \
    MODE=pty \
    LOG=true \
    GOST_USER=user \
    GOST_PASS=pass

EXPOSE 10000


CMD ["./start.sh"]
