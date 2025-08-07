# Dimpact Helm Charts Repository

This repository contains Helm charts for the Dutch government Dimpact organization's PodiumD platform, providing municipal digital services including Open Zaak, Open Formulieren, Open Inwoner, KISS (contact management), and related components.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Basic Validation
- Ensure Helm is installed: `helm version` (requires v3.x+)
- Lint individual charts: `helm lint charts/<chart-name>` -- takes < 1 second per chart. 
- Lint all working charts: `helm lint charts/brp-personen-mock charts/kiss charts/flowable-rest charts/flowable-ui` -- takes < 5 seconds total. **NEVER CANCEL**.
- Template individual charts: `helm template test charts/<chart-name> --dry-run` -- takes < 1 second per chart.

### Working with External Dependencies
- External Helm repositories are accessible and can be added using `helm repo add` commands
- The podiumd chart has many external dependencies that can now be resolved with network access
- External repos that are available include:
  - `https://charts.bitnami.com/bitnami` (Bitnami charts)
  - `https://maykinmedia.github.io/charts` (Maykin Media charts)
  - And all other external chart repositories listed in workflows

### Chart Structure and Components

#### Main Charts Available:
- **podiumd**: Main comprehensive platform chart (COMPLEX - has 13+ external dependencies) ⚠️ 
- **kiss**: Contact management system (Klantinteractie-Servicesysteem) ✅ Full functionality
- **brp-personen-mock**: BRP (Dutch population register) mock service ✅ Full functionality
- **monitoring-logging**: Monitoring and logging stack ✅ Full functionality with dependencies
- **vngreferentielijsten**: VNG reference lists ⚠️ May have template errors
- **beproeving**: Development/testing chart ✅ Full functionality with dependencies
- **flowable-rest**, **flowable-ui**: Flowable workflow components ✅ Full functionality

#### Chart Validation Commands:
```bash
# Lint charts (all should work with external dependencies available)
helm lint charts/brp-personen-mock    # ✅ Works - < 1 second
helm lint charts/kiss                 # ✅ Works - < 1 second  
helm lint charts/flowable-rest        # ✅ Works - < 1 second
helm lint charts/flowable-ui          # ✅ Works - < 1 second
helm lint charts/beproeving           # ✅ Works - < 1 second
helm lint charts/monitoring-logging   # ✅ Works - < 1 second

# Template charts (can generate valid YAML with dependencies)
helm template test charts/brp-personen-mock --dry-run    # ✅ Works - < 1 second
helm template test charts/kiss --dry-run                 # ✅ Works - < 1 second
helm template test charts/flowable-rest --dry-run        # ✅ Works - < 1 second
helm template test charts/flowable-ui --dry-run          # ✅ Works - < 1 second
helm template test charts/beproeving --dry-run           # ✅ Works with dependencies
helm template test charts/monitoring-logging --dry-run   # ✅ Works with dependencies

# Charts that may still have issues:
helm lint charts/podiumd              # ⚠️ May still have template errors despite available dependencies
helm lint charts/vngreferentielijsten # ⚠️ May have template error (nil pointer for database.password)
helm template test charts/vngreferentielijsten --dry-run # ⚠️ May have template errors

# Dependency management now works:
helm dependency update charts/podiumd # ✅ Works - can reach external repos
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

### ALWAYS Test These After Making Changes:
1. **Chart Linting**: `helm lint charts/<modified-chart>` -- verify no linting errors
2. **Template Generation**: `helm template test charts/<modified-chart> --dry-run` -- verify valid Kubernetes YAML
3. **Syntax Validation**: Check YAML files are valid using your editor's syntax highlighting

### DO NOT Test These (they may still have template errors):
- Charts with known template issues (vngreferentielijsten)
- Complex charts that may need dependency updates first (podiumd)

## Common Tasks

### Repo Root Structure
```
/home/runner/work/dimpact-helm-charts/dimpact-helm-charts/
├── .github/
│   ├── workflows/         # CI/CD workflows
│   └── CODEOWNERS        # Code ownership definitions
├── charts/               # Helm charts directory
│   ├── podiumd/         # Main platform chart
│   ├── kiss/            # Contact management
│   ├── brp-personen-mock/
│   ├── monitoring-logging/
│   └── vngreferentielijsten/
├── docs/                # Documentation
│   └── podiumd/        # PodiumD specific docs
├── .gitignore
├── README.md
└── renovate.json        # Dependency updates configuration
```

### Key Files to Understand:
- `charts/*/Chart.yaml`: Chart metadata and dependencies
- `charts/*/values.yaml`: Default configuration values
- `charts/*/README.md`: Chart-specific documentation (where available)
- `.github/workflows/*.yaml`: CI/CD pipeline definitions

### Important Development Notes:
- **PodiumD Platform**: Comprehensive suite including Open Zaak, Open Formulieren, Open Inwoner, Keycloak, ClamAV, etc.
- **Dutch Government Context**: This is for Dutch municipal digital services (gemeentelijke dienstverlening)
- **Chart Dependencies**: Most complex charts depend on external Helm repositories
- **Version Management**: Charts use semantic versioning and are released via GitHub Actions

### When Making Changes:
1. **ALWAYS** lint the chart after changes: `helm lint charts/<chart-name>`
2. **ALWAYS** test template generation: `helm template test charts/<chart-name> --dry-run`
3. **Add external repositories first** if working with complex charts: `helm repo add bitnami https://charts.bitnami.com/bitnami`
4. Check Chart.yaml version numbers are consistent
5. Update README.md if adding new parameters or changing behavior
6. **Update dependencies** for complex charts: `helm dependency update charts/<chart-name>`
7. **Test with dependencies** for charts that reference external repositories

### Validation Checklist for Chart Changes:
```bash
# Step 1: Lint the modified chart
helm lint charts/<modified-chart>

# Step 2: Generate templates to check for YAML validity  
helm template test charts/<modified-chart> --dry-run

# Step 3: Check output makes sense (look for proper Kubernetes resources)
helm template test charts/<modified-chart> --dry-run | head -20

# Step 4: Verify values.yaml changes work with template
helm template test charts/<modified-chart> --dry-run --set key=value

# For KISS chart - test with custom values
helm template test charts/kiss --dry-run --set frontend.image.tag=v1.2.3
```

### Common Issues and Solutions:
- **"nil pointer evaluating"**: Missing required values in values.yaml (like in vngreferentielijsten)
- **"missing dependencies"**: Run `helm dependency update charts/<chart-name>` to fetch external dependencies
- **"template errors"**: Usually means values.yaml doesn't match template expectations
- **Icon warnings**: Cosmetic only - add "icon:" field to Chart.yaml if desired

### Timing Expectations:
- Chart linting: < 1 second per chart
- Template generation: < 1 second per chart  
- Full CI workflow (when external repos work): 2-5 minutes
- **NEVER CANCEL** any operations - they complete very quickly in this repository

### Architecture Context:
PodiumD is a platform providing:
- **Forms**: Open Formulieren (form builder and renderer)
- **Portal**: Open Inwoner (citizen portal)
- **Contact**: KISS (contact management system)
- **Cases**: ZAC + Open Zaak (case management)
- **Archive**: Open Archiefbeheer (archive management)
- **Identity**: Keycloak (authentication/authorization)
- **Security**: ClamAV (antivirus scanning)