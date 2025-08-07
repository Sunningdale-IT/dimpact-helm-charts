#!/bin/bash

# Simple test script for package-and-push.sh
set -e

echo "🧪 Testing package-and-push.sh script..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SCRIPT_PATH="$SCRIPT_DIR/package-and-push.sh"

# Test 1: Help functionality
echo "📋 Test 1: Help functionality"
if "$SCRIPT_PATH" --help | grep -q "Package and push Helm charts"; then
    echo "✅ Help test passed"
else
    echo "❌ Help test failed"
    exit 1
fi

# Test 2: Error handling for non-existent chart
echo "📋 Test 2: Error handling for non-existent chart"
if "$SCRIPT_PATH" --chart nonexistent 2>&1 | grep -q "Chart directory not found"; then
    echo "✅ Error handling test passed"
else
    echo "❌ Error handling test failed"
    exit 1
fi

# Test 3: Dev mode without credentials
echo "📋 Test 3: Development mode validation"
if "$SCRIPT_PATH" --dev 2>&1 | grep -q "Registry URL is required for development mode"; then
    echo "✅ Development mode validation test passed"
else
    echo "❌ Development mode validation test failed"
    exit 1
fi

# Test 4: Production mode (dry run - just lint and package)
echo "📋 Test 4: Production mode dry run"
cd "$REPO_ROOT"
if "$SCRIPT_PATH" --chart kiss | grep -q "Chart packaged successfully"; then
    echo "✅ Production mode test passed"
    # Clean up
    rm -f *.tgz
else
    echo "❌ Production mode test failed"
    exit 1
fi

echo "🎉 All tests passed!"