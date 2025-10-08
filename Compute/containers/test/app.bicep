extension radius
extension containers

@description('The Radius environment ID')
param environment string

// Create test application
resource app 'Applications.Core/applications@2023-10-01-preview' = {
  name: 'container-test-app'
  location: 'global'
  properties: {
    environment: environment
    extensions: [
      {
        kind: 'kubernetesNamespace'
        namespace: 'container-test'
      }
    ]
  }
}

// Test Case 1: Simple single container with port
resource simpleContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'simple-container'
  properties: {
    application: app.id
    environment: environment
    containers: {
      nginx: {
        image: 'nginx:alpine'
        ports: {
          http: {
            containerPort: 80
          }
        }
        env: {
          NGINX_PORT: {
            value: '80'
          }
        }
      }
    }
  }
}

// Output for validation
output simpleContainerName string = simpleContainer.name
