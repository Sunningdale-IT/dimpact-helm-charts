# PodiumD Helmfile Deployment

This directory contains a **Helmfile-based deployment solution** that replaces the monolithic `podiumd` Helm chart to resolve Kubernetes Secret size limitations while maintaining full platform functionality.

## 🚀 Quick Start

### Prerequisites

1. **Helm** (v3.8+)
2. **Helmfile** (v0.169.1+)
3. **kubectl** configured for your cluster

### Install Helmfile

```bash
# Install helmfile
curl -L https://github.com/helmfile/helmfile/releases/download/v0.169.1/helmfile_0.169.1_linux_amd64.tar.gz | tar -xzf -
sudo mv helmfile /usr/local/bin/
helmfile version
```

### Deploy PodiumD Platform

```bash
# Deploy to development environment
helmfile -e development sync

# Deploy to production environment  
helmfile -e production sync

# Deploy with custom namespace
helmfile -e development --set namespace=podiumd-custom sync
```

## 📋 Architecture Overview

The PodiumD platform is decomposed into **logical tiers** deployed as separate Helm releases:

### 🏗️ Infrastructure Tier (Core Services)
- **Keycloak** - Identity and Access Management
- **ClamAV** - Antivirus Scanning
- **Infinispan** - Distributed Caching

### ⚖️ Case Management Tier
- **Open Zaak** - Case Management API
- **Open Notificaties** - Notification Services  
- **ZAC** - Case Handling Component

### 📋 Objects & Data Tier
- **Objecten** - Generic Objects API
- **Objecttypen** - Object Types API
- **Open Archiefbeheer** - Archive Management
- **Open Klant** - Customer Management

### 🌐 Forms & Portal Tier
- **Open Formulieren** - Form Builder & Renderer
- **Open Inwoner** - Citizen Portal

### 📞 Contact Management Tier
- **KISS Elastic** - Contact Management System

### 🧪 Testing/Mock Tier
- **BRP Personen Mock** - Mock Person Registry

## 🎯 Problem Solved

**Issue**: The original monolithic `podiumd` chart created a Kubernetes Secret exceeding the 1MB limit:
```
Error: INSTALLATION FAILED: create: failed to create: Secret "sh.helm.release.v1.podiumd.v1" is invalid: data: Too long: may not be more than 1048576 bytes
```

**Solution**: Split into **14 separate Helm releases** with dependency management, staying well under the Secret size limit per release.

## 📁 Directory Structure

```
helmfile/
├── environments/          # Environment-specific configurations
│   ├── default.yaml      # Base configuration values
│   ├── development.yaml  # Development overrides
│   └── production.yaml   # Production overrides
└── values/               # Component-specific value templates
    ├── keycloak.yaml.gotmpl         # Keycloak configuration
    ├── openzaak.yaml.gotmpl         # Open Zaak configuration
    ├── opennotificaties.yaml.gotmpl # Open Notificaties configuration
    ├── clamav.yaml.gotmpl           # ClamAV configuration
    └── ... (other components)
```

## 🔧 Configuration

### Environment Configuration

Each environment has its own configuration file:

- **`default.yaml`** - Base configuration shared across environments
- **`development.yaml`** - Development-specific overrides
- **`production.yaml`** - Production-specific settings

### Component Templates

Value templates use Go templating to inject environment-specific values:

```yaml
# Example from keycloak.yaml.gotmpl
auth:
  adminPassword: {{ .Values.global.configuration.openzaakNotificatiesSecret | quote }}
ingress:
  hostname: {{ .Values.global.configuration.keycloakHostname | default "keycloak.example.com" }}
```

### Dependency Management

Components are deployed in dependency order:

1. **Infrastructure Tier** (Keycloak, ClamAV, Infinispan)
2. **Core APIs** (Open Zaak, Open Notificaties) 
3. **Data Services** (Objecten, Objecttypen, etc.)
4. **User-Facing Apps** (Open Formulieren, Open Inwoner)
5. **Specialized Components** (ZAC, KISS)

## 🚀 Deployment Commands

### Basic Operations

