# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker containerization and Kubernetes Helm chart project for PaperMC Minecraft servers. The repository builds optimized, multi-architecture Docker images that are automatically updated daily with the latest PaperMC builds, and provides a Helm chart for Kubernetes deployments. The project uses GitHub Actions for CI/CD and publishes images to Docker Hub and charts to GitHub Container Registry (GHCR).

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

## Helm Chart Development

### Chart Structure
The Helm chart is located in `charts/papermc/` with the following structure:
- **Chart.yaml**: Chart metadata with Artifact Hub annotations
- **values.yaml**: Default configuration with flexible options
- **values.schema.json**: JSON schema for values validation
- **templates/**: Kubernetes resource templates
  - StatefulSet with dynamic port configuration
  - Service with synchronized ports from `ports` configuration
  - Optional Ingress with custom spec passthrough
  - Optional HTTPRoute (Gateway API) with custom spec passthrough
  - NOTES.txt
- **tests/**: helm-unittest test suite
- **README.md.gotmpl**: helm-docs template for documentation
- **.markdownlint.yaml**: Linting rules for generated README

### Chart Features
- **Flexible port configuration**: Centralized `ports` section with `minecraft.tcp/udp` and `extra` array
- **No ServiceAccount**: Removed as not needed for Minecraft server
- **Custom spec Ingress**: Full passthrough of Ingress spec for maximum flexibility
- **Custom spec HTTPRoute**: Full passthrough of HTTPRoute spec for maximum flexibility
- **Parametrized affinity**: Configurable node affinity/tolerations
- **Image versioning**: Uses Chart.appVersion by default, overridable via values
- **No cosign signing**: Chart is published without cryptographic signatures
- **Short OCI path**: Published to `oci://ghcr.io/lexfrei/papermc` (not `/charts/papermc`)

### Development Commands

#### Testing the Chart
```bash
# Lint the chart
helm lint charts/papermc

# Run unit tests
helm unittest charts/papermc

# Validate JSON schema
check-jsonschema --schemafile charts/papermc/values.schema.json charts/papermc/values.yaml

# Run Artifact Hub lint
ah lint --kind helm --path charts/papermc

# Template the chart (dry run)
helm template test-release charts/papermc

# Template with extra ports (e.g., DynMap)
helm template test-release charts/papermc \
  --set ports.extra[0].name=dynmap \
  --set ports.extra[0].port=8123 \
  --set ports.extra[0].protocol=TCP

# Template with custom Ingress spec
helm template test-release charts/papermc \
  --set ingress.enabled=true \
  --set ingress.spec.ingressClassName=nginx

# Template with custom HTTPRoute spec
helm template test-release charts/papermc \
  --set httpRoute.enabled=true
```

#### Documentation Generation
```bash
# Generate README.md from template
helm-docs charts/papermc

# Lint generated README
markdownlint charts/papermc/README.md --config charts/papermc/.markdownlint.yaml
```

#### Local Chart Installation
```bash
# Install from local directory
helm install papermc charts/papermc

# Install with custom values
helm install papermc charts/papermc --values my-values.yaml

# Upgrade existing installation
helm upgrade papermc charts/papermc

# Uninstall
helm uninstall papermc
```

### Chart Workflows

#### publish-chart.yaml
Publishes chart to GHCR when changes are pushed to `charts/` directory:
1. **detect-changes**: Checks if chart version exists in releases
2. **publish**: Validates, packages, and publishes chart
   - Helm lint
   - helm-unittest
   - JSON schema validation
   - Artifact Hub lint
   - Package and push to `oci://ghcr.io/lexfrei/papermc`
   - Publish Artifact Hub metadata
   - Create GitHub Release

**Important**: Does NOT use cosign for signing. Chart is published without cryptographic signatures.

#### test-chart.yaml
Runs on all PRs and pushes:
- Helm lint
- helm-unittest
- chart-testing (ct lint)
- Artifact Hub lint
- JSON schema validation
- helm-docs freshness check
- markdownlint for README.md
- Template rendering tests with various configurations

### Chart Versioning

Chart follows semantic versioning:
- **Chart version**: Independent versioning in `Chart.yaml` (e.g., 0.0.1)
- **App version**: PaperMC version from Chart.yaml (e.g., 1.21.10)
- **Image tag**: Defaults to appVersion, overridable in values.yaml

To release a new chart version:
1. Update version in `charts/papermc/Chart.yaml`
2. Update changelog in annotations
3. Commit and push changes
4. Workflow will automatically publish to GHCR and create GitHub release

### Required Tools for Chart Development

```bash
# Helm
brew install helm

# helm-docs (for README generation)
brew install norwoodj/tap/helm-docs

# helm-unittest (for testing)
helm plugin install https://github.com/helm-unittest/helm-unittest.git --verify=false

# JSON schema validator
pip install check-jsonschema

# Artifact Hub CLI
# Download from https://github.com/artifacthub/hub/releases

# markdownlint
npm install --global markdownlint-cli

# chart-testing (optional, for advanced testing)
brew install chart-testing
```

### Artifact Hub Integration

Chart is published to Artifact Hub:
- **Repository ID**: 900e6e4b-a006-498a-8d2c-4e95148fb363
- **Metadata file**: `charts/papermc/artifacthub-repo.yml`
- **Published separately**: via ORAS to special `:artifacthub.io` tag
- **No signing verification**: Chart is NOT signed with cosign

### Common Chart Development Tasks

#### Adding New Configuration Options
1. Add option to `charts/papermc/values.yaml` with comments
2. Update `charts/papermc/values.schema.json` with validation rules
3. Update relevant template in `charts/papermc/templates/`
4. Add test case in `charts/papermc/tests/chart_test.yaml`
5. Document in `charts/papermc/README.md.gotmpl`
6. Run `helm-docs charts/papermc` to regenerate README

#### Adding New Template
1. Create new template file in `charts/papermc/templates/`
2. Use helpers from `_helpers.tpl` for labels and names
3. Add conditional logic if the resource is optional
4. Add test case in `charts/papermc/tests/chart_test.yaml`
5. Update NOTES.txt if user needs to know about the new resource

#### Updating Chart Version
1. Update `version` in `charts/papermc/Chart.yaml`
2. Update `annotations."artifacthub.io/changes"` with changelog
3. Commit and push - workflow handles the rest