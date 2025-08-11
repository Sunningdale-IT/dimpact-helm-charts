#!/bin/bash

# 🚀 Script to remove nodeSelectors from all PodiumD components
# This removes the agentpool: userpool nodeSelector that causes scheduling issues

echo "🔧 Removing nodeSelectors from all component values files..."

# Backup current values files
mkdir -p helmfile/values/backup.$(date +%Y%m%d_%H%M%S)
cp helmfile/values/*.yaml helmfile/values/backup.$(date +%Y%m%d_%H%M%S)/

# Remove nodeSelector sections from all values files
for file in helmfile/values/*.yaml; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        # Remove nodeSelector sections
        sed -i.bak '/^nodeSelector:/,/^[^ ]/d' "$file"
        # Clean up any empty lines that might be left
        sed -i.bak '/^$/d' "$file"
    fi
done

# Clean up backup files
rm -f helmfile/values/*.bak

echo "✅ NodeSelectors have been removed from all component values files!"
echo "📋 You can now run: helmfile apply"
echo "🔄 The pods will now schedule on any available nodes"
