# Base image: Red Hat UBI9 OpenJDK 25 runtime with run-java.sh entrypoint
FROM registry.access.redhat.com/ubi9/openjdk-25-runtime:1.24-2

# Configure environment
EXPOSE 25565/tcp 25565/udp 8123/tcp
VOLUME /data
WORKDIR /data

# Arguments
ARG DOWNLOAD_URL

# Set up environment variables for run-java.sh entrypoint
# JAVA_APP_DIR: where run-java.sh runs from and looks for the jar
# JAVA_APP_JAR: explicit jar file name
# GC_CONTAINER_OPTIONS: override default ParallelGC with G1GC for Minecraft
# JAVA_OPTS_APPEND: Aikar's flags for optimal JVM settings for Paper/Minecraft servers
# See: https://docs.papermc.io/paper/aikars-flags
ENV JAVA_APP_DIR="/data" \
  JAVA_APP_JAR="/opt/minecraft/paperspigot.jar" \
  JAVA_APP_NAME="papermc" \
  GC_CONTAINER_OPTIONS="-XX:+UseG1GC" \
  JAVAFLAGS="-XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dcom.mojang.eula.agree=true" \
  JAVA_OPTS_APPEND="-XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dcom.mojang.eula.agree=true" \
  PAPERMC_FLAGS="--nojline"

# Install libwebp for Dynmap plugin image processing and create directories
USER root
# hadolint ignore=DL3041
RUN microdnf install --assumeyes --nodocs libwebp && \
  microdnf clean all && \
  mkdir -p /data /opt/minecraft && \
  chown -R 9001:9001 /data /opt/minecraft
USER 9001:9001

# Add server jar
# hadolint ignore=DL3020
ADD --chown=9001:9001 "${DOWNLOAD_URL}" /opt/minecraft/paperspigot.jar

# Configure health check using bash /dev/tcp (no nc needed)
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=3 \
  CMD bash -c 'exec 3<>/dev/tcp/localhost/25565 && exec 3<&-'

# Start server using run-java.sh with Paper-specific arguments
ENTRYPOINT ["/opt/jboss/container/java/run/run-java.sh"]
CMD ["--nojline", "nogui"]
