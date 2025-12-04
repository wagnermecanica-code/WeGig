#!/bin/bash
# WeGig Code Signing Verification Script
# Verifica se todos os requisitos de Code Signing estão configurados

set -e

echo "🔐 WeGig Code Signing Verification"
echo "===================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check and display result
check_item() {
    local description=$1
    local command=$2
    
    echo -n "Checking $description... "
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# Check Team ID in project
echo "📱 Project Configuration"
echo "------------------------"

cd "$(dirname "$0")/../packages/app/ios"

TEAM_ID=$(xcodebuild -project Runner.xcodeproj -showBuildSettings -configuration Release 2>/dev/null | grep "DEVELOPMENT_TEAM" | head -1 | awk '{print $3}')

if [ -n "$TEAM_ID" ]; then
    echo -e "Team ID: ${GREEN}$TEAM_ID${NC}"
else
    echo -e "Team ID: ${RED}NOT CONFIGURED${NC}"
fi

echo ""

# Check Bundle Identifier
echo "📦 Bundle Identifiers"
echo "---------------------"

BUNDLE_ID=$(xcodebuild -project Runner.xcodeproj -showBuildSettings -configuration Release 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | head -1 | awk '{print $3}')
BUNDLE_ID_DEV=$(xcodebuild -project Runner.xcodeproj -showBuildSettings -configuration "Debug-dev" 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | head -1 | awk '{print $3}')
BUNDLE_ID_STAGING=$(xcodebuild -project Runner.xcodeproj -showBuildSettings -configuration "Debug-staging" 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | head -1 | awk '{print $3}')

echo "Production: $BUNDLE_ID"
echo "Dev:        $BUNDLE_ID_DEV"
echo "Staging:    $BUNDLE_ID_STAGING"

echo ""

# Check Certificates
echo "📜 Code Signing Certificates"
echo "----------------------------"

CERT_COUNT=$(security find-identity -v -p codesigning 2>/dev/null | grep "iPhone" | wc -l)

if [ "$CERT_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Found $CERT_COUNT code signing certificate(s)"
    security find-identity -v -p codesigning 2>/dev/null | grep "iPhone" | head -5
else
    echo -e "${RED}✗${NC} No code signing certificates found"
    echo "   Run: open /Applications/Xcode.app/Contents/Developer/Applications/Application\\ Loader.app"
fi

echo ""

# Check Provisioning Profiles
echo "📋 Provisioning Profiles"
echo "------------------------"

PP_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
if [ -d "$PP_DIR" ]; then
    PP_COUNT=$(ls "$PP_DIR"/*.mobileprovision 2>/dev/null | wc -l)
    
    if [ "$PP_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Found $PP_COUNT provisioning profile(s)"
        
        # Show profiles for our bundle IDs
        for profile in "$PP_DIR"/*.mobileprovision; do
            APP_ID=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' /dev/stdin <<< $(security cms -D -i "$profile") 2>/dev/null | cut -d. -f2-)
            
            if [[ "$APP_ID" == *"wegig"* ]]; then
                PROFILE_NAME=$(/usr/libexec/PlistBuddy -c 'Print :Name' /dev/stdin <<< $(security cms -D -i "$profile") 2>/dev/null)
                echo "  • $PROFILE_NAME ($APP_ID)"
            fi
        done
    else
        echo -e "${RED}✗${NC} No provisioning profiles found"
        echo "   Download from: https://developer.apple.com/account/resources/profiles/list"
    fi
else
    echo -e "${RED}✗${NC} Provisioning profiles directory not found"
fi

echo ""

# Check exportOptions.plist
echo "⚙️  Export Configuration"
echo "------------------------"

if [ -f "exportOptions.plist" ]; then
    echo -e "${GREEN}✓${NC} exportOptions.plist exists"
else
    echo -e "${RED}✗${NC} exportOptions.plist not found"
    echo "   Expected at: $(pwd)/exportOptions.plist"
fi

echo ""

# Summary
echo "📊 Summary"
echo "----------"

ERRORS=0

[ -n "$TEAM_ID" ] || ((ERRORS++))
[ "$CERT_COUNT" -gt 0 ] || ((ERRORS++))
[ -f "exportOptions.plist" ] || ((ERRORS++))

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You're ready to build signed iOS apps."
    exit 0
else
    echo -e "${RED}✗ $ERRORS issue(s) found${NC}"
    echo ""
    echo "Please fix the issues above before building for production."
    echo "See CODE_SIGNING_SETUP.md for detailed instructions."
    exit 1
fi
