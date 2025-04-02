# PaperMC Docker Image

[![Build Paper Docker Images](https://github.com/lexfrei/papermc-docker/actions/workflows/build-paper-images.yml/badge.svg)](https://github.com/lexfrei/papermc-docker/actions/workflows/build-paper-images.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/lexfrei/papermc.svg)](https://hub.docker.com/r/lexfrei/papermc)

A lightweight, optimized Docker image for running PaperMC Minecraft servers.

## Features

- Based on Eclipse Temurin 21 JRE
- Automatically updated daily with the latest Paper builds
- Optimized with [Aikar's flags](https://docs.papermc.io/paper/aikars-flags)
- Built-in RCON support with health checks
- Plugin installation support
- Multi-architecture support (amd64, arm64)
- Minimal image size with multi-stage builds

## Tags

- `latest` - Latest PaperMC version
- `<version>` - Specific Minecraft version (e.g. `1.21.4`)
- `<version>-<build>` - Specific Minecraft version and Paper build (e.g. `1.21.4-222`)

## Usage

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `JAVAFLAGS` | Java flags for optimized performance | Aikar's flags |
| `PAPERMC_FLAGS` | Additional PaperMC flags | `--nojline` |

> **Note**: Memory limits should be set using container runtime controls (e.g., Docker's `--memory` flag or Kubernetes resource limits).

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

### Kubernetes

See the [examples/kubernetes](examples/kubernetes) directory for Kubernetes deployment examples.

## Installing Plugins

To install plugins, simply place the JAR files in the `/data/plugins` directory. PaperMC will automatically load plugins from this directory.

For better organization, you can also use `/data/plugins/update` as a directory to store plugins that PaperMC will automatically update.

> **Important**: Make sure your plugin files have the correct permissions (owned by user 9001) or the server may not be able to access them.

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

## Backups

It's recommended to regularly back up your server data. The simplest approach is to stop the container and copy the data directory:

```bash
docker stop minecraft-server
cp -r /path/to/data /path/to/backup
docker start minecraft-server
```

For automated backups, consider using a dedicated backup solution like [Duplicati](https://www.duplicati.com/) or [Restic](https://restic.net/).

## Common Issues & Troubleshooting

### Permission Denied Errors

If you're seeing permission errors when the container tries to access your mounted volumes, it's likely due to the container running as a non-root user (UID 9001) while your host directories have different ownership.

**Solution:** Change the ownership of your data directory to match the container's user (9001):

```bash
sudo chown -R 9001:9001 /path/to/data
sudo chown -R 9001:9001 /path/to/plugins  # If using plugins directory
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

This image includes a health check using RCON. If the health check fails:

1. Ensure the server is running properly
2. Check if RCON is enabled (default is enabled)
3. Verify network connectivity inside the container

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

## License

This project is licensed under the BSD License - see the LICENSE file for details.

## Credits

- [PaperMC](https://papermc.io/) - The high performance Minecraft server
- [Aikar's flags](https://docs.papermc.io/paper/aikars-flags) - Optimized JVM flags for Minecraft servers
- [itzg/rcon-cli](https://github.com/itzg/docker-rcon-cli) - RCON client for Minecraft
