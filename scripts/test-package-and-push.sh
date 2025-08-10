#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Testing Helm chart package and push script${NC}"
echo ""

# Test 1: Help functionality
echo -e "${YELLOW}📋 Test 1: Help functionality${NC}"
if ./scripts/package-and-push.sh --help >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Help functionality works${NC}"
else
    echo -e "${RED}❌ Help functionality failed${NC}"
    exit 1
fi

# Test 2: Missing registry credentials (should fail)
echo -e "${YELLOW}📋 Test 2: Missing registry credentials handling${NC}"
output=$(./scripts/package-and-push.sh --chart brp-personen-mock 2>&1 || true)
if echo "$output" | grep -q "Registry username is required\|Registry password is required"; then
    echo -e "${GREEN}✅ Missing registry credentials handled correctly${NC}"
else
    echo -e "${RED}❌ Missing registry credentials not handled correctly${NC}"
    echo "Output: $output"
    exit 1
fi

# Test 3: GITHUB_TOKEN functionality (should proceed)
echo -e "${YELLOW}📋 Test 3: GITHUB_TOKEN functionality${NC}"
output=$(GITHUB_TOKEN=test123 ./scripts/package-and-push.sh --dev --username testuser 2>&1 | head -5 || true)
if echo "$output" | grep -q "Starting Helm chart package and push process"; then
    echo -e "${GREEN}✅ GITHUB_TOKEN functionality works correctly${NC}"
else
    echo -e "${RED}❌ GITHUB_TOKEN functionality not working correctly${NC}"
    echo "Output: $output"
    exit 1
fi

# Test 4: Invalid chart name
echo -e "${YELLOW}📋 Test 4: Invalid chart name handling${NC}"
output=$(./scripts/package-and-push.sh --chart nonexistent-chart 2>&1 || true)
if echo "$output" | grep -q "Chart directory not found"; then
    echo -e "${GREEN}✅ Invalid chart name handled correctly${NC}"
else
    echo -e "${RED}❌ Invalid chart name not handled correctly${NC}"
    echo "Output: $output"
    exit 1
fi

# Test 5: Invalid option
echo -e "${YELLOW}📋 Test 5: Invalid option handling${NC}"
output=$(./scripts/package-and-push.sh --invalid-option 2>&1 || true)
if echo "$output" | grep -q "Unknown option"; then
    echo -e "${GREEN}✅ Invalid option handled correctly${NC}"
else
    echo -e "${RED}❌ Invalid option not handled correctly${NC}"
    echo "Output: $output"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All tests passed! The script is working correctly.${NC}"
echo -e "${YELLOW}💡 To test with actual registry push, use:${NC}"
echo "   # Development mode (with -snapshot suffix):"
echo "   ./scripts/package-and-push.sh --dev --registry oci://your-registry.com --username youruser --password yourpass"
echo "   # Development mode with default registry (ghcr.io/sunningdale-it):"
echo "   ./scripts/package-and-push.sh --dev --username youruser --password yourpass"
echo "   # Production mode (without -snapshot suffix):"
echo "   ./scripts/package-and-push.sh --registry oci://your-registry.com --username youruser --password yourpass"
echo "   # Production mode with default registry (ghcr.io/sunningdale-it):"
echo "   ./scripts/package-and-push.sh --username youruser --password yourpass"
