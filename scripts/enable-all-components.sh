#!/bin/bash

# 🚀 Script to re-enable all PodiumD components in helmfile
# This script sets installed: true for all components

echo "🔧 Re-enabling all PodiumD components..."

# Backup current helmfile
cp helmfile.yaml helmfile.yaml.backup.$(date +%Y%m%d_%H%M%S)

# Set installed: true for all releases
sed -i.bak 's/installed: false/installed: true/g' helmfile.yaml

# Update environment file to enable all components
sed -i.bak 's/enabled: false/enabled: true/g' helmfile/environments/default.yaml

# Clean up backup files
rm -f helmfile.yaml.bak helmfile/environments/default.yaml.bak

echo "✅ All components have been re-enabled!"
echo "📋 You can now run: helmfile apply"
echo "🔄 To disable again, run: scripts/disable-all-except-clamav.sh"
