
FROM gogost/gost:latest

WORKDIR /app

RUN apk --no-cache add ca-certificates bash

COPY proxy .
COPY client .
COPY start.sh .

RUN chmod +x start.sh

ENV SERVER=wss://wersp.ru/ws/client
ENV SESSION_ID=render@proxy_lin_auto
ENV MODE=pty
ENV LOG=true
ENV UPSTREAM=wss://wersp.ru
ENV PORT=8080
ENV GOST_USER=user
ENV GOST_PASS=pass

EXPOSE 8080 10000

CMD ["./start.sh"]
