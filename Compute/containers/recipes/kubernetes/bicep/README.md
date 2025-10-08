# Kubernetes Containers Recipe

## Overview

This Bicep recipe deploys containers to Kubernetes using the Bicep Kubernetes extension. It creates Kubernetes Deployment, Service, Secret, ServiceAccount, Role, and RoleBinding resources.

**Maturity Level:** Alpha  
**Platform:** Kubernetes  
**IaC Language:** Bicep

## Features

- ✅ Multi-container deployments
- ✅ Port exposure via ClusterIP Service
- ✅ Environment variable injection
- ✅ Connection-based environment variables
- ✅ Ephemeral volumes (emptyDir)
- ✅ Health probes (readiness/liveness)
- ✅ RBAC (ServiceAccount, Role, RoleBinding)
- ✅ Dapr sidecar support
- ✅ Manual scaling
- ✅ Custom Kubernetes metadata
- ⏳ Persistent volumes (Phase 2)
- ⏳ Secret volumes (Phase 2)
- ⏳ Auto-scaling (Phase 2)
- ⏳ Azure Workload Identity (Phase 2)

## Prerequisites

- Kubernetes cluster (v1.24+)
- Radius CLI with Kubernetes environment configured
- Bicep Kubernetes extension (preview)

## Recipe Input Properties

The recipe receives properties from the `Radius.Compute/containers` resource definition:

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `containers` | object | Yes | Map of container specifications |
| `connections` | object | No | Resource connections for env var injection |
| `volumes` | object | No | Volume definitions (emptyDir only in Alpha) |
| `replicas` | integer | No | Number of replicas (default: 1) |
| `extensions.daprSidecar` | object | No | Dapr sidecar configuration |
| `platformOptions.kubernetes.metadata` | object | No | Custom labels and annotations |

### Container Specification

Each container in the `containers` map includes:

- `image` (required): Container image
- `ports`: Map of port definitions with `containerPort` and optional `protocol`
- `env`: Map of environment variables with `value` or `valueFrom`
- `resources.requests/limits`: CPU and memory constraints
- `readinessProbe/livenessProbe`: Health check configurations
- `volumeMounts`: Array of volume mount points

## Recipe Output Properties

The recipe returns connection information:

| Property | Type | Description |
|----------|------|-------------|
| `host` | string | Kubernetes Service DNS name |
| `port` | string | First exposed port (if any) |

## Usage Example

```bicep
extension radius

param environment string

resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'demo-app'
  properties: {
    environment: environment
  }
}

resource container 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'web'
  properties: {
    application: app.id
    environment: environment
    containers: {
      web: {
        image: 'nginx:latest'
        ports: {
          http: {
            containerPort: 80
          }
        }
      }
    }
    replicas: 3
  }
}
```

## Customization

Platform engineers can customize this recipe by:

1. **Modifying resource defaults**: Change default CPU/memory limits in the recipe
   ```bicep
   // Example: Increase default limits
   cpu: containerName.value.?resources.?limits.?cpu ?? '1000m'  // Changed from 500m
   memory: '${containerName.value.?resources.?limits.?memoryInMib ?? 1024}Mi'  // Changed from 512
   ```

2. **Adding security policies**: Add pod security context
   ```bicep
   spec: {
     securityContext: {
       runAsNonRoot: true
       runAsUser: 1000
     }
   }
   ```

3. **Configuring network policies**: Add NetworkPolicy resources
   ```bicep
   resource networkPolicy 'networking.k8s.io/NetworkPolicy@v1' = {
     // Define ingress/egress rules
   }
   ```

4. **Adding init containers**: Support for init containers
   ```bicep
   initContainers: [
     // Add init container logic based on container.initContainer property
   ]
   ```

5. **Custom volume types**: Add support for ConfigMap volumes
   ```bicep
   // Add ConfigMap volume type alongside emptyDir
   ```

## Limitations (Alpha Stage)

- Only ephemeral volumes (emptyDir) supported
- No persistent volume mounting
- No secret volume mounting
- No auto-scaling configuration
- No Azure Workload Identity integration
- Limited port and environment variable handling due to Bicep for-expression nesting limitations
- Service exposes only first container's ports

## Testing

Test this recipe using:

```bash
make build-bicep-recipe RECIPE_PATH=Compute/containers/recipes/kubernetes/bicep
make test-recipe RECIPE_PATH=Compute/containers/recipes/kubernetes/bicep
```

## Troubleshooting

### Recipe build fails
- Ensure Bicep Kubernetes extension is installed
- Check bicepconfig.json has correct extension reference

### Deployment fails
- Verify container image is accessible from cluster
- Check resource quotas in namespace
- Review pod logs: `kubectl logs -n <namespace> <pod-name>`

### Service not accessible
- Verify container ports are correctly defined
- Check Service selector matches Deployment labels
- Use `kubectl get svc,pods -n <namespace>` to verify resources

## References

- [Radius Recipes Documentation](https://docs.radapp.io/guides/recipes)
- [Bicep Kubernetes Extension](https://learn.microsoft.com/azure/azure-resource-manager/bicep/bicep-kubernetes-extension)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
