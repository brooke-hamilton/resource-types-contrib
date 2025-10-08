# Container Recipe Test Application

## Overview

This test application validates the core Kubernetes deployment features of the `Radius.Compute/containers` recipe.

## Test Cases

The `app.bicep` file includes 8 test cases:

1. **Simple Container**: Single nginx container with port exposure
2. **Multi-Container**: Two containers sharing an emptyDir volume
3. **Health Probes**: Container with readiness and liveness probes
4. **Replica Scaling**: Container scaled to 3 replicas
5. **Dapr Extension**: Container with Dapr sidecar configuration
6. **Custom Metadata**: Container with custom Kubernetes labels/annotations
7. **Resource Limits**: Container with CPU/memory requests and limits
8. **Connection**: Container with connection to another container resource

## Running Tests

### Prerequisites

- Kubernetes cluster running (k3d, kind, or cloud)
- Radius installed with Kubernetes environment
- Container resource type registered

### Build and Test

```bash
# From repository root
cd Compute/containers

# Build the resource type
make build-resource-type TYPE_FOLDER=Compute/containers

# Build the recipe
make build-bicep-recipe RECIPE_PATH=Compute/containers/recipes/kubernetes/bicep/kubernetes-containers.bicep

# Run tests
make test-recipe RECIPE_PATH=Compute/containers/recipes/kubernetes/bicep/kubernetes-containers.bicep
```

### Manual Testing

```bash
# Deploy test application
rad deploy test/app.bicep -e <your-kubernetes-environment>

# Verify all pods are running
kubectl get pods -n container-test

# Check services created
kubectl get svc -n container-test

# Verify deployments
kubectl get deployments -n container-test

# Clean up
rad app delete container-test-app -e <your-kubernetes-environment>
```

## Validation Criteria

✅ All pods reach Running state  
✅ Services are created for containers with ports  
✅ Multi-container pods share volumes correctly  
✅ Health probes are configured correctly  
✅ Replica counts match specifications  
✅ Dapr annotations are applied  
✅ Custom labels and annotations are present  
✅ Resource limits are enforced  

## Detailed Validation Commands

### Test Case 1: Simple Container
```bash
# Check pod status
kubectl get pod -l app.kubernetes.io/name=simple-container -n container-test

# Verify service
kubectl get svc simple-container -n container-test

# Check environment variables
kubectl exec -n container-test $(kubectl get pod -l app.kubernetes.io/name=simple-container -o jsonpath='{.items[0].metadata.name}') -- env | grep NGINX_PORT
```

### Test Case 2: Multi-Container
```bash
# Verify both containers are running
kubectl get pod -l app.kubernetes.io/name=multi-container -n container-test -o jsonpath='{.items[0].spec.containers[*].name}'

# Check shared volume content
kubectl exec -n container-test -c frontend $(kubectl get pod -l app.kubernetes.io/name=multi-container -o jsonpath='{.items[0].metadata.name}') -- cat /usr/share/nginx/html/index.html
```

### Test Case 3: Health Probes
```bash
# Verify readiness probe
kubectl get pod -l app.kubernetes.io/name=container-probes -n container-test -o jsonpath='{.items[0].spec.containers[0].readinessProbe}'

# Verify liveness probe
kubectl get pod -l app.kubernetes.io/name=container-probes -n container-test -o jsonpath='{.items[0].spec.containers[0].livenessProbe}'
```

### Test Case 4: Replica Scaling
```bash
# Verify 3 replicas
kubectl get deployment scaled-container -n container-test -o jsonpath='{.spec.replicas}'

# Check all pods are running
kubectl get pods -l app.kubernetes.io/name=scaled-container -n container-test
```

### Test Case 5: Dapr Extension
```bash
# Check Dapr annotations
kubectl get pod -l app.kubernetes.io/name=dapr-container -n container-test -o jsonpath='{.items[0].metadata.annotations}' | jq

# Verify Dapr sidecar is injected (should see 2 containers)
kubectl get pod -l app.kubernetes.io/name=dapr-container -n container-test -o jsonpath='{.items[0].spec.containers[*].name}'
```

### Test Case 6: Custom Metadata
```bash
# Verify custom labels
kubectl get deployment container-metadata -n container-test -o jsonpath='{.metadata.labels}' | jq

# Verify custom annotations
kubectl get deployment container-metadata -n container-test -o jsonpath='{.metadata.annotations}' | jq
```

### Test Case 7: Resource Limits
```bash
# Check resource requests
kubectl get pod -l app.kubernetes.io/name=container-resources -n container-test -o jsonpath='{.items[0].spec.containers[0].resources}'
```

### Test Case 8: Connection
```bash
# Verify connection secret is created
kubectl get secret -n container-test | grep container-connection

# Check environment variables include connection info
kubectl exec -n container-test $(kubectl get pod -l app.kubernetes.io/name=container-connection -o jsonpath='{.items[0].metadata.name}') -- env | grep CONNECTION
```

## Troubleshooting

### Pods not starting
- Check image pull errors: `kubectl describe pod -n container-test <pod-name>`
- Verify resource quotas: `kubectl describe quota -n container-test`
- Check node resources: `kubectl top nodes`

### Services not accessible
- Verify port configurations: `kubectl get svc -n container-test -o yaml`
- Check service selectors match pod labels
- Test service connectivity from another pod

### Volume mounting issues
- Check volume definitions: `kubectl get pod <pod-name> -n container-test -o jsonpath='{.spec.volumes}'`
- Verify mount paths don't conflict
- Check volume mount permissions

### Dapr sidecar not injected
- Ensure Dapr is installed on the cluster: `dapr status -k`
- Verify Dapr annotations are correct
- Check Dapr control plane logs

## Notes

- This test application does NOT include any cloud provider resources (Azure/AWS)
- Tests focus purely on Kubernetes deployment capabilities
- Connection testing with actual resources (Redis) should use the external demo application
- Some tests may show warnings about type availability until the resource type is fully built
