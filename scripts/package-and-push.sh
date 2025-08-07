#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Auto-detect git repository information
GIT_REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$GIT_REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    GIT_OWNER="${BASH_REMATCH[1]}"
    GIT_REPO="${BASH_REMATCH[2]}"
    DEFAULT_REGISTRY_URL="oci://ghcr.io/${GIT_OWNER}"
else
    DEFAULT_REGISTRY_URL=""
fi

# Default values
CHART_NAME="podiumd"
CHART_PATH="charts/${CHART_NAME}"
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
    --dev                   Enable development mode (pushes to development registry)
    --chart CHART_NAME      Chart name to package (default: podiumd)
    --registry URL          Registry URL (required for --dev mode)
    --username USERNAME     Registry username (required for --dev mode)
    --password PASSWORD     Registry password (required for --dev mode)
    --help                  Show this help message

EXAMPLES:
    # Development mode - push to custom registry
    $0 --dev --registry oci://my-registry.com/charts --username myuser --password mypass
    
    # Development mode - uses auto-detected GitHub registry and defaults
    $0 --dev
    
    # Production mode - uses GitHub Actions workflow instead
    $0

ENVIRONMENT VARIABLES:
    HELM_REGISTRY_URL       Registry URL for development mode
    HELM_REGISTRY_USERNAME  Registry username for development mode  
    HELM_REGISTRY_PASSWORD  Registry password for development mode
    GITHUB_TOKEN           GitHub token (used as default password for GitHub registries)

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

# Function to add dependency repositories
add_dependency_repos() {
    echo -e "${YELLOW}📦 Adding dependency chart repositories...${NC}"
    
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add maykinmedia https://maykinmedia.github.io/charts  
    helm repo add opentelemetry https://open-telemetry.github.io/opentelemetry-helm-charts
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
    helm lint "$CHART_PATH"
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Helm lint passed! Proceeding to package the chart...${NC}"
    else
        echo -e "${RED}❌ Helm lint failed!${NC}"
        exit 1
    fi
}

# Function to package the chart
package_chart() {
    echo -e "${YELLOW}📦 Packaging chart $CHART_NAME...${NC}"
    helm package "$CHART_PATH"
    
    # Find the packaged chart file
    CHART_VERSION=$(helm show chart "$CHART_PATH" | grep '^version:' | awk '{print $2}')
    PACKAGE_FILE="${CHART_NAME}-${CHART_VERSION}.tgz"
    
    if [[ -f "$PACKAGE_FILE" ]]; then
        echo -e "${GREEN}✅ Successfully packaged chart and saved it to: $PACKAGE_FILE${NC}"
    else
        echo -e "${RED}❌ Failed to package chart${NC}"
        exit 1
    fi
}

# Function to push chart in development mode
push_chart_dev() {
    # Use environment variables if not provided via command line
    REGISTRY_URL=${REGISTRY_URL:-$HELM_REGISTRY_URL}
    REGISTRY_URL=${REGISTRY_URL:-$DEFAULT_REGISTRY_URL}
    REGISTRY_USERNAME=${REGISTRY_USERNAME:-$HELM_REGISTRY_USERNAME}
    REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-$HELM_REGISTRY_PASSWORD}
    REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-$GITHUB_TOKEN}
    
    # Validate required parameters for dev mode
    if [[ -z "$REGISTRY_URL" ]]; then
        echo -e "${RED}❌ Registry URL is required for development mode${NC}"
        echo -e "${YELLOW}💡 Use --registry or set HELM_REGISTRY_URL environment variable${NC}"
        if [[ -n "$GIT_REMOTE_URL" ]]; then
            echo -e "${YELLOW}💡 Auto-detected GitHub repository, but could not determine registry URL${NC}"
        fi
        exit 1
    fi
    
    if [[ -z "$REGISTRY_USERNAME" ]]; then
        echo -e "${RED}❌ Registry username is required for development mode${NC}"  
        echo -e "${YELLOW}💡 Use --username or set HELM_REGISTRY_USERNAME environment variable${NC}"
        exit 1
    fi
    
    if [[ -z "$REGISTRY_PASSWORD" ]]; then
        echo -e "${RED}❌ Registry password is required for development mode${NC}"
        echo -e "${YELLOW}💡 Use --password, set HELM_REGISTRY_PASSWORD, or ensure GITHUB_TOKEN is available${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}🔐 Logging into registry...${NC}"
    
    # Login to registry
    if echo "$REGISTRY_PASSWORD" | helm registry login "$REGISTRY_URL" --username "$REGISTRY_USERNAME" --password-stdin; then
        echo -e "${GREEN}✅ Login Succeeded${NC}"
    else
        echo -e "${RED}❌ Registry login failed${NC}"
        exit 1
    fi
    
    # Push the chart
    echo -e "${YELLOW}🚀 Pushing chart to development registry...${NC}"
    CHART_VERSION=$(helm show chart "$CHART_PATH" | grep '^version:' | awk '{print $2}')
    PACKAGE_FILE="${CHART_NAME}-${CHART_VERSION}.tgz"
    
    # Construct the full registry path
    if [[ "$REGISTRY_URL" == oci://* ]]; then
        FULL_REGISTRY_PATH="$REGISTRY_URL"
    else
        FULL_REGISTRY_PATH="oci://$REGISTRY_URL"
    fi
    
    if helm push "$PACKAGE_FILE" "$FULL_REGISTRY_PATH"; then
        echo -e "${GREEN}✅ Chart pushed successfully to $FULL_REGISTRY_PATH${NC}"
    else
        echo -e "${RED}❌ Failed to push chart to registry${NC}"
        exit 1
    fi
}

# Function to handle production mode
handle_production_mode() {
    echo -e "${YELLOW}🏭 Production mode detected${NC}"
    echo -e "${YELLOW}💡 For production releases, use GitHub Actions workflow instead:${NC}"
    echo "   - Push changes to main branch for automatic release"
    echo "   - Use 'Release Charts met changelogs' workflow for manual release with specific version"
    echo ""
    echo -e "${GREEN}✅ Chart packaged successfully for local testing${NC}"
    echo -e "${YELLOW}📦 Package location: ${CHART_NAME}-*.tgz${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}🚀 Starting Helm chart package and push process${NC}"
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
    
    # Handle push based on mode
    if [[ "$DEV_MODE" = true ]]; then
        push_chart_dev
    else
        handle_production_mode
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Process completed successfully!${NC}"
}

# Run main function
main "$@"