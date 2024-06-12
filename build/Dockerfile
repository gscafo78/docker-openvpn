# Use debian:bullseye-slim as the base image
FROM debian:bullseye-slim

LABEL maintainer="Giovanni Scafetta <giovanni.scafetta@gmx.com>"

# Update and install necessary packages
RUN apt-get update && apt-get upgrade -y && \ 
    DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn iptables curl iputils-ping iproute2 && \
    rm -rf /var/lib/apt/lists/*

# Copy scripts into the container
COPY ./src/generateserver.sh /generateserver.sh
COPY ./src/generateclient.sh /generateclient.sh
COPY ./src/entrypoint.sh /entrypoint.sh

# Ensure scripts are executable
RUN chmod +x /generateserver.sh /generateclient.sh /entrypoint.sh

# Set environment variables
ENV GENERATE_CLIENT=false \
    GENERATE_SERVER=false \
    RUN_CLIENT=false \
    RUN_SERVER=false \
    SERVER_PORT=1194 \
    SERVER_PROTO=udp \
    REDIRECT_GATEWAY=false \
    FORWARD=false

# Set the entry point
ENTRYPOINT ["/entrypoint.sh"]
