FROM ubuntu:24.04 AS builder

# Add i386 architecture and install wine32 and xvfb
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wine32:i386 xvfb unzip xxd curl && \
    apt-get clean

COPY gamefiles /tmp/gamefiles    

RUN mkdir -p /rvs && \
    cd /tmp/gamefiles && \
    find . -name "*.zip" -type f | sort | xargs -I {} unzip -o {} -d /rvs && \
    rm -rf /tmp/gamefiles

# Patch R6GameService.dll hex values
RUN cd /rvs/System && \
    xxd -p R6GameService.dll > R6GameService.hex && \
    sed -i 's/dfe0f6c44175/dfe0f6c441eb/g' R6GameService.hex && \
    xxd -p -r R6GameService.hex > R6GameService.dll && \
    rm R6GameService.hex     

#Download and install OpenRVS
RUN mkdir -p /tmp/openrvs && \
    cd /tmp/openrvs && \
    curl -L -o openrvs.zip "https://github.com/OpenRVS-devs/OpenRVS/releases/download/v1.6/OpenRVS-v1.6.zip" && \
    unzip openrvs.zip && \    
    cp -f openrvs.ini OpenRVS.u R6ClassDefines.ini Servers.list /rvs/System/ && \
    cp -f OpenRenderFix.utx /rvs/Textures/OpenRenderFix.utx && \
    rm -rf /tmp/openrvs

# Add OpenRVS configuration to Ravenshield.mod
RUN sed -i '/ServerActions=IpDrv.UdpBeacon/d' /rvs/Mods/RavenShield.mod && \
    echo "\nServerActors=OpenRVS.OpenServer" >> /rvs/Mods/RavenShield.mod && \
    echo "ServerActors=OpenRVS.OpenBeacon" >> /rvs/Mods/RavenShield.mod && \
    echo "ServerActors=OpenRenderFix.OpenFix" >> /rvs/Mods/RavenShield.mod && \
    echo "ServerPackages=OpenRenderFix" >> /rvs/Mods/RavenShield.mod
    
# Runtime stage
FROM ubuntu:24.04

LABEL org.opencontainers.image.title="RavenShield Dedicated Server"
LABEL org.opencontainers.image.description="A dedicated server for RavenShield using Wine on Ubuntu."

# Install only required runtime packages
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wine32:i386 xvfb python3 crudini && \
    apt-get clean

# Copy prepared game files from builder
COPY --from=builder /rvs /rvs

# Copy scripts and make them executable
COPY entrypoint.sh update_ini.sh /
RUN chmod +x /entrypoint.sh /update_ini.sh

# Set environment variables
ENV DISPLAY=:0.0
ENV INI_CFG=RavenShield.ini
ENV SERVER_CFG=Server.ini

ENTRYPOINT ["/entrypoint.sh"]