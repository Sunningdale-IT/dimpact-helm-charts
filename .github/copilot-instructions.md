# Dimpact Helm Charts Repository

This repository contains Helm charts for the Dutch government Dimpact organization's PodiumD platform, providing municipal digital services including Open Zaak, Open Formulieren, Open Inwoner, KISS (contact management), and related components.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Basic Validation
- Ensure Helm is installed: `helm version` (requires v3.x+)
- **CRITICAL**: Bootstrap complete environment by running the repository setup commands below
- Lint podiumd chart: `helm lint charts/podiumd` -- primary chart of interest 
- Template podiumd chart: `helm template test charts/podiumd --dry-run` -- verify podiumd templates

### Complete Repository Setup (ALWAYS RUN FIRST)
**NEVER CANCEL these commands - they complete in under 2 minutes total:**

```bash
# Step 1: Navigate to repository root (5 seconds)
cd /home/runner/work/dimpact-helm-charts/dimpact-helm-charts

# Step 2: Add ALL required repositories (30-45 seconds total - NEVER CANCEL)
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add maykinmedia https://maykinmedia.github.io/charts
helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
helm repo add dimpact https://Dimpact-Samenwerking.github.io/helm-charts
helm repo add elastic https://helm.elastic.co
helm repo add kiss-frontend https://raw.githubusercontent.com/Klantinteractie-Servicesysteem/KISS-frontend/main/helm
helm repo add kiss-adapter https://raw.githubusercontent.com/ICATT-Menselijk-Digitaal/podiumd-adapter/main/helm
helm repo add kiss-elastic https://raw.githubusercontent.com/Klantinteractie-Servicesysteem/.github/main/docs/scripts/elastic
helm repo add zac https://infonl.github.io/dimpact-zaakafhandelcomponent/
helm repo add openshift https://charts.openshift.io
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Step 3: Update repositories (15-30 seconds - NEVER CANCEL)
helm repo update

# Step 4: Update podiumd dependencies (30-60 seconds - NEVER CANCEL)
helm dependency update charts/podiumd
```

### Working with External Dependencies
- External Helm repositories are accessible and can be added using `helm repo add` commands
- The podiumd chart has many external dependencies that can now be resolved with network access
- External repos that are available include:
  - `https://charts.bitnami.com/bitnami` (Bitnami charts)
  - `https://maykinmedia.github.io/charts` (Maykin Media charts)
  - And all other external chart repositories listed in workflows

### Chart Structure and Components

#### Main Chart of Interest:
- **podiumd**: Main comprehensive platform chart (COMPLEX - has 13+ external dependencies) ⚠️ 

#### Other Charts (Reference Only):
- **kiss**: Contact management system (Klantinteractie-Servicesysteem)
- **brp-personen-mock**: BRP (Dutch population register) mock service
- **monitoring-logging**: Monitoring and logging stack
- **vngreferentielijsten**: VNG reference lists
- **beproeving**: Development/testing chart
- **flowable-rest**, **flowable-ui**: Flowable workflow components

#### Chart Validation Commands:
```bash
# Primary focus: podiumd chart
helm lint charts/podiumd                               # ⚠️ May have template errors, complex dependencies
helm template test charts/podiumd --dry-run            # ⚠️ May have template errors
helm dependency update charts/podiumd                  # ✅ Works - can reach external repos

# Dependency management for podiumd:
helm dependency update charts/podiumd                  # Download external dependencies
helm dependency list charts/podiumd                    # List current dependencies
```

### GitHub Workflows and CI/CD
- **release.yaml**: Main release workflow that publishes charts to GitHub Pages
- **release-test.yaml**: Manual release workflow with changelog generation
- **trivy-vuln-scanner.yaml**: Security vulnerability scanning workflow
- **podiumd-test-podiumd-helm-chart-changes.yaml**: Tests podiumd chart changes

### Required Helm Repositories
These repositories can now be added and are accessible:
```bash
# These commands now work and are needed for full functionality:
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add maykinmedia https://maykinmedia.github.io/charts
helm repo add wiremind https://wiremind.github.io/wiremind-helm-charts
helm repo add dimpact https://Dimpact-Samenwerking.github.io/helm-charts
helm repo add elastic https://helm.elastic.co
helm repo add kiss-frontend https://raw.githubusercontent.com/Klantinteractie-Servicesysteem/KISS-frontend/main/helm
helm repo add kiss-adapter https://raw.githubusercontent.com/ICATT-Menselijk-Digitaal/podiumd-adapter/main/helm
helm repo add kiss-elastic https://raw.githubusercontent.com/Klantinteractie-Servicesysteem/.github/main/docs/scripts/elastic
helm repo add zac https://infonl.github.io/dimpact-zaakafhandelcomponent/
helm repo add openshift https://charts.openshift.io
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add zgw-office-addin https://infonl.github.io/zgw-office-addin
```

