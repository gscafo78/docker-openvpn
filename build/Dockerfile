# Use debian:bullseye-slim as the base image
FROM debian:bullseye-slim

LABEL maintainer="Giovanni Scafetta <giovanni.scafetta@gmx.com>"

# Update and install necessary packages
RUN apt update && apt upgrade -y && \ 
    DEBIAN_FRONTEND=noninteractive apt install -y openvpn iptables curl iputils-ping iproute2 && \
    rm -rf /var/lib/apt/lists/*

COPY ./src/generateserver.sh /generateserver.sh
COPY ./src/generateclient.sh /generateclient.sh
COPY ./src/entrypoint.sh /entrypoint.sh

RUN chmod +x /generateserver.sh
RUN chmod +x /generateclient.sh
RUN chmod +x /entrypoint.sh

ENV GENERATE_CLIENT=false
ENV GENERATE_SERVER=false
ENV RUN_CLIENT=false
ENV RUN_SERVER=false
ENV SERVER_PORT=1194
ENV SERVER_PROTO=udp
ENV REDIRECT_GATEWAY=false
ENV FORWARD=false

# Set the entry point
ENTRYPOINT ["/entrypoint.sh"]