```bash
# List all environments
helmfile list

# Preview changes (dry-run)
helmfile -e development diff

# Deploy all components
helmfile -e development sync

# Deploy specific components
helmfile -e development -l tier=infrastructure sync
helmfile -e development -l name=keycloak sync

# Destroy deployment
helmfile -e development destroy
```

### Advanced Operations

```bash
# Template rendering (for debugging)
helmfile -e development template

# Update dependencies
helmfile -e development deps

# Validate configuration
helmfile -e development lint

# Monitor deployment status
watch kubectl get pods -n podiumd
```

## 🔍 Troubleshooting

### Common Issues

**1. Repository Not Found**
```bash
# Add missing repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add maykinmedia https://maykinmedia.github.io/charts
helm repo update
```

**2. Dependency Timeout**
```bash
# Increase timeout for large components
helmfile -e development --timeout 900 sync
```

**3. Failed Component**
```bash
# Check specific component status
kubectl describe pod -l app.kubernetes.io/name=keycloak -n podiumd

# Retry failed component
helmfile -e development -l name=keycloak sync
```

### Debugging Templates

```bash
# Debug template rendering
helmfile -e development template > /tmp/rendered.yaml
kubectl apply --dry-run=client -f /tmp/rendered.yaml
```

## 🔄 Migration from Monolithic Chart

### Migration Steps

1. **Backup existing deployment**:
   ```bash
   helm get values podiumd > podiumd-backup.yaml
   kubectl get secrets -o yaml > secrets-backup.yaml
   ```

2. **Uninstall monolithic chart**:
   ```bash
   helm uninstall podiumd
   ```

3. **Deploy with Helmfile**:
   ```bash
   helmfile -e development sync
   ```

4. **Verify migration**:
   ```bash
   kubectl get pods -n podiumd
   kubectl get services -n podiumd
   ```

### Configuration Mapping

| Original Section | New Location |
|------------------|--------------|
| `values.yaml#keycloak` | `helmfile/values/keycloak.yaml.gotmpl` |
| `values.yaml#openzaak` | `helmfile/values/openzaak.yaml.gotmpl` |
| `values.yaml#global` | `helmfile/environments/{env}.yaml` |

## 🚀 Alternative Deployment Solutions

While Helmfile is the recommended solution, here are other approaches to solve the Secret size issue:

### 1. 🔄 ArgoCD Application Sets (GitOps)

**Best for**: GitOps workflows, automated deployments

```yaml
# argocd-appset.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: podiumd
spec:
  generators:
  - list:
      elements:
      - name: keycloak
        chart: bitnami/keycloak
        version: 24.8.0
      - name: openzaak  
        chart: maykinmedia/openzaak
        version: 1.9.0
  template:
    metadata:
      name: 'podiumd-{{name}}'
    spec:
      source:
        repoURL: https://charts.example.com
        chart: '{{chart}}'
        targetRevision: '{{version}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: podiumd
```

**Pros**: 
- GitOps native
- Automatic sync and rollback
- UI for deployment management
- Multi-cluster support

**Cons**:
- Requires ArgoCD installation
- Learning curve for ArgoCD concepts

### 2. 🌊 Flux Helm Controller (GitOps)

**Best for**: Flux-based GitOps workflows

```yaml
# flux-helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: podiumd-keycloak
spec:
  chart:
    spec:
      chart: keycloak
      version: 24.8.0
      sourceRef:
        kind: HelmRepository
        name: bitnami
  values:
    auth:
      adminPassword: "secret"
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1  
kind: HelmRelease
metadata:
  name: podiumd-openzaak
spec:
  dependsOn:
    - name: podiumd-keycloak
  chart:
    spec:
      chart: openzaak
      version: 1.9.0
      sourceRef:
        kind: HelmRepository
        name: maykinmedia
```

**Pros**:
- Native Kubernetes CRDs
- Automatic dependency management
- Built-in monitoring and alerting

**Cons**:
- Requires Flux installation
- YAML-heavy configuration

### 3. 🏗️ Terraform Helm Provider (Infrastructure as Code)

**Best for**: Infrastructure teams using Terraform