## Validation Scenarios

### ALWAYS Test These After Making Changes to podiumd:
1. **Chart Linting**: `helm lint charts/podiumd` -- verify no linting errors
2. **Template Generation**: `helm template test charts/podiumd --dry-run` -- verify valid Kubernetes YAML
3. **Syntax Validation**: Check YAML files are valid using your editor's syntax highlighting

### DO NOT Test These (may still have template errors):
- Charts with known template issues (vngreferentielijsten)
- Other charts not currently of interest

## Common Tasks

### Repo Root Structure
```
/home/runner/work/dimpact-helm-charts/dimpact-helm-charts/
├── .github/
│   ├── workflows/         # CI/CD workflows
│   └── CODEOWNERS        # Code ownership definitions
├── charts/               # Helm charts directory
│   ├── podiumd/         # Main platform chart (PRIMARY FOCUS)
│   ├── kiss/            # Contact management (reference only)
│   ├── brp-personen-mock/ # (reference only)
│   ├── monitoring-logging/ # (reference only)
│   └── vngreferentielijsten/ # (reference only)
├── docs/                # Documentation
│   └── podiumd/        # PodiumD specific docs
├── .gitignore
├── README.md
└── renovate.json        # Dependency updates configuration
```

### Key Files to Understand:
- `charts/podiumd/Chart.yaml`: Chart metadata and dependencies (MAIN FOCUS)
- `charts/podiumd/values.yaml`: Default configuration values (MAIN FOCUS)
- `charts/podiumd/README.md`: Chart-specific documentation
- `.github/workflows/*.yaml`: CI/CD pipeline definitions

### Important Development Notes:
- **PodiumD Platform**: Comprehensive suite including Open Zaak, Open Formulieren, Open Inwoner, Keycloak, ClamAV, etc.
- **Dutch Government Context**: This is for Dutch municipal digital services (gemeentelijke dienstverlening)
- **Chart Dependencies**: Most complex charts depend on external Helm repositories
- **Version Management**: Charts use semantic versioning and are released via GitHub Actions

### When Making Changes:
1. **ALWAYS** lint the podiumd chart after changes: `helm lint charts/podiumd`
2. **ALWAYS** test template generation: `helm template test charts/podiumd --dry-run`
3. **Add external repositories first** for podiumd dependencies: `helm repo add bitnami https://charts.bitnami.com/bitnami`
4. Check Chart.yaml version numbers are consistent
5. Update README.md if adding new parameters or changing behavior
6. **Update dependencies** for podiumd: `helm dependency update charts/podiumd`
7. **Test with dependencies** for charts that reference external repositories

### Validation Checklist for podiumd Chart Changes:
**NEVER CANCEL these commands - complete sequence takes < 2 minutes:**

```bash
# Step 1: Lint the podiumd chart (< 5 seconds)
helm lint charts/podiumd

# Step 2: Generate templates to check for YAML validity (< 10 seconds)
helm template test charts/podiumd --dry-run

# Step 3: If template generation fails, debug with verbose output (< 10 seconds)
helm template test charts/podiumd --dry-run --debug

# Step 4: Check output makes sense for working charts (< 5 seconds)
helm template test charts/kiss --dry-run | head -20

# Step 5: Verify values.yaml changes work with working chart (< 5 seconds)
helm template test charts/kiss --dry-run --set replicaCount=2

# Step 6: Update dependencies if Chart.yaml changed (30-60 seconds - NEVER CANCEL)
helm dependency update charts/podiumd
```

### Troubleshooting Common Issues:
- **"nil pointer evaluating"**: Missing required values in values.yaml - check template requirements
- **"missing dependencies"**: Run `helm dependency update charts/podiumd` (30-60s - NEVER CANCEL)
- **"template errors"**: Usually means values.yaml doesn't match template expectations
- **"repository not found"**: Run the complete repository setup commands above
- **Icon warnings**: Cosmetic only - add "icon:" field to Chart.yaml if desired
- **"Valid .Values.zacInternalEndpointsApiKey entry required!"**: Known issue with podiumd template generation - this is expected

### Common Issues and Solutions:
- **"nil pointer evaluating"**: Missing required values in values.yaml - check template requirements
- **"missing dependencies"**: Run `helm dependency update charts/podiumd` (30-60s - NEVER CANCEL)
- **"template errors"**: Usually means values.yaml doesn't match template expectations
- **"repository not found"**: Run the complete repository setup commands above
- **Icon warnings**: Cosmetic only - add "icon:" field to Chart.yaml if desired
- **"Valid .Values.zacInternalEndpointsApiKey entry required!"**: Known issue with podiumd template generation - this is expected

