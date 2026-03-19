FROM alpine:latest

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

EXPOSE 8080

CMD ["./start.sh"]
