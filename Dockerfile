FROM gogost/gost:latest AS gost

FROM alpine:latest

WORKDIR /app

RUN apk --no-cache add ca-certificates bash

# копируем gost из его образа
COPY --from=gost /bin/gost /usr/local/bin/gost

COPY proxy .
COPY client .
COPY start.sh .
COPY gost.yaml .

RUN chmod +x start.sh proxy client

ENV SERVER=wss://wersp.ru/ws/client
ENV SESSION_ID=render@proxy_lin_auto
ENV MODE=pty
ENV LOG=true
ENV UPSTREAM=wss://wersp.ru
ENV PORT=8080
ENV GOST_USER=user
ENV GOST_PASS=pass

EXPOSE 10000

CMD ["./start.sh"]
