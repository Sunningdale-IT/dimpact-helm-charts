#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate required tools
check_requirements() {
    local missing_tools=()
    
    if ! command -v helm >/dev/null 2>&1; then
        missing_tools+=("helm")
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}💡 Please install the missing tools and try again${NC}"
        exit 1
    fi
}

# Auto-detect git repository information
GIT_REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$GIT_REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
  GIT_OWNER="${BASH_REMATCH[1]}"
  GIT_REPO="${BASH_REMATCH[2]}"
  # Convert owner to lowercase for OCI registry URL
  DEFAULT_REGISTRY_URL="oci://ghcr.io/$(echo "${GIT_OWNER}" | tr '[:upper:]' '[:lower:]')"
else
    # Default to sunningdale-it if no git repository detected
    DEFAULT_REGISTRY_URL="oci://ghcr.io/sunningdale-it"
fi

# Default values
CHART_NAME="podiumd"
CHART_PATH="charts/podiumd"
DEV_MODE=false
REGISTRY_URL=""
REGISTRY_USERNAME="jimleitch01"
REGISTRY_PASSWORD=""

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Package and push Helm charts to a registry.

OPTIONS:
    --dev                   Enable development mode (pushes to development registry with -snapshot suffix)
    --chart CHART_NAME      Chart name to package (default: podiumd)
    --registry URL          Registry URL (default: oci://ghcr.io/sunningdale-it)
    --username USERNAME     Registry username (required)
    --password PASSWORD     Registry password (optional if GITHUB_TOKEN is set)
    --help                  Show this help message

EXAMPLES:
    # Development mode - push to custom registry with -snapshot suffix
    $0 --dev --registry oci://my-registry.com/charts --username myuser --password mypass
    
    # Development mode - uses default registry (ghcr.io/sunningdale-it) with GITHUB_TOKEN
    $0 --dev --username myuser
    
    # Production mode - push to registry without -snapshot suffix
    $0 --registry oci://my-registry.com/charts --username myuser --password mypass
    
    # Production mode - uses default registry (ghcr.io/sunningdale-it) with GITHUB_TOKEN
    $0 --username myuser

ENVIRONMENT VARIABLES:
    HELM_REGISTRY_URL       Registry URL (default: oci://ghcr.io/sunningdale-it)
    HELM_REGISTRY_USERNAME  Registry username
    HELM_REGISTRY_PASSWORD  Registry password
    GITHUB_TOKEN           GitHub token (used as password for GitHub registries)

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            DEV_MODE=true
            shift
            ;;
        --chart)
            CHART_NAME="$2"
            CHART_PATH="charts/${CHART_NAME}"
            shift 2
            ;;
        --registry)
            REGISTRY_URL="$2"
            shift 2
            ;;
        --username)
            REGISTRY_USERNAME="$2"
            shift 2
            ;;
        --password)
            REGISTRY_PASSWORD="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Check if chart exists
if [[ ! -d "$CHART_PATH" ]]; then
    echo -e "${RED}❌ Chart directory not found: $CHART_PATH${NC}"
    exit 1
fi

# Set registry parameters from environment variables or defaults if not provided via command line
if [[ -z "$REGISTRY_URL" ]]; then
    REGISTRY_URL=${HELM_REGISTRY_URL:-$DEFAULT_REGISTRY_URL}
fi

if [[ -z "$REGISTRY_USERNAME" ]]; then
    REGISTRY_USERNAME=${HELM_REGISTRY_USERNAME:-}
fi

if [[ -z "$REGISTRY_PASSWORD" ]]; then
    REGISTRY_PASSWORD=${HELM_REGISTRY_PASSWORD:-${GITHUB_TOKEN:-}}
fi

