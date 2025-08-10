#!/bin/bash

# 🚀 Script to toggle individual PodiumD components on/off
# Usage: ./scripts/toggle-component.sh <component-name> [on|off]

if [ $# -lt 1 ]; then
    echo "❌ Usage: $0 <component-name> [on|off]"
    echo "📋 Available components:"
    echo "   keycloak, infinispan, openzaak, opennotificaties, zac"
    echo "   objecten, objecttypen, openarchiefbeheer, openklant"
    echo "   openformulieren, openinwoner, kisselastic, brppersonenmock"
    echo "   clamav"
    exit 1
fi

COMPONENT=$1
ACTION=${2:-"toggle"}

# Validate component name
VALID_COMPONENTS="keycloak infinispan openzaak opennotificaties zac objecten objecttypen openarchiefbeheer openklant openformulieren openinwoner kisselastic brppersonenmock clamav"

if [[ ! " $VALID_COMPONENTS " =~ " $COMPONENT " ]]; then
    echo "❌ Invalid component: $COMPONENT"
    echo "📋 Valid components: $VALID_COMPONENTS"
    exit 1
fi

echo "🔧 Toggling component: $COMPONENT"

# Backup current helmfile
cp helmfile.yaml helmfile.yaml.backup.$(date +%Y%m%d_%H%M%S)

if [ "$ACTION" = "on" ] || [ "$ACTION" = "toggle" ]; then
    # Enable component
    sed -i.bak "/name: $COMPONENT/,/timeout:/{/installed: false/d}" helmfile.yaml
    sed -i.bak "/name: $COMPONENT/a\    installed: true" helmfile.yaml
    
    # Update environment file
    sed -i.bak "s/^$COMPONENT:/$COMPONENT:\n  enabled: true/" helmfile/environments/default.yaml
    
    echo "✅ $COMPONENT has been ENABLED"
elif [ "$ACTION" = "off" ]; then
    # Disable component
    sed -i.bak "/name: $COMPONENT/,/timeout:/{/installed: true/d}" helmfile.yaml
    sed -i.bak "/name: $COMPONENT/a\    installed: false" helmfile.yaml
    
    # Update environment file
    sed -i.bak "s/^$COMPONENT:/$COMPONENT:\n  enabled: false/" helmfile/environments/default.yaml
    
    echo "✅ $COMPONENT has been DISABLED"
fi

# Clean up backup files
rm -f helmfile.yaml.bak helmfile/environments/default.yaml.bak

echo "📋 You can now run: helmfile apply"
echo "🔄 To check status: helmfile status"
