// ===== SECTION 1: PARAMETER DEFINITIONS =====
@description('Radius context with resource metadata and runtime info')
param context object

// ===== SECTION 2: KUBERNETES EXTENSION CONFIGURATION =====
extension kubernetes with {
  kubeConfig: ''
  namespace: context.runtime.kubernetes.namespace
} as kubernetes

// ===== SECTION 3: VARIABLE DECLARATIONS =====

// Extract resource properties
var containers = context.resource.properties.containers          // Required: map of container specs
var connections = context.resource.properties.?connections ?? {} // Optional: resource connections
var volumes = context.resource.properties.?volumes ?? {}         // Optional: volume definitions
var replicas = context.resource.properties.?replicas ?? 1        // Optional: replica count
var extensions = context.resource.properties.?extensions ?? {}   // Optional: extensions object
var platformOptions = context.resource.properties.?platformOptions ?? {} // Optional: platform config

// Extract context metadata
var resourceName = context.resource.name
var applicationName = context.application.name
var namespace = context.runtime.kubernetes.namespace

// Common labels for all resources
var commonLabels = {
  'app.kubernetes.io/name': resourceName
  'app.kubernetes.io/part-of': applicationName
  'app.kubernetes.io/managed-by': 'radius'
  'radapp.io/application': applicationName
  'radapp.io/resource': resourceName
}

// Selector labels (subset of common labels for matching)
var selectorLabels = {
  'app.kubernetes.io/name': resourceName
  'radapp.io/application': applicationName
}

// Custom labels and annotations from platformOptions
var customLabels = platformOptions.?kubernetes.?metadata.?labels ?? {}
var customAnnotations = platformOptions.?kubernetes.?metadata.?annotations ?? {}

// Dapr extension support
var daprEnabled = contains(extensions, 'daprSidecar')
var daprLabels = daprEnabled ? {
  'dapr.io/enabled': 'true'
} : {}
var daprAnnotations = daprEnabled ? {
  'dapr.io/enabled': 'true'
  'dapr.io/app-id': extensions.daprSidecar.?appId ?? resourceName
  'dapr.io/app-port': string(extensions.daprSidecar.?appPort ?? 80)
  'dapr.io/config': extensions.daprSidecar.?config ?? ''
} : {}

// Connection support
var hasConnections = length(connections) > 0

// Check if any container has ports - simplified check
var containersList = items(containers)
var hasPorts = length(containersList) > 0 && containersList[0].value.?ports != null

// Build service ports array - use first container's first port as a simple implementation
var firstContainerPorts = containersList[0].value.?ports ?? {}
var servicePorts = [for p in items(firstContainerPorts): {
  name: p.key
  port: p.value.containerPort
  targetPort: p.value.containerPort
  protocol: p.value.?protocol ?? 'TCP'
}]

// ===== SECTION 4: KUBERNETES RESOURCES =====

// 4.1 ServiceAccount
resource serviceAccount 'core/ServiceAccount@v1' = {
  metadata: {
    name: resourceName
    namespace: namespace
    labels: commonLabels
  }
}

// 4.2 Role (RBAC)
resource role 'rbac.authorization.k8s.io/Role@v1' = {
  metadata: {
    name: resourceName
    namespace: namespace
    labels: commonLabels
  }
  rules: [
    {
      apiGroups: ['']
      resources: ['pods', 'services', 'secrets']
      verbs: ['get', 'list', 'watch']
    }
  ]
}

// 4.3 RoleBinding (RBAC)
resource roleBinding 'rbac.authorization.k8s.io/RoleBinding@v1' = {
  metadata: {
    name: resourceName
    namespace: namespace
    labels: commonLabels
  }
  subjects: [
    {
      kind: 'ServiceAccount'
      name: serviceAccount.metadata.name
      namespace: namespace
    }
  ]
  roleRef: {
    kind: 'Role'
    name: role.metadata.name
    apiGroup: 'rbac.authorization.k8s.io'
  }
}

// 4.4 Secret (Conditional - only if connections exist)
resource connectionSecret 'core/Secret@v1' = if (hasConnections) {
  metadata: {
    name: '${resourceName}-connection-secret'
    namespace: namespace
    labels: commonLabels
  }
  type: 'Opaque'
  stringData: {
    // Connection environment variables injected by Radius
    // Actual implementation will have connection values from context at deployment time
    // Format expected: CONNECTION_<RESOURCE>_<PROPERTY>=<value>
    'connection-data': 'placeholder-for-radius-injected-connections'
  }
}

// 4.5 Deployment
resource deployment 'apps/Deployment@v1' = {
  metadata: {
    name: resourceName
    namespace: namespace
    labels: union(commonLabels, customLabels, daprLabels)
    annotations: union(customAnnotations, daprAnnotations)
  }
  spec: {
    replicas: replicas
    selector: {
      matchLabels: selectorLabels
    }
    template: {
      metadata: {
        labels: union(commonLabels, customLabels, daprLabels)
        annotations: union(customAnnotations, daprAnnotations)
      }
      spec: {
        serviceAccountName: serviceAccount.metadata.name
        containers: [for containerName in items(containers): union({
          name: containerName.key
          image: containerName.value.image
          env: hasConnections ? [{
            name: 'CONNECTION_INFO'
            valueFrom: {
              secretKeyRef: {
                name: '${resourceName}-connection-secret'
                key: 'connection-data'
              }
            }
          }] : []
          resources: {
            requests: {
              cpu: containerName.value.?resources.?requests.?cpu ?? '100m'
              memory: containerName.value.?resources.?requests.?memoryInMib != null 
                ? '${containerName.value.resources.requests.memoryInMib}Mi' 
                : '128Mi'
            }
            limits: {
              cpu: containerName.value.?resources.?limits.?cpu ?? '500m'
              memory: containerName.value.?resources.?limits.?memoryInMib != null 
                ? '${containerName.value.resources.limits.memoryInMib}Mi' 
                : '512Mi'
            }
          }
        }, 
        containerName.value.?command != null ? { command: containerName.value.command } : {},
        containerName.value.?args != null ? { args: containerName.value.args } : {},
        containerName.value.?readinessProbe != null ? { readinessProbe: containerName.value.readinessProbe } : {},
        containerName.value.?livenessProbe != null ? { livenessProbe: containerName.value.livenessProbe } : {}
        )]
        volumes: [for v in items(volumes): {
          name: v.key
          emptyDir: v.value.?emptyDir ?? {}
        }]
      }
    }
  }
}

// 4.6 Service (Conditional - only if ports are defined)
resource service 'core/Service@v1' = if (hasPorts) {
  metadata: {
    name: resourceName
    namespace: namespace
    labels: commonLabels
  }
  spec: {
    type: 'ClusterIP'
    selector: selectorLabels
    ports: servicePorts
  }
}

// ===== SECTION 5: OUTPUTS =====

// Simplified port selection logic for outputs
var firstContainer = items(containers)[0]
var firstContainerPortsForOutput = items(firstContainer.value.?ports ?? {})
var hasAnyPorts = length(firstContainerPortsForOutput) > 0
var firstPortNumber = hasAnyPorts ? firstContainerPortsForOutput[0].value.containerPort : 0

output result object = {
  resources: [
    '/planes/kubernetes/local/namespaces/${namespace}/providers/core/Service/${resourceName}'
    '/planes/kubernetes/local/namespaces/${namespace}/providers/apps/Deployment/${resourceName}'
  ]
  values: {
    host: hasPorts ? '${resourceName}.${namespace}.svc.cluster.local' : ''
    port: hasPorts ? string(firstPortNumber) : ''
  }
  secrets: {}
}
