#!/bin/bash

# 🚀 Script to disable all PodiumD components except clamav
# This script sets installed: false for all components except clamav

echo "🔧 Disabling all PodiumD components except clamav..."

# Backup current helmfile
cp helmfile.yaml helmfile.yaml.backup.$(date +%Y%m%d_%H%M%S)

# Set installed: false for all releases except clamav
sed -i.bak '/name: clamav/,/timeout:/{/installed:/d}' helmfile.yaml
sed -i.bak 's/installed: true/installed: false/g' helmfile.yaml

# Add installed: true for clamav (since we removed it above)
sed -i.bak '/name: clamav/a\    installed: true' helmfile.yaml

# Update environment file to disable all components except clamav
sed -i.bak 's/enabled: true/enabled: false/g' helmfile/environments/default.yaml
sed -i.bak 's/clamav:/clamav:\n  enabled: true/' helmfile/environments/default.yaml

# Clean up backup files
rm -f helmfile.yaml.bak helmfile/environments/default.yaml.bak

echo "✅ All components except clamav have been disabled!"
echo "📋 You can now run: helmfile apply"
echo "🔄 To enable all again, run: scripts/enable-all-components.sh"