# Validate required parameters for both modes
if [[ -z "$REGISTRY_URL" ]]; then
    echo -e "${RED}❌ Registry URL is required${NC}"
    echo -e "${YELLOW}💡 Use --registry or set HELM_REGISTRY_URL environment variable${NC}"
    if [[ -n "$GIT_REMOTE_URL" ]]; then
        echo -e "${YELLOW}💡 Auto-detected GitHub repository, but could not determine registry URL${NC}"
    fi
    exit 1
fi

if [[ -z "$REGISTRY_USERNAME" ]]; then
    echo -e "${RED}❌ Registry username is required${NC}"  
    echo -e "${YELLOW}💡 Use --username or set HELM_REGISTRY_USERNAME environment variable${NC}"
    exit 1
fi

# Check for password or GITHUB_TOKEN
if [[ -z "$REGISTRY_PASSWORD" && -z "${GITHUB_TOKEN:-}" ]]; then
    echo -e "${RED}❌ Registry password is required${NC}"
    echo -e "${YELLOW}💡 Use --password, set HELM_REGISTRY_PASSWORD, or ensure GITHUB_TOKEN is available${NC}"
    exit 1
fi

# Function to add dependency repositories
add_dependency_repos() {
    echo -e "${YELLOW}📦 Adding dependency chart repositories...${NC}"





    # List of required repositories and their URLs (portable array)
    REPO_LIST=(
      "bitnami=https://charts.bitnami.com/bitnami"
      "maykinmedia=https://maykinmedia.github.io/charts"
      "opentelemetry=https://open-telemetry.github.io/opentelemetry-helm-charts"
      "wiremind=https://wiremind.github.io/wiremind-helm-charts"
      "dimpact=https://Dimpact-Samenwerking.github.io/helm-charts"
      "elastic=https://helm.elastic.co"
      "kiss-frontend=https://raw.githubusercontent.com/Klantinteractie-Servicesysteem/KISS-frontend/main/helm"
      "kiss-adapter=https://raw.githubusercontent.com/ICATT-Menselijk-Digitaal/podiumd-adapter/main/helm"
      "kiss-elastic=https://raw.githubusercontent.com/Klantinteractie-Servicesysteem/.github/main/docs/scripts/elastic"
      "zac=https://infonl.github.io/dimpact-zaakafhandelcomponent/"
      "openshift=https://charts.openshift.io"
      "grafana=https://grafana.github.io/helm-charts"
      "prometheus-community=https://prometheus-community.github.io/helm-charts"
    )

    # Get list of already added repos
    EXISTING_REPOS=$(helm repo list | awk 'NR>1 {print $1}')

    for entry in "${REPO_LIST[@]}"; do
      repo="${entry%%=*}"
      url="${entry#*=}"
      if echo "$EXISTING_REPOS" | grep -qx "$repo"; then
        echo -e "${YELLOW}🔎 Helm repo '$repo' already exists, skipping...${NC}"
      else
        helm repo add "$repo" "$url"
      fi
    done

    echo -e "${GREEN}✅ Dependency repositories added successfully${NC}"
}

# Function to update dependencies
update_dependencies() {
    echo -e "${YELLOW}🔄 Updating chart dependencies for $CHART_NAME...${NC}"
    helm dependency update "$CHART_PATH"
    echo -e "${GREEN}✅ Dependencies updated successfully${NC}"
}

# Function to lint the chart
lint_chart() {
    echo -e "${YELLOW}🔍 Linting $CHART_PATH...${NC}"
    if helm lint "$CHART_PATH"; then
        echo -e "${GREEN}✅ Helm lint passed! Proceeding to package the chart...${NC}"
    else
        echo -e "${RED}❌ Helm lint failed!${NC}"
        exit 1
    fi
}

