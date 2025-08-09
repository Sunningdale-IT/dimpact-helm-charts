#!/bin/bash
#
# PodiumD Migration Script
# 
# This script helps migrate from the monolithic podiumd chart to the new Helmfile-based deployment
#

set -e

# Configuration
NAMESPACE=${NAMESPACE:-podiumd}
BACKUP_DIR=${BACKUP_DIR:-./podiumd-migration-backup-$(date +%Y%m%d-%H%M%S)}
DRY_RUN=${DRY_RUN:-false}
HELMFILE_ENV=${HELMFILE_ENV:-development}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed. Please install Helm v3.8+ first."
        exit 1
    fi
    
    # Check if helmfile is installed
    if ! command -v helmfile &> /dev/null; then
        log_error "Helmfile is not installed. Please install Helmfile v0.169.1+ first."
        echo "Installation command: curl -L https://github.com/helmfile/helmfile/releases/download/v0.169.1/helmfile_0.169.1_linux_amd64.tar.gz | tar -xzf - && sudo mv helmfile /usr/local/bin/"
        exit 1
    fi
    
    # Check if kubectl is configured
    if ! kubectl cluster-info &> /dev/null; then
        log_error "kubectl is not configured or cluster is not accessible."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Backup existing deployment
backup_existing_deployment() {
    log_info "Creating backup of existing deployment..."
    mkdir -p "$BACKUP_DIR"
    
    # Check if podiumd release exists
    if helm list -n "$NAMESPACE" | grep -q "podiumd"; then
        log_info "Backing up existing podiumd release..."
        
        # Backup Helm values
        helm get values podiumd -n "$NAMESPACE" > "$BACKUP_DIR/podiumd-values.yaml"
        
        # Backup Helm manifest
        helm get manifest podiumd -n "$NAMESPACE" > "$BACKUP_DIR/podiumd-manifest.yaml"
        
        # Backup all secrets in namespace
        kubectl get secrets -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/secrets-backup.yaml"
        
        # Backup all configmaps in namespace
        kubectl get configmaps -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/configmaps-backup.yaml"
        
        # Backup PVCs
        kubectl get pvc -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/pvc-backup.yaml"
        
        log_success "Backup completed in $BACKUP_DIR"
    else
        log_warn "No existing podiumd release found in namespace $NAMESPACE"
    fi
}

# Validate helmfile configuration
validate_helmfile() {
    log_info "Validating Helmfile configuration..."
    
    if [ ! -f "helmfile.yaml" ]; then
        log_error "helmfile.yaml not found in current directory"
        exit 1
    fi
    
    # Test helmfile template generation
    if helmfile -e "$HELMFILE_ENV" template --quiet > /tmp/helmfile-validation.yaml 2>&1; then
        log_success "Helmfile validation passed"
        log_info "Generated template has $(wc -l < /tmp/helmfile-validation.yaml) lines"
    else
        log_error "Helmfile validation failed:"
        cat /tmp/helmfile-validation.yaml
        exit 1
    fi
}

# Remove old deployment
remove_old_deployment() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would remove existing podiumd release"
        return
    fi
    
    log_info "Removing existing podiumd deployment..."
    
    if helm list -n "$NAMESPACE" | grep -q "podiumd"; then
        log_warn "Uninstalling monolithic podiumd chart..."
        helm uninstall podiumd -n "$NAMESPACE" --wait
        log_success "Old deployment removed"
    else
        log_info "No existing podiumd deployment found"
    fi
}

# Deploy with helmfile
deploy_with_helmfile() {
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would deploy with helmfile"
        helmfile -e "$HELMFILE_ENV" diff
        return
    fi
    
    log_info "Deploying PodiumD platform with Helmfile..."
    
    # Deploy all components
    helmfile -e "$HELMFILE_ENV" sync --wait --timeout 900
    
    log_success "Helmfile deployment completed"
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check if all expected releases are installed
    expected_releases=("keycloak" "clamav" "openzaak" "opennotificaties" "objecten" "objecttypen" "openformulieren" "openinwoner")
    
    for release in "${expected_releases[@]}"; do
        if helm list -n "$NAMESPACE" | grep -q "$release"; then
            log_success "✓ $release is deployed"
        else
            log_warn "✗ $release is missing"
        fi
    done
    
    # Check pod status
    log_info "Pod status in namespace $NAMESPACE:"
    kubectl get pods -n "$NAMESPACE"
    
    # Check services
    log_info "Service status in namespace $NAMESPACE:"
    kubectl get services -n "$NAMESPACE"
}

# Main migration function
migrate() {
    echo "
╔══════════════════════════════════════════════════════════════════════════════╗
║                           PodiumD Migration Script                           ║
║                                                                              ║
║  This script migrates from monolithic podiumd chart to Helmfile deployment  ║
║  Environment: $HELMFILE_ENV                                                    ║
║  Namespace: $NAMESPACE                                                       ║
║  Dry Run: $DRY_RUN                                                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
"
    
    check_prerequisites
    backup_existing_deployment
    validate_helmfile
    
    if [ "$DRY_RUN" = "false" ]; then
        read -p "Do you want to proceed with the migration? This will remove the existing deployment! (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Migration cancelled by user"
            exit 0
        fi
    fi
    
    remove_old_deployment
    deploy_with_helmfile
    verify_deployment
    
    echo "
╔══════════════════════════════════════════════════════════════════════════════╗
║                              Migration Complete                              ║
║                                                                              ║
║  Your PodiumD platform has been successfully migrated to Helmfile!          ║
║                                                                              ║
║  Backup Location: $BACKUP_DIR                                               ║
║  Environment: $HELMFILE_ENV                                                  ║
║  Namespace: $NAMESPACE                                                       ║
║                                                                              ║
║  Useful commands:                                                            ║
║    helmfile -e $HELMFILE_ENV list                                           ║
║    helmfile -e $HELMFILE_ENV status                                         ║
║    kubectl get pods -n $NAMESPACE                                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
"
}

# Handle command line arguments
case "${1:-migrate}" in
    migrate)
        migrate
        ;;
    backup-only)
        check_prerequisites
        backup_existing_deployment
        ;;
    validate)
        check_prerequisites
        validate_helmfile
        ;;
    deploy-only)
        check_prerequisites
        validate_helmfile
        deploy_with_helmfile
        verify_deployment
        ;;
    *)
        echo "Usage: $0 [migrate|backup-only|validate|deploy-only]"
        echo ""
        echo "Commands:"
        echo "  migrate     - Full migration from monolithic to helmfile (default)"
        echo "  backup-only - Only backup existing deployment"
        echo "  validate    - Only validate helmfile configuration"
        echo "  deploy-only - Only deploy with helmfile (assumes cleanup is done)"
        echo ""
        echo "Environment Variables:"
        echo "  NAMESPACE      - Kubernetes namespace (default: podiumd)"
        echo "  HELMFILE_ENV   - Helmfile environment (default: development)"
        echo "  DRY_RUN        - Set to 'true' for dry run (default: false)"
        echo "  BACKUP_DIR     - Backup directory (default: ./podiumd-migration-backup-TIMESTAMP)"
        exit 1
        ;;
esac