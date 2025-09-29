# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker containerization project for PaperMC Minecraft servers. The repository builds optimized, multi-architecture Docker images that are automatically updated daily with the latest PaperMC builds. The project uses GitHub Actions for CI/CD and publishes images to Docker Hub.

## Core Architecture

### Build System
- **Primary build tool**: Docker with multi-stage builds
- **CI/CD**: GitHub Actions workflows in `.github/workflows/`
- **Build matrix generation**: Uses custom Go tool `goPaperMC` to fetch latest Paper versions
- **Multi-architecture**: Builds for `linux/amd64` and `linux/arm64`
- **Daily automation**: Automated builds triggered by cron schedule (`0 0 * * *`)

### Image Architecture
- **Base image**: Eclipse Temurin 21 JRE
- **Security**: Runs as non-root user (UID 9001)
- **Optimization**: Uses Aikar's flags for JVM optimization
- **Health check**: Socket-based health monitoring via `scripts/mc-health-check`
- **Volumes**: Single data volume at `/data` for all persistent state
- **Ports**: Exposes 25565 (Minecraft), 8123 (DynMap)

### Key Components
- `Dockerfile`: Main container definition with optimized multi-stage build
- `scripts/mc-health-check`: Shell script for container health monitoring
- `.github/workflows/build-paper-images.yml`: Main CI/CD pipeline
- `.github/workflows/dockerhub-description.yml`: Automated Docker Hub documentation sync
- `examples/`: Deployment examples for Docker and Kubernetes

## Development Commands

### Building the Image
```bash
# Build with a specific Paper download URL
docker build --build-arg DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/1.21.5/builds/20/downloads/paper-1.21.5-20.jar" -t lexfrei/papermc:local .

# Quick local build for testing
docker build -t lexfrei/papermc:local .
```

### Testing the Image
```bash
# Basic functionality test
docker run -d -p 25565:25565 --name mc-test lexfrei/papermc:local

# Test with persistent data
docker run -d -p 25565:25565 -v $(pwd)/test-data:/data --name mc-test lexfrei/papermc:local

# Test health check
docker run -d --name mc-test lexfrei/papermc:local && sleep 60 && docker exec mc-test mc-health-check

# Cleanup test containers
docker stop mc-test && docker rm mc-test
```

### GitHub Actions Development
```bash
# Install goPaperMC tool for local testing
go install github.com/lexfrei/goPaperMC/cmd/papermc@v0.0.2

# Test build matrix generation
papermc --limit=3 ci github-actions paper

# Get latest version info
papermc ci latest paper
```

### Security Scanning
```bash
# Run Trivy security scan (same as CI)
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasecurity/trivy image lexfrei/papermc:local
```

## Workflow Integration

### Automated Build Process
1. **Prepare job**: Installs goPaperMC and generates build matrix for last 3 Paper versions
2. **Build job**: Matrix builds for each version with security scanning and multi-arch publishing
3. **Security**: Each build includes Trivy vulnerability scanning with SARIF upload
4. **Caching**: Uses GitHub Actions cache for Docker layer caching

### Manual Triggers
- Both workflows support `workflow_dispatch` for manual execution
- Use GitHub CLI: `gh workflow run build-paper-images.yml`

## Container Deployment Patterns

### Docker Compose Development
Use examples in `examples/docker/` for local development setups.

### Kubernetes Production
Reference `examples/kubernetes/` for production deployments with:
- Resource limits and requests
- Persistent volume configurations
- Service definitions
- Optional VPA (Vertical Pod Autoscaler) configurations

## File Structure Context

- **Root level**: Contains main Dockerfile and documentation
- **`.github/workflows/`**: CI/CD automation with daily builds and Docker Hub sync
- **`examples/`**: Platform-specific deployment configurations
- **`scripts/`**: Container utility scripts (health checks, etc.)
- **Container runs from `/data`**: All Minecraft server data persisted in single volume

## Dependencies and Tools

### External Dependencies
- **goPaperMC**: Custom Go tool for Paper version management
- **Eclipse Temurin 21**: JRE base image
- **netcat-openbsd**: For health check socket testing
- **webp**: For DynMap plugin image optimization

### GitHub Secrets Required
- `DOCKERHUB_USERNAME`: Docker Hub authentication
- `DOCKERHUB_TOKEN`: Docker Hub authentication

## Common Development Tasks

### Updating Paper Versions
The build matrix automatically includes the latest 3 minor versions. No manual intervention required unless changing the version limit in the workflow.

### Modifying JVM Flags
Update the `JAVAFLAGS` environment variable in the Dockerfile. Current flags are based on Aikar's optimizations for Paper servers.

### Adding New Ports
Update both the `EXPOSE` directive in Dockerfile and the examples in documentation.

### Health Check Modifications
Edit `scripts/mc-health-check` for alternative health monitoring approaches.