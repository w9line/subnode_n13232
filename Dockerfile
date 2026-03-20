FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /app

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