### Timing Expectations:
- **Repository setup**: 2 minutes total - NEVER CANCEL
- **Chart linting**: < 5 seconds per chart
- **Template generation**: < 5 seconds per chart (when working)
- **Dependency updates**: 30-60 seconds for podiumd - NEVER CANCEL
- **Helm repo add**: < 5 seconds per repo
- **Helm repo update**: 15-30 seconds total - NEVER CANCEL
- **Full CI workflow**: 2-5 minutes when external repos work
- **CRITICAL**: Set bash timeouts to minimum 120 seconds for any helm command
- **NEVER CANCEL** any operations - they complete quickly in this repository

### Known Working vs Problematic Charts:
**✅ WORKING CHARTS** (fully validated):
- **kiss**: Contact management - lints and templates successfully
- **brp-personen-mock**: BRP mock service - lints and templates successfully

**⚠️ PARTIALLY WORKING CHARTS**:
- **podiumd**: Main chart - lints successfully but templates may fail due to missing required values like `zacInternalEndpointsApiKey`

**❌ PROBLEMATIC CHARTS** (DO NOT test):
- **vngreferentielijsten**: Has template errors (nil pointer evaluating .Values.database.password)

### Complete Validation Workflow (Post-Changes):
**Run this complete sequence after making ANY changes - NEVER CANCEL any command:**

```bash
# Pre-validation setup (if not done already) - 2 minutes total
cd /home/runner/work/dimpact-helm-charts/dimpact-helm-charts
helm repo update  # 15-30 seconds
helm dependency update charts/podiumd  # 30-60 seconds

# Validation sequence - 30 seconds total
helm lint charts/podiumd  # < 5 seconds - should show 0 failed
helm lint charts/kiss  # < 5 seconds - verify other charts still work
helm template test charts/kiss --dry-run | head -10  # < 5 seconds - verify working chart still works

# Advanced validation (if podiumd template errors occur)
helm template test charts/podiumd --dry-run --debug  # < 10 seconds - shows detailed error info
```

### Manual Testing Scenarios:
**After making changes to charts, ALWAYS test these scenarios:**

1. **Chart Structure Validation**:
   ```bash
   # Verify Chart.yaml is valid (< 5 seconds)
   helm show chart charts/podiumd
   
   # Check dependencies are properly listed (< 5 seconds)
   helm dependency list charts/podiumd
   ```

2. **Template Output Validation**:
   ```bash
   # For working charts, verify they generate valid Kubernetes YAML (< 5 seconds)
   helm template test charts/kiss --dry-run | grep "apiVersion:"
   
   # Count generated resources to ensure nothing was broken (< 5 seconds)
   helm template test charts/kiss --dry-run | grep -c "^---"
   ```

3. **Dependency Resolution Testing**:
   ```bash
   # Test that external dependencies can be resolved (30-60 seconds - NEVER CANCEL)
   rm -rf charts/podiumd/charts/*  # Remove cached deps
   helm dependency update charts/podiumd  # Should re-download successfully
   ```

### Architecture Context:
PodiumD is a platform providing:
- **Forms**: Open Formulieren (form builder and renderer)
- **Portal**: Open Inwoner (citizen portal)
- **Contact**: KISS (contact management system)
- **Cases**: ZAC + Open Zaak (case management)
- **Archive**: Open Archiefbeheer (archive management)
- **Identity**: Keycloak (authentication/authorization)
- **Security**: ClamAV (antivirus scanning)

### Package and Push Scripts
Use the provided scripts for advanced operations:

```bash
# Package and validate charts using the utility script (30-60 seconds - NEVER CANCEL)
./scripts/package-and-push.sh --chart podiumd

# Test the packaging script functionality (< 30 seconds)
./scripts/test-package-and-push.sh
```

### Complete Working Session Example:
**Start every session with this sequence (total time: 2-3 minutes - NEVER CANCEL):**

```bash
# 1. Repository setup
cd /home/runner/work/dimpact-helm-charts/dimpact-helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add maykinmedia https://maykinmedia.github.io/charts
# ... (add all repositories from setup section above)

# 2. Update and validate
helm repo update  # 15-30 seconds
helm dependency update charts/podiumd  # 30-60 seconds

# 3. Baseline validation
helm lint charts/podiumd  # < 5 seconds - should show "0 chart(s) failed"
helm template test charts/kiss --dry-run | head -5  # < 5 seconds - verify working chart

# 4. Ready to work!
```