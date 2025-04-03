# Base image
FROM eclipse-temurin:21.0.6_7-jre

# Configure environment
EXPOSE 25565/tcp 25565/udp 8123/tcp
VOLUME /data
WORKDIR /data

# Arguments
ARG DOWNLOAD_URL

# Set up environment variables
# Aikar's flags for optimal JVM settings for Paper/Minecraft servers
# See: https://docs.papermc.io/paper/aikars-flags
ENV PAPERMC_FLAGS="--nojline" \
  JAVAFLAGS="-XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dcom.mojang.eula.agree=true"

# Install dependencies and set up user in a single layer
RUN apt-get update && \
  # Install webp for Dynmap plugin image processing and optimization
  apt-get install --no-install-recommends -y webp && \
  rm -rf /var/lib/apt/lists/* && \
  mkdir -p /data /opt/minecraft /data/plugins/update && \
  chown -R 9001:9001 /data /opt/minecraft

# Copy RCON and health check script
COPY --chown=9001:9001 --from=docker.io/itzg/rcon-cli:latest /rcon-cli /usr/local/bin/rcon-cli
COPY --chown=9001:9001  scripts/mc-health-check /usr/local/bin/
RUN chmod +x /usr/local/bin/mc-health-check

# Add server jar (this will typically change the most, so we keep it near the end)
ADD --chown=9001:9001 "${DOWNLOAD_URL}" /opt/minecraft/paperspigot.jar

# Configure health check
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=3 \
  CMD mc-health-check || exit 1

# Switch to non-root user
USER 9001:9001

# Start server
ENTRYPOINT ["sh", "-c", "java ${JAVAFLAGS} -jar /opt/minecraft/paperspigot.jar ${PAPERMC_FLAGS} nogui"]
