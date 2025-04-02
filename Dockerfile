FROM eclipse-temurin:21.0.6_7-jre-alpine AS build

# Install necessary build tools
RUN apk add --no-cache curl jq

# Download and prepare RCON health check script
RUN mkdir -p /scripts && \
    echo '#!/bin/sh' > /scripts/mc-health-check && \
    echo 'rcon-cli ping > /dev/null 2>&1' >> /scripts/mc-health-check && \
    chmod +x /scripts/mc-health-check

# Final stage
FROM eclipse-temurin:21.0.6_7-jre

# Configure environment
EXPOSE 25565/tcp 25565/udp 8123/tcp
VOLUME /data
WORKDIR /data

# Arguments
ARG RCON_VERSION=latest
ARG DOWNLOAD_URL

# Set up environment variables
# Aikar's flags for optimal JVM settings for Paper/Minecraft servers
# See: https://docs.papermc.io/paper/aikars-flags
ENV PAPERMC_FLAGS="--nojline" \
  JAVAFLAGS="-XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dcom.mojang.eula.agree=true"

# Install dependencies and set up user in a single layer
RUN apt-get update && \
  apt-get install --no-install-recommends -y webp && \
  rm -rf /var/lib/apt/lists/* && \
  mkdir -p /data /opt/minecraft /data/plugins/update && \
  chown -R 9001:9001 /data /opt/minecraft

# Copy RCON and health check script
COPY --from=docker.io/itzg/rcon-cli:${RCON_VERSION} /rcon-cli /usr/local/bin/rcon-cli
COPY --from=build /scripts/mc-health-check /usr/local/bin/

# Add server jar (this will typically change the most, so we keep it near the end)
ADD "${DOWNLOAD_URL}" /opt/minecraft/paperspigot.jar

# Configure health check
HEALTHCHECK --interval=60s --timeout=15s --start-period=120s --retries=3 \
  CMD mc-health-check || exit 1

# Switch to non-root user
USER 9001:9001

# Start server
ENTRYPOINT ["sh", "-c", "java ${JAVAFLAGS} -jar /opt/minecraft/paperspigot.jar ${PAPERMC_FLAGS} nogui"]
