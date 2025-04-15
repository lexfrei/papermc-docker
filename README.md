# PaperMC Docker Image

[![Build Paper Docker Images](https://github.com/lexfrei/papermc-docker/actions/workflows/build-paper-images.yml/badge.svg)](https://github.com/lexfrei/papermc-docker/actions/workflows/build-paper-images.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/lexfrei/papermc.svg)](https://hub.docker.com/r/lexfrei/papermc)
[![License](https://img.shields.io/github/license/lexfrei/papermc-docker)](https://github.com/lexfrei/papermc-docker/blob/master/LICENSE)
[![Docker Image Size](https://img.shields.io/docker/image-size/lexfrei/papermc/latest)](https://hub.docker.com/r/lexfrei/papermc)
[![Wiki](https://img.shields.io/badge/wiki-documentation-informational)](https://github.com/lexfrei/papermc-docker/wiki)

A lightweight, optimized Docker image for running PaperMC Minecraft servers.

## Compatibility

This server is compatible with:

- **Minecraft Java Edition** clients only (not Bedrock Edition)
- PaperMC plugins and Spigot/Bukkit plugins
- Standard Minecraft protocols and tools

## Features

- Based on Eclipse Temurin 21 JRE
- Automatically updated daily with the latest Paper builds
- Optimized with [Aikar's flags](https://docs.papermc.io/paper/aikars-flags)
- Simple socket-based health checks
- Plugin installation support
- Multi-architecture support (amd64, arm64)
- Minimal image size with optimized configuration
- Security-focused: runs as non-root user (UID 9001)

## Tags

- `latest` - Points to the newest Minecraft version
- `<version>` - Specific Minecraft version (e.g., `1.21.5`), which points to the same image as its corresponding build tag
- `<version>-<build>` - Specific Minecraft version with PaperMC build number (e.g., `1.21.5-20`)

Example of tag relationships:
- `latest` → `<newest-version>` → `<newest-version>-<build>` (all point to the same image)
- `<older-version>` → `<older-version>-<build>` (both point to the same image)

To find the latest available tags, check [Docker Hub](https://hub.docker.com/r/lexfrei/papermc/tags).

## Supported Versions

This image automatically builds the latest three minor versions within the current major version daily. For example:

- Latest minor version (e.g., 1.21.5)
- Second most recent minor version (e.g., 1.21.4)
- Third most recent minor version (e.g., 1.21.3)

Only the three most recent minor versions are maintained, not all versions within a major release range. As new minor versions are released, older ones are removed from active maintenance.

### Version Update Policy

- **Daily builds**: The container is rebuilt daily with the latest PaperMC builds for each supported minor version
- **Minor version tracking**: The three most recent minor versions within the current major version are maintained
- **Build tracking**: For each minor version, the latest PaperMC build is tracked and updated
- **Tag synchronization**: Version tags (e.g., `<version>`) always point to their corresponding build-specific tags (e.g., `<version>-<build>`)

> **Recommendation**: Use `latest` tag for testing, but switch to a specific version-build tag (e.g., `<version>-<build>`) for production environments to ensure stability.

## Usage

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `JAVAFLAGS` | Java flags for optimized performance | Aikar's flags |
| `PAPERMC_FLAGS` | Additional PaperMC flags | `--nojline` |

> **Note**: Memory limits should be set using container runtime controls (e.g., Docker's `--memory` flag or Kubernetes resource limits).

### Resource Usage Recommendations

PaperMC's memory requirements vary based on player count, world size, and installed plugins. Here are some general recommendations:

| Player Count | Recommended Memory | Notes |
|-------------|-------------------|-------|
| 1-5 players | 2GB | Suitable for small, vanilla-like servers |
| 5-15 players | 4GB | Good for moderate plugin usage |
| 15-30 players | 6-8GB | Recommended for larger servers with multiple plugins |
| 30+ players | 10GB+ | For busy servers with many plugins and large worlds |

These values are starting points and should be adjusted based on your specific server performance.

> **Kubernetes Users**: Consider using [Vertical Pod Autoscaler](#kubernetes-resource-management) to automatically adjust resource limits based on actual usage patterns. This is particularly helpful for Minecraft servers with variable loads.

### Docker Run

```bash
docker run -d \
  --name minecraft-server \
  -p 25565:25565/tcp \
  -p 25565:25565/udp \
  --memory 4G \
  -v /path/to/data:/data \
  lexfrei/papermc:latest
```

> **Note**: For production environments, replace `latest` with a specific version-build tag after testing.

### Docker Compose

```yaml
version: '3'

services:
  papermc:
    image: lexfrei/papermc:latest
    container_name: minecraft-server
    ports:
      - "25565:25565/tcp"
      - "25565:25565/udp"
    volumes:
      - ./data:/data
    deploy:
      resources:
        limits:
          memory: 4G
    restart: unless-stopped
```

> **Note**: For production deployments, use a specific version-build tag instead of `latest`.

### Kubernetes

See the [examples/kubernetes](examples/kubernetes) directory for Kubernetes deployment examples.

#### Kubernetes Resource Management

When running in Kubernetes, consider using the Vertical Pod Autoscaler (VPA) to automatically adjust CPU and memory requests:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: minecraft-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: minecraft-server
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
      - containerName: "*"
        minAllowed:
          memory: "1Gi"
          cpu: "500m"
        maxAllowed:
          memory: "8Gi"
          cpu: "2"
```

The VPA will analyze resource usage over time and automatically adjust the resource requests, which helps optimize resource allocation while preventing OOM kills during peak usage.

### Multi-Server Setup

Running multiple Minecraft servers on the same host is straightforward with this container. Each container needs its own ports and data volume:

```yaml
version: '3'

services:
  survival:
    image: lexfrei/papermc:latest
    container_name: mc-survival
    ports:
      - "25565:25565/tcp"
      - "25565:25565/udp"
    volumes:
      - ./survival-data:/data
    deploy:
      resources:
        limits:
          memory: 4G
    restart: unless-stopped
    
  creative:
    image: lexfrei/papermc:latest
    container_name: mc-creative
    ports:
      - "25566:25565/tcp"  # Note different host port
      - "25566:25565/udp"
    volumes:
      - ./creative-data:/data
    deploy:
      resources:
        limits:
          memory: 4G
    restart: unless-stopped
```

This example runs a survival server on the default port 25565 and a creative server on port 25566.

## Installing Plugins

To install plugins, simply place the JAR files in the `/data/plugins` directory. PaperMC will automatically load plugins from this directory.

For better organization, you can also use `/data/plugins/update` as a directory to store plugins that PaperMC will automatically update.

> **Important**: The container runs as a non-root user (UID 9001). When mounting volumes, ensure the `/data` directory has appropriate permissions.

```bash
docker run -d \
  --name minecraft-server \
  -p 25565:25565/tcp \
  -p 25565:25565/udp \
  --memory 4G \
  -v /path/to/data:/data \
  lexfrei/papermc:latest
```

With this setup, you can add plugins by placing them in `/path/to/data/plugins`.

### Recommended Plugins

These plugins are known to work well with this container:

- **[EssentialsX](https://essentialsx.net/)** - Core server commands and functionality
- **[LuckPerms](https://luckperms.net/)** - Permission management
- **[CoreProtect](https://modrinth.com/plugin/coreprotect)** - Block logging and rollback
- **[Dynmap](https://dynmap.us/)** - Real-time web-based map (port 8123 exposed by default)
- **[WorldEdit](https://enginehub.org/worldedit/)** - In-game world editing
- **[WorldGuard](https://enginehub.org/worldguard/)** - Area protection

These are simply recommendations - all standard Paper plugins should work with this container.

## Server Configuration

### server.properties

Create a `server.properties` file in your data directory to customize your server settings. If no file exists, a default one will be created on first run.

Example configuration:

```properties
server-port=25565
motd=My PaperMC Server
max-players=20
view-distance=10
spawn-protection=0
```

### Using RCON (Optional)

If you need to use RCON for server management, you have two options:

1. Use an external RCON client or sidecar container
2. Connect to the server using an RCON client of your choice

To enable RCON, add these settings to your `server.properties`:

```properties
enable-rcon=true
rcon.password=your_secure_password
rcon.port=25575
```

And expose the RCON port when running your container:

```bash
docker run -d \
  --name minecraft-server \
  -p 25565:25565/tcp \
  -p 25565:25565/udp \
  -p 25575:25575/tcp \  # Expose RCON port
  --memory 4G \
  -v /path/to/data:/data \
  lexfrei/papermc:latest
```

### Logging Configuration

PaperMC server logs are stored in the `/data/logs` directory and can be accessed by mounting this volume. You can view them with:

```bash
# View logs from the container
docker logs minecraft-server

# Access detailed logs from the mounted volume
cat /path/to/data/logs/latest.log
```

To customize logging behavior, you can modify `/data/log4j2.xml` after the first server run. For example, to change retention policy or log levels.

### DynMap Configuration

If you're using DynMap, make sure to expose port 8123:

```bash
docker run -d \
  --name minecraft-server \
  -p 25565:25565/tcp \
  -p 25565:25565/udp \
  -p 8123:8123/tcp \  # Expose DynMap web interface
  --memory 4G \
  -v /path/to/data:/data \
  lexfrei/papermc:latest
```

## Container Lifecycle

### Proper Shutdown Procedure

Minecraft servers need proper shutdown procedures to save all world data and prevent corruption. This container is configured to handle Docker stop signals correctly.

When stopping the container:

```bash
# Allow 30 seconds for clean shutdown
docker stop --time=30 minecraft-server
```

This gives the server time to save all chunks and player data properly before terminating.

### Startup Time

The container includes a reasonable startup-period in its health check to accommodate the time it takes for PaperMC to initialize. Larger worlds and more plugins will increase startup time.

## Backups

It's recommended to regularly back up your server data. The simplest approach is to stop the container and copy the data directory:

```bash
docker stop minecraft-server
cp -r /path/to/data /path/to/backup
docker start minecraft-server
```

For automated backups, consider using a dedicated backup solution like [Duplicati](https://www.duplicati.com/) or [Restic](https://restic.net/).

## Volumes and Persistence

This container uses a single volume at `/data` which contains all persistent data. Here's what's stored in this volume:

| Path | Description |
|------|-------------|
| `/data/world/` | The main world data |
| `/data/world_nether/` | The Nether dimension |
| `/data/world_the_end/` | The End dimension |
| `/data/plugins/` | All installed plugins |
| `/data/config/` | Configuration files |
| `/data/logs/` | Server logs |
| `/data/server.properties` | Main server configuration |
| `/data/banned-ips.json` | IP ban list |
| `/data/banned-players.json` | Player ban list |
| `/data/ops.json` | Server operators list |
| `/data/whitelist.json` | Whitelisted players list |

When mounting volumes, always ensure the entire `/data` directory is preserved to maintain all server state.

## Common Issues & Troubleshooting

### Permission Denied Errors

If you're seeing permission errors when the container tries to access your mounted volumes, it's likely due to the container running as a non-root user (UID 9001) while your host directories have different ownership.

**Solution:** Change the ownership of your data directory to match the container's user (9001):

```bash
sudo chown -R 9001:9001 /path/to/data
```

### Container Crashes Due to Memory Limits

If the container crashes with `java.lang.OutOfMemoryError`, your memory limits may be too low.

**Solution:** Increase the container memory limit:

```bash
docker run -d --memory 6G ... lexfrei/papermc:latest
```

For Kubernetes, update your resource limits:

```yaml
resources:
  limits:
    memory: "6G"
```

### Server Won't Start

Check the logs with:

```bash
docker logs minecraft-server
```

Common issues include:

- Incompatible plugins
- Incorrect server.properties configuration
- Insufficient disk space

### Health Check Failures

This image includes a socket-based health check. If the health check fails:

1. Ensure the server is running properly
2. Verify the Minecraft server port (25565) is accessible from within the container
3. Check server logs for any startup issues

### World Corruption Issues

If you experience world corruption:

1. Always use proper shutdown procedures (`docker stop --time=30 minecraft-server`)
2. Ensure you have sufficient disk space (low disk space can cause saving issues)
3. Restore from a backup or attempt repair with PaperMC's built-in repair tools

### Network Connectivity Problems

If players cannot connect to your server:

1. Verify the server is running with `docker logs minecraft-server`
2. Check that port forwarding is correctly set up on your router/firewall
3. Confirm the correct ports are exposed in your Docker configuration
4. Try connecting locally first to isolate network issues

### Plugin Compatibility

If a plugin is causing issues:

1. Start the server with minimal plugins to identify the problematic one
2. Check for plugin updates - older plugins may not work with newer Minecraft versions
3. Look at the server logs for specific error messages related to plugins

## Migration Guide

### Migrating from Other Containers

If you're migrating from another Minecraft container (like itzg/minecraft-server):

1. Stop your existing container
2. Copy the world data (usually in `/data/world` or similar path)
3. Copy your plugins folder
4. Copy your server.properties and other config files
5. Adjust file permissions: `sudo chown -R 9001:9001 /path/to/new/data`
6. Start the new container with the new data directory

### Migrating Server Versions

When upgrading Minecraft versions:

1. Always back up your data first
2. Test with a copy of your data before upgrading production
3. Check plugin compatibility with the new version
4. For major version upgrades, consider starting the server with `--forceUpgrade` flag

## Building the Image

```bash
docker build -t lexfrei/papermc:latest .
```

## Contributing

Contributions are welcome! Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines.

## License

This project is licensed under the BSD License - see the LICENSE file for details.

## Credits

- [PaperMC](https://papermc.io/) - The high performance Minecraft server
- [Aikar's flags](https://docs.papermc.io/paper/aikars-flags) - Optimized JVM flags for Minecraft servers