# Function to package the chart
package_chart() {
    echo -e "${YELLOW}📦 Packaging chart $CHART_NAME...${NC}"
    CHART_VERSION=$(helm show chart "$CHART_PATH" | grep '^version:' | awk '{print $2}')
    if [[ "$DEV_MODE" = true ]]; then
        SNAPSHOT_VERSION="${CHART_VERSION}-snapshot"
        # Create a temporary Chart.yaml with -snapshot version
        TMP_CHART_YAML="$CHART_PATH/Chart.yaml.tmp"
        cp "$CHART_PATH/Chart.yaml" "$TMP_CHART_YAML"
        sed -i.bak "s/^version: .*/version: $SNAPSHOT_VERSION/" "$TMP_CHART_YAML"
        helm package "$CHART_PATH" --destination . --version "$SNAPSHOT_VERSION" --app-version "$SNAPSHOT_VERSION"
        rm -f "$TMP_CHART_YAML" "$TMP_CHART_YAML.bak"
        PACKAGE_FILE="${CHART_NAME}-${SNAPSHOT_VERSION}.tgz"
    else
        PACKAGE_FILE="${CHART_NAME}-${CHART_VERSION}.tgz"
        helm package "$CHART_PATH" --destination .
    fi
    
    if [[ -f "$PACKAGE_FILE" ]]; then
        echo -e "${GREEN}✅ Successfully packaged chart and saved it to: $PACKAGE_FILE${NC}"
    else
        echo -e "${RED}❌ Failed to package chart${NC}"
        exit 1
    fi
}

