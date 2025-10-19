# papermc

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.21.10](https://img.shields.io/badge/AppVersion-1.21.10-informational?style=flat-square)

PaperMC Minecraft server Helm chart for Kubernetes

**Homepage:** <https://github.com/lexfrei/papermc-docker/>

## About PaperMC

**Important**: This is a third-party Helm chart for [PaperMC](https://papermc.io/). PaperMC itself is developed and maintained by the PaperMC team, not by this chart's maintainers.

- **Upstream Project**: [PaperMC](https://github.com/PaperMC/Paper)
- **Official Documentation**: [docs.papermc.io](https://docs.papermc.io/)
- **Official Discord**: [discord.gg/papermc](https://discord.gg/papermc)

For questions, issues, or support regarding **PaperMC server itself** (gameplay, plugins, server configuration, etc.), please refer to the official PaperMC resources above.

This Helm chart only provides Kubernetes deployment automation for PaperMC.

For issues related to the **Helm chart** (deployment, chart configuration, Kubernetes resources), please use the [chart repository's issue tracker](https://github.com/lexfrei/papermc-docker/issues).

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| lexfrei | <f@lex.la> | <https://github.com/lexfrei> |

## Source Code

* <https://github.com/lexfrei/papermc-docker/>
* <https://github.com/PaperMC/Paper>

## Installing the Chart

This chart is published to GitHub Container Registry (GHCR) as an OCI artifact.

```bash
# Install from GHCR
helm install papermc \
  oci://ghcr.io/lexfrei/papermc \
  --version 0.1.0

# Install with custom values
helm install papermc \
  oci://ghcr.io/lexfrei/papermc \
  --version 0.1.0 \
  --values values.yaml
```

## Uninstalling the Chart

```bash
helm delete papermc
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity for pod assignment |
| fullnameOverride | string | `""` |  |
| httpRoute | object | `{"enabled":false,"spec":{}}` | HTTPRoute configuration (Gateway API) for web interfaces Provides full control over the HTTPRoute spec for maximum flexibility |
| httpRoute.spec | object | `{}` | Full HTTPRoute spec (excluding metadata) The service name will be auto-injected as the chart fullname |
| image | object | `{"pullPolicy":"IfNotPresent","repository":"lexfrei/papermc","tag":""}` | Image configuration |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion |
| imagePullSecrets | list | `[]` |  |
| ingress | object | `{"enabled":false,"spec":{}}` | Ingress configuration for web interfaces (e.g., DynMap) Provides full control over the Ingress spec for maximum flexibility |
| ingress.spec | object | `{}` | Full Ingress spec (excluding metadata) The service name will be auto-injected as the chart fullname |
| livenessProbe | object | `{"enabled":true,"initialDelaySeconds":60,"periodSeconds":15,"tcpSocket":{"port":"minecraft-tcp"}}` | Liveness probe configuration |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` | Node selector for pod assignment |
| persistence | object | `{"accessMode":"ReadWriteOnce","enabled":true,"existingClaim":"","size":"30Gi","storageClassName":""}` | Persistence configuration |
| persistence.accessMode | string | `"ReadWriteOnce"` | Access mode for PVC |
| persistence.existingClaim | string | `""` | Use an existing PVC |
| persistence.size | string | `"30Gi"` | Size of the PVC |
| persistence.storageClassName | string | `""` | Storage class name for PVC |
| podAnnotations | object | `{}` | Pod annotations |
| podLabels | object | `{}` | Pod labels |
| podSecurityContext | object | `{}` | Security context for the pod |
| ports | object | `{"extra":[],"minecraft":{"tcp":25565,"udp":25565}}` | Port configuration |
| ports.extra | list | `[]` | Additional ports for plugins (e.g., DynMap, BlueMap, etc.) Each port will be exposed in both the Pod and Service |
| ports.minecraft | object | `{"tcp":25565,"udp":25565}` | Minecraft server ports (TCP and UDP) |
| readinessProbe | object | `{"enabled":true,"initialDelaySeconds":30,"periodSeconds":10,"tcpSocket":{"port":"minecraft-tcp"}}` | Readiness probe configuration |
| resources | object | `{"limits":{"cpu":"2000m","memory":"4Gi"},"requests":{"cpu":"1000m","memory":"4Gi"}}` | Resource limits and requests |
| securityContext | object | `{}` | Security context for the container |
| service | object | `{"annotations":{},"type":"LoadBalancer"}` | Service configuration |
| service.annotations | object | `{}` | Service annotations (e.g., for LoadBalancer IP assignment) |
| service.type | string | `"LoadBalancer"` | Service type |
| tolerations | list | `[]` | Tolerations for pod assignment |
| updateStrategy | object | `{"type":"RollingUpdate"}` | Update strategy |

## Example Configurations

### Simple Server

Minimal configuration for a basic Minecraft server:

```yaml
persistence:
  size: 30Gi

resources:
  requests:
    memory: "4Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

### Server with DynMap Plugin

Enable additional port for DynMap web interface:

```yaml
ports:
  extra:
    - name: dynmap
      port: 8123
      protocol: TCP

ingress:
  enabled: true
  spec:
    ingressClassName: nginx
    tls:
      - secretName: map-tls
        hosts:
          - map.example.com
    rules:
      - host: map.example.com
        http:
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: papermc  # Will be auto-replaced with release name
                  port:
                    name: dynmap
```

### Server with Multiple Plugins

Configure multiple plugin web interfaces:

```yaml
ports:
  extra:
    - name: dynmap
      port: 8123
      protocol: TCP
    - name: bluemap
      port: 8100
      protocol: TCP
```

### Server on Specific Node

Use node affinity to schedule on a specific node:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - mc-node-01
```

### Gateway API (HTTPRoute) Configuration

Use Gateway API instead of Ingress:

```yaml
ports:
  extra:
    - name: dynmap
      port: 8123
      protocol: TCP

httpRoute:
  enabled: true
  spec:
    parentRefs:
      - name: cilium-gateway
        namespace: kube-system
        sectionName: https
    hostnames:
      - map.example.com
    rules:
      - matches:
          - path:
              type: PathPrefix
              value: /
        backendRefs:
          - name: papermc  # Will be auto-replaced with release name
            port: 8123
```

### LoadBalancer with Fixed IP

Assign a specific IP to the LoadBalancer service:

```yaml
service:
  type: LoadBalancer
  annotations:
    io.cilium/lb-ipam-ips: "172.16.100.253"
    # Or for MetalLB:
    # metallb.io/address-pool: minecraft-pool
```

### Custom Image Version

Override the image tag to use a specific PaperMC version:

```yaml
image:
  tag: "1.21.5-20"
```

## Persistence

By default, the chart creates a PersistentVolumeClaim with 30Gi storage. All server data is stored in `/data` inside the container, which is mounted from this PVC.

To use a different storage class or size:

```yaml
persistence:
  storageClassName: longhorn
  size: 50Gi
```

To use an existing PVC:

```yaml
persistence:
  existingClaim: my-existing-pvc
```

## Resource Management

The default resource configuration is optimized for a server with 10-20 players:

```yaml
resources:
  requests:
    memory: "4Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

Adjust based on your player count and plugin usage.

## Probes

The chart includes liveness and readiness probes using TCP socket checks on the Minecraft port. These ensure the server is running and ready to accept connections.

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
