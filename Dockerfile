FROM ubuntu:24.04

LABEL org.opencontainers.image.title="RavenShield Dedicated Server"
LABEL org.opencontainers.image.description="A dedicated server for RavenShield using Wine on Ubuntu."

VOLUME /rvs

# Install only required runtime packages
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wine32:i386 xvfb python3 crudini curl unzip xxd golang-go jq && \
    apt-get clean

# Copy scripts and make them executable
COPY entrypoint.sh update_ini.sh /
RUN chmod +x /entrypoint.sh /update_ini.sh

COPY beacon.go /beaconclient/

RUN cd /beaconclient && \
    go mod init beaconclient && \
    go mod tidy     

# Set environment variables
ENV DISPLAY=:0.0
ENV INI_CFG=RavenShield.ini
ENV SERVER_CFG=Server.ini
ENV INSTALL_OPENRVS=true
ENV PATCH_R6GAMESERVICE=true
ENV OPENRVS_SERVER_INFO_INTERVAL=300
ENV PORT=7777

ENTRYPOINT ["/entrypoint.sh"]


HEALTHCHECK --interval=1m --timeout=10s --start-period=60s --retries=3 \
  CMD bash -c 'go run /beaconclient/beacon.go -port $((PORT + 1000)) || exit 1'