# Function to push chart to registry
push_chart() {
    # Registry parameters are already set in main execution
    
    echo -e "${YELLOW}🔐 Logging into registry...${NC}"
    
    # Extract registry hostname for login (strip oci:// and any path)
    LOGIN_HOST=$(echo "$REGISTRY_URL" | sed -E 's|^oci://||; s|/.*$||')
    if echo "$REGISTRY_PASSWORD" | helm registry login "$LOGIN_HOST" --username "$REGISTRY_USERNAME" --password-stdin; then
        echo -e "${GREEN}✅ Login Succeeded${NC}"
    else
        echo -e "${RED}❌ Registry login failed${NC}"
        exit 1
    fi
    
    # Push the chart
    echo -e "${YELLOW}🚀 Pushing chart to registry...${NC}"
    CHART_VERSION=$(helm show chart "$CHART_PATH" | grep '^version:' | awk '{print $2}')
    
    # Determine package file name based on mode
    if [[ "$DEV_MODE" = true ]]; then
        if [[ "$CHART_VERSION" == *-snapshot ]]; then
            PACKAGE_FILE="${CHART_NAME}-${CHART_VERSION}.tgz"
        else
            PACKAGE_FILE="${CHART_NAME}-${CHART_VERSION}-snapshot.tgz"
        fi
    else
        # Production mode - use original version without snapshot
        PACKAGE_FILE="${CHART_NAME}-${CHART_VERSION}.tgz"
    fi
    
    # Verify package file exists before pushing
    if [[ ! -f "$PACKAGE_FILE" ]]; then
        echo -e "${RED}❌ Package file not found: $PACKAGE_FILE${NC}"
        echo -e "${YELLOW}💡 Make sure the chart was packaged successfully${NC}"
        exit 1
    fi
    
    # Build the registry path - for GHCR, don't include chart name as Helm adds it automatically
    if [[ "$LOGIN_HOST" == "ghcr.io" ]]; then
        # Extract organization from registry URL or use default
        ORG=$(echo "$REGISTRY_URL" | sed -E 's|^oci://ghcr.io/||; s|/.*$||')
        if [[ -z "$ORG" ]]; then
            ORG="sunningdale-it"
        fi
        FULL_REGISTRY_PATH="oci://ghcr.io/$ORG"
    else
        # For non-GHCR registries, use the provided URL
        BASE_PATH="${REGISTRY_URL%/}"
        # Prepend oci:// if missing
        if [[ "$BASE_PATH" != oci://* ]]; then
            BASE_PATH="oci://$BASE_PATH"
        fi
        # Append chart name if not present
        if [[ "$BASE_PATH" != */$CHART_NAME ]]; then
            FULL_REGISTRY_PATH="$BASE_PATH/$CHART_NAME"
        else
            FULL_REGISTRY_PATH="$BASE_PATH"
        fi
    fi

    if helm push "$PACKAGE_FILE" "$FULL_REGISTRY_PATH"; then
        # Print the registry path and tag in the correct format
        if [[ "$LOGIN_HOST" == "ghcr.io" ]]; then
            ORG=$(echo "$REGISTRY_URL" | sed -E 's|^oci://ghcr.io/||; s|/.*$||')
            if [[ -z "$ORG" ]]; then
                ORG="sunningdale-it"
            fi
            echo -e "${GREEN}✅ Chart pushed successfully to: ghcr.io/$ORG/$CHART_NAME:$CHART_VERSION${NC}"
        else
            echo -e "${GREEN}✅ Chart pushed successfully to: $FULL_REGISTRY_PATH:${CHART_VERSION}${NC}"
        fi
    else
        echo -e "${RED}❌ Failed to push chart to registry${NC}"
        exit 1
    fi
}

# Main execution
main() {
    echo -e "${GREEN}🚀 Starting Helm chart package and push process${NC}"
    
    # Check requirements first
    check_requirements
    
    echo -e "${YELLOW}📋 Chart: $CHART_NAME${NC}"
    echo -e "${YELLOW}📁 Path: $CHART_PATH${NC}"
    echo -e "${YELLOW}🔧 Mode: $([ "$DEV_MODE" = true ] && echo "Development" || echo "Production")${NC}"
    if [[ -n "$DEFAULT_REGISTRY_URL" ]]; then
        echo -e "${YELLOW}🏠 Auto-detected repository: $GIT_OWNER/$GIT_REPO${NC}"
        echo -e "${YELLOW}📦 Default registry: $DEFAULT_REGISTRY_URL${NC}"
    fi
    echo ""
    
    # Add dependency repositories
    add_dependency_repos
    
    # Update dependencies
    update_dependencies
    
    # Lint the chart
    lint_chart
    
    # Package the chart
    package_chart
    
    # Push the chart to registry
    push_chart
    
    echo ""
    echo -e "${GREEN}🎉 Process completed successfully!${NC}"

    # Output instructions to download the chart from the target repository
    CHART_VERSION=$(helm show chart "$CHART_PATH" | grep '^version:' | awk '{print $2}')
    if [[ -n "$REGISTRY_URL" ]]; then
        LOGIN_HOST=$(echo "$REGISTRY_URL" | sed -E 's|^oci://||; s|/.*$||')
        if [[ "$LOGIN_HOST" == "ghcr.io" ]]; then
            ORG=$(echo "$REGISTRY_URL" | sed -E 's|^oci://ghcr.io/||; s|/.*$||')
            if [[ -z "$ORG" ]]; then
                ORG="sunningdale-it"
            fi
            REPO_PATH="oci://ghcr.io/$ORG/$CHART_NAME"
        else
            BASE_PATH="${REGISTRY_URL%/}"
            if [[ "$BASE_PATH" != oci://* ]]; then
                BASE_PATH="oci://$BASE_PATH"
            fi
            if [[ "$BASE_PATH" != */$CHART_NAME ]]; then
                REPO_PATH="$BASE_PATH/$CHART_NAME"
            else
                REPO_PATH="$BASE_PATH"
            fi
        fi
    else
        REPO_PATH="$DEFAULT_REGISTRY_URL/$CHART_NAME"
    fi
    
    if [[ "$DEV_MODE" = true ]]; then
        echo -e "${YELLOW}📥 To download the dev chart, run:${NC}"
        echo -e "  helm pull $REPO_PATH --version $CHART_VERSION-snapshot"
    else
        echo -e "${YELLOW}📥 To download the production chart, run:${NC}"
        echo -e "  helm pull $REPO_PATH --version $CHART_VERSION"
    fi
}

# Run main function
main "$@"

