# syntax=docker/dockerfile:1
ARG GO_VERSION=1.26

########################################
# Build stage
########################################
FROM golang:${GO_VERSION}-trixie AS build
ARG ENV_PROTONMAIL_BRIDGE_VERSION=v3.25.0

# Build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    libsecret-1-dev \
    libfido2-dev \
    libcbor-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build/
RUN git clone --depth 1 -b "$ENV_PROTONMAIL_BRIDGE_VERSION" https://github.com/ProtonMail/proton-bridge.git
WORKDIR /build/proton-bridge/
RUN make build-nogui

########################################
# Runtime stage
########################################
FROM debian:trixie-slim

ARG ENV_PROTONMAIL_BRIDGE_VERSION=v3.25.0
LABEL maintainer="Asyncura" \
      org.opencontainers.image.title="Proton Mail Bridge" \
      org.opencontainers.image.description="Proton Mail Bridge (CLI) in Docker" \
      org.opencontainers.image.version="$ENV_PROTONMAIL_BRIDGE_VERSION" \
      org.opencontainers.image.source="https://github.com/asyncura/ProtonMailBridgeDocker" \
      org.opencontainers.image.licenses="GPL-3.0-or-later"

# Ports/interface the bridge itself listens on inside the container.
# It should be 1025/tcp and 1143/tcp but on some k3s instances it could be 1026 and 1144.
# Launch `netstat -ltnp` on a running container to be sure.
ARG ENV_BRIDGE_SMTP_PORT=1025
ARG ENV_BRIDGE_IMAP_PORT=1143
ARG ENV_BRIDGE_HOST=127.0.0.1
# Change ENV_CONTAINER_SMTP_PORT only if you have a docker port conflict on host network namespace.
ARG ENV_CONTAINER_SMTP_PORT=25
ARG ENV_CONTAINER_IMAP_PORT=143
ENV PROTON_BRIDGE_SMTP_PORT=$ENV_BRIDGE_SMTP_PORT \
    PROTON_BRIDGE_IMAP_PORT=$ENV_BRIDGE_IMAP_PORT \
    PROTON_BRIDGE_HOST=$ENV_BRIDGE_HOST \
    CONTAINER_SMTP_PORT=$ENV_CONTAINER_SMTP_PORT \
    CONTAINER_IMAP_PORT=$ENV_CONTAINER_IMAP_PORT \
    ENV_PROTONMAIL_BRIDGE_VERSION=$ENV_PROTONMAIL_BRIDGE_VERSION

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    socat \
    net-tools \
    procps \
    pass \
    ca-certificates \
    libsecret-1-0 \
    libfido2-1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/
COPY --from=build /build/proton-bridge/bridge /build/proton-bridge/proton-bridge /app/
COPY --chmod=755 entrypoint.sh /app/
COPY GPGparams.txt LICENSE.txt /app/

# Default forwarded ports (documentation only; remap with CONTAINER_SMTP_PORT / CONTAINER_IMAP_PORT).
EXPOSE 25/tcp 143/tcp

# Volume to save pass and bridge configurations/data
VOLUME /root

HEALTHCHECK --interval=60s --timeout=5s --start-period=60s --retries=3 \
    CMD bash -c "exec 3<>/dev/tcp/127.0.0.1/${CONTAINER_SMTP_PORT}" || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
