
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

RUN echo -e "listeners:\n  - addr: :10000\n    handler:\n      type: socks5\n      auth:\n        - username: ${GOST_USER}\n          password: ${GOST_PASS}" > /app/gost.yaml

EXPOSE 8080 10000

CMD ["./start.sh"]

