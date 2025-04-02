# PaperMC Docker Image

[![Build Paper Docker Images](https://github.com/lexfrei/papermc-docker/actions/workflows/build-paper-images.yml/badge.svg)](https://github.com/lexfrei/papermc-docker/actions/workflows/build-paper-images.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/lexfrei/papermc.svg)](https://hub.docker.com/r/lexfrei/papermc)

A lightweight, optimized Docker image for running PaperMC Minecraft servers.

## Features

- Based on Eclipse Temurin 21 JRE
- Automatically updated daily with the latest Paper builds
- Optimized with [Aikar's flags](https://docs.papermc.io/paper/aikars-flags)
- Built-in RCON support
- Multi-architecture support (amd64, arm64)
- Minimal image size

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

## Example Configurations

The [examples](examples) directory contains ready-to-use configuration examples for:

- Docker (Linux and Windows)
- Kubernetes (simple and with Dynmap)

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
