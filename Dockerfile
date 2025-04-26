FROM ubuntu:24.04

LABEL org.opencontainers.image.title="RavenShield Dedicated Server"
LABEL org.opencontainers.image.description="A dedicated server for RavenShield using Wine on Ubuntu."

# Add i386 architecture and install wine32 and xvfb
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wine32:i386 xvfb && \
    apt-get clean

# Set DISPLAY environment variable for Wine
ENV DISPLAY=:0.0

# Set default configuration file arguments for init and server cfg
ENV INIT_CFG=RavenShield.ini
ENV SERVER_CFG=Server.ini

# Run Xvfb in the background then run the wine command with configurable args
CMD ["sh", "-c", "Xvfb :0 -screen 0 640x480x16 2>/dev/null & cd /rvs/system && wine UCC.exe server -ini=${INIT_CFG} -servercfg=${SERVER_CFG}"]