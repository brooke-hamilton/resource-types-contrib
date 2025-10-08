# GitHub Copilot Prompt: Create Implementation Plan for Containers Resource Type Recipe

## Context

I need you to create a **detailed low-level implementation plan** for developing a new Radius recipe for the `Radius.Compute/containers` resource type. This plan should define all files to be created, their structure, and implementation details in accordance with the project's development guidelines.

## Background Materials

### Design Document
The complete design for this recipe is available at:
https://github.com/brooke-hamilton/radius-design-notes/blob/27d2f2a68e9c8353e2df826b32e4ee8539142e1c/recipe/2025-09-container.md

Key points from the design:
- Replacing the imperative Go renderer chain with a declarative Bicep recipe
- Using the Bicep Kubernetes extension (preview) to create native Kubernetes resources
- Supporting multi-container deployments, volumes, identity, RBAC, connections
- Implementing extension functionality (Dapr sidecars, manual scaling, metadata)
- Supporting three volume types: emptyDir (ephemeral), persistentVolume (PVCs), and secret volumes

### Demo Requirements
The initial version must enable the demo defined at:
https://gist.github.com/willtsai/19a6e3c6d48783f6fb9a31688bb2b2f5#october-17-2025-basic-container-app-deployment

Demo specifics:
- Deploy a simple container application (from Radius quickstart) to both AKS and ACI
- Container uses `ghcr.io/radius-project/samples/demo:latest` image
- Exposes port 3000
- Connects to a Redis cache resource
- Must work with the new `Radius.Compute/containers@2025-08-01-preview` schema

### Resource Type Schema
The resource type definition is in `/workspace/brooke-hamilton/resource-types-contrib/Compute/containers/containers.yaml`

Key schema elements:
- Namespace: `Radius.Compute`
- Resource type: `containers`
- API version: `2025-08-01-preview`
- Required properties: `environment`, `application`, `containers`
- Optional properties: `connections`, `volumes`, `restartPolicy`, `replicas`, `autoScaling`, `extensions`, `platformOptions`

### Development Guidelines
Review the following documentation files in `/workspace/brooke-hamilton/resource-types-contrib/docs/contributing/`:
- `contributing-resource-types-recipes.md` - Defines Resource Type contribution process, maturity levels (Alpha/Beta/Stable), schema guidelines, and documentation requirements
- `testing-resource-types-recipes.md` - Explains testing process using make commands

Key guidelines:
1. **Directory Structure**: Recipes must be organized under `Compute/containers/recipes/{platform}/{iac-language}/`
2. **Maturity Levels**: This contribution targets **Alpha** stage initially (single recipe, basic documentation, manual testing)
3. **Documentation**: Need two types:
   - Developer documentation (embedded in Resource Type YAML)
   - Platform engineer documentation (README.md in recipe directories)
4. **Testing**: Use `make` commands for building and testing recipes locally

## Objective

Create a **comprehensive implementation plan** that specifies:

1. **All files to be created** with complete file paths
2. **File structure and content outline** for each file
3. **Implementation sequence** and dependencies between files
4. **Testing strategy** aligned with the repository's testing guidelines

## Requirements

### Phase 1: Kubernetes Recipe (Alpha Stage - Demo Enablement)

For the initial demo, create a **Kubernetes bicep recipe** that:

1. **Supports the demo requirements**:
   - Single container deployment
   - Port exposure (containerPort: 3000)
   - Connection to Redis cache with environment variable injection
   - ClusterIP Service creation

2. **Uses Bicep Kubernetes extension** (preview):
   - Configure extension with kubeconfig parameter
   - Create native Kubernetes resources: Deployment, Service, Secret, ServiceAccount, Role, RoleBinding
   - Use proper resource type format: `{group}/{kind}@{version}` (e.g., `apps/Deployment@v1`)

3. **Implements core features**:
   - Multi-container support (iterate over `containers` map)
   - Environment variables from connections and direct values
   - Basic health probes (readiness/liveness)
   - Volume mounts (ephemeral emptyDir volumes for demo)
   - RBAC resources (Role/RoleBinding for pod/secret access)

4. **Includes extension support**:
   - Dapr sidecar (via `extensions.daprSidecar` object)
   - Manual scaling (via `replicas` property)
   - Kubernetes metadata (via `platformOptions.kubernetes.metadata`)

5. **Follows repository conventions**:
   - Place recipe in `Compute/containers/recipes/kubernetes/bicep/`
   - Include parameter file (`kubernetes-containers.bicep.params`)
   - Create README.md with platform engineer documentation
   - Provide test application in `test/` directory

6. **Includes test application** (`Compute/containers/test/app.bicep`):
   - Tests core Kubernetes deployment features of the recipe
   - Deploys a container with basic configuration (image, port, environment variables)
   - Tests multi-container support if applicable
   - Tests volume mounts (emptyDir only for Alpha stage)
   - Tests connection to another resource (e.g., Redis) with environment variable injection
   - **MUST NOT** include non-Kubernetes features (no Azure-specific resources, no cloud provider dependencies)
   - **MUST** be deployable to any Kubernetes cluster using the recipe
   - Focuses purely on validating the recipe's ability to deploy containers to Kubernetes

### Phase 2: Additional Features (Post-Demo)

Plan for future implementation (not required for initial demo):
- Persistent volume mounting (from `Radius.Compute/persistentVolumes` resources)
- Secret volume mounting (from `Radius.Security/secrets` resources)
- Auto-scaling configuration
- Identity integration (Azure workload identity)
- Base manifest merging capabilities

## Deliverable Structure

Please organize your implementation plan with the following sections:

### 1. File Inventory
List every file to be created with:
- Full file path
- Purpose/description
- Dependencies on other files

**Required files:**
- Recipe implementation: `Compute/containers/recipes/kubernetes/bicep/kubernetes-containers.bicep`
- Recipe parameters: `Compute/containers/recipes/kubernetes/bicep/kubernetes-containers.bicep.params`
- Recipe README: `Compute/containers/recipes/kubernetes/bicep/README.md`
- Test application: `Compute/containers/test/app.bicep`
- Test README (optional): `Compute/containers/test/README.md`

### 2. Implementation Details per File

For each file, provide:

#### A. Purpose and Scope
- What functionality this file implements
- How it fits into the overall architecture

#### B. Key Implementation Challenges
- Technical complexity areas
- Design decisions needed
- Bicep/Kubernetes extension limitations to address

#### C. Content Structure
- High-level outline of file contents
- Key sections/resources to include
- Parameter definitions and data structures

#### D. Recipe Parameters (for Bicep recipe files)
- Input parameters from Resource Type schema
- How they map to Kubernetes resources
- Example values for demo scenario

#### E. Resource Generation Logic (for Bicep recipe files)
- Kubernetes resources to create
- Conditional resource creation logic
- Resource dependencies and ordering

### 3. Implementation Sequence
- Order in which files should be created
- Validation checkpoints between steps
- How to test each component incrementally

### 4. Testing Strategy
Detail how to test the implementation:
- Local testing with `make` commands
- Test application (`test/app.bicep`) deployment and validation
- Demo application deployment (external demo from gist)
- Validation criteria for success
- Commands to verify Kubernetes resources are created correctly (kubectl commands)
- Verification that test app focuses only on Kubernetes features (no cloud provider dependencies)

### 5. Documentation Requirements
- Developer documentation to add to `containers.yaml`
- Platform engineer README content
- Usage examples for the demo scenario

### 6. Known Limitations and Future Work
- Features not included in Phase 1
- Technical debt or workarounds
- Path to Beta and Stable maturity levels

## Constraints and Considerations

1. **Alpha Stage Focus**: Prioritize working demo over comprehensive feature set
2. **Kubernetes Only**: Initial recipe is Kubernetes-only (ACI comes later)
3. **Bicep Only**: Start with Bicep recipe (Terraform variant comes later for Beta)
4. **Extension Preview**: Be aware Bicep Kubernetes extension is in preview
5. **Volume Limitations**: For demo, focus on ephemeral emptyDir volumes only
6. **Repository Standards**: Follow exact directory structure and naming conventions from guidelines

## Success Criteria

The plan is successful if it enables a developer to:
1. Create all necessary files from your specifications
2. Build the recipe using `make build-bicep-recipe RECIPE_PATH=Compute/containers/recipes/kubernetes/bicep`
3. Test the recipe with `make test-recipe RECIPE_PATH=Compute/containers/recipes/kubernetes/bicep` (uses test/app.bicep)
4. Verify test app.bicep only tests Kubernetes features (no Azure/AWS resources)
5. Deploy the external demo application successfully with `rad run`
6. Access the running container and verify Redis connection works
7. Validate all Kubernetes resources (Deployment, Service, Secret, RBAC) are created correctly

## Output Format

Please structure your response as a detailed technical specification document with:
- Clear section headings
- Numbered lists for sequences
- Code blocks for file content outlines
- Tables where helpful for comparing options

Focus on being **specific and actionable** - a developer should be able to implement this plan without needing to make significant design decisions.

## Additional Context

- Current working directory structure available in `/workspace/brooke-hamilton/resource-types-contrib/`
- Existing recipe examples: `Data/mySqlDatabases/recipes/kubernetes/bicep/` and `Security/secrets/recipes/kubernetes/bicep/`
- Resource Type already defined in `Compute/containers/containers.yaml`
- Build system uses Makefile with standardized commands
- Bicep extension packaging creates `.tgz` files and updates `bicepconfig.json`
