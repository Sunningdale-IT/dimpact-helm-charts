# Dimpact Helm Charts Repository

This repository contains Helm charts for the Dutch government Dimpact organization's PodiumD platform, providing municipal digital services including Open Zaak, Open Formulieren, Open Inwoner, KISS (contact management), and related components.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Basic Validation
- Ensure Helm is installed: `helm version` (requires v3.x+)
- Lint podiumd chart: `helm lint charts/podiumd` -- primary chart of interest 
- Template podiumd chart: `helm template test charts/podiumd --dry-run` -- verify podiumd templates

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
```bash
# Step 1: Lint the podiumd chart
helm lint charts/podiumd

# Step 2: Generate templates to check for YAML validity  
helm template test charts/podiumd --dry-run

# Step 3: Check output makes sense (look for proper Kubernetes resources)
helm template test charts/podiumd --dry-run | head -20

# Step 4: Verify values.yaml changes work with template
helm template test charts/podiumd --dry-run --set key=value

# Step 5: Update dependencies if needed
helm dependency update charts/podiumd
```

### Common Issues and Solutions:
- **"nil pointer evaluating"**: Missing required values in values.yaml 
- **"missing dependencies"**: Run `helm dependency update charts/podiumd` to fetch external dependencies
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