```hcl
# terraform/main.tf
resource "helm_release" "keycloak" {
  name       = "keycloak"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"
  version    = "24.8.0"
  
  values = [
    file("${path.module}/values/keycloak.yaml")
  ]
}

resource "helm_release" "openzaak" {
  name       = "openzaak"  
  repository = "https://maykinmedia.github.io/charts"
  chart      = "openzaak"
  version    = "1.9.0"
  
  depends_on = [helm_release.keycloak]
  
  values = [
    file("${path.module}/values/openzaak.yaml")
  ]
}
```

**Pros**:
- Infrastructure as Code
- State management
- Provider ecosystem integration
- Plan/apply workflow

**Cons**:
- Requires Terraform knowledge
- State file management complexity

### 4. 📜 Custom Shell Scripts (Simple)

**Best for**: Simple deployments, CI/CD pipelines

```bash
#!/bin/bash
# deploy-podiumd.sh

set -e

NAMESPACE=${NAMESPACE:-podiumd}
ENVIRONMENT=${ENVIRONMENT:-development}

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Deploy infrastructure tier
echo "🏗️ Deploying infrastructure tier..."
helm upgrade --install keycloak bitnami/keycloak \
  --namespace $NAMESPACE \
  --values values/keycloak-$ENVIRONMENT.yaml \
  --wait --timeout 10m

helm upgrade --install clamav wiremind/clamav \
  --namespace $NAMESPACE \
  --values values/clamav-$ENVIRONMENT.yaml \
  --wait --timeout 5m

# Deploy case management tier
echo "⚖️ Deploying case management tier..."
helm upgrade --install openzaak maykinmedia/openzaak \
  --namespace $NAMESPACE \
  --values values/openzaak-$ENVIRONMENT.yaml \
  --wait --timeout 10m

# Continue with other components...
```

**Pros**:
- Simple and straightforward
- Easy to customize
- No additional tools required
- Works in any CI/CD system

**Cons**:
- Manual dependency management
- Limited rollback capabilities
- No built-in templating

### 5. 🏷️ Helm Umbrella Chart with Sub-Charts

**Best for**: Teams wanting to stay with pure Helm

```yaml
# Chart.yaml
dependencies:
  - name: keycloak
    version: 24.8.0
    repository: https://charts.bitnami.com/bitnami
    condition: keycloak.enabled
  - name: openzaak
    version: 1.9.0  
    repository: https://maykinmedia.github.io/charts
    condition: openzaak.enabled
    tags:
      - backend
```

**Pros**:
- Pure Helm solution
- Familiar tooling
- Single installation command

**Cons**:
- Still creates large secrets (doesn't solve the original issue)
- Complex values.yaml files

## 📊 Comparison Matrix

| Solution | GitOps | Complexity | Secret Size | Learning Curve | Maintenance |
|----------|--------|------------|-------------|----------------|-------------|
| **Helmfile** ⭐ | ❌ | Low | ✅ Small | Low | Low |
| ArgoCD AppSets | ✅ | Medium | ✅ Small | Medium | Medium |
| Flux HelmRelease | ✅ | Medium | ✅ Small | Medium | Medium |
| Terraform | ❌ | High | ✅ Small | High | High |
| Shell Scripts | ❌ | Low | ✅ Small | Low | Medium |
| Umbrella Chart | ❌ | Low | ❌ Large | Low | Low |

## 🎯 Recommendation

**Helmfile** is the recommended solution because it:

✅ **Solves the Secret size issue** - Each component gets its own release
✅ **Maintains simplicity** - Familiar Helm-based workflow  
✅ **Provides templating** - Environment-specific configurations
✅ **Manages dependencies** - Proper deployment ordering
✅ **Requires minimal infrastructure** - No additional operators needed
✅ **Easy migration** - Gradual transition from monolithic chart

## 📚 Additional Resources

- [Helmfile Documentation](https://helmfile.readthedocs.io/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes Secrets Limitations](https://kubernetes.io/docs/concepts/configuration/secret/#restrictions)
- [PodiumD Architecture Documentation](../docs/podiumd/)

## 🔧 Contributing

When adding new components or modifying configurations:

1. Update the relevant environment files
2. Create/modify component value templates
3. Test with `helmfile diff` before applying
4. Update this README with any new procedures
5. Document breaking changes and migration steps

---

*This solution successfully resolves the Kubernetes Secret size limitation while maintaining the complete PodiumD platform functionality through a well-architected, maintainable deployment approach.*