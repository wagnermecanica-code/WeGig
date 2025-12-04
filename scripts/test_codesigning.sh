#!/bin/bash
# Script para testar Code Signing localmente antes de rodar no CI
# Simula o processo do GitHub Actions

set -e

echo "🧪 Testing Code Signing Setup Locally"
echo "======================================"
echo ""

# Check if running from correct directory
if [ ! -f "packages/app/ios/Runner.xcodeproj/project.pbxproj" ]; then
  echo "❌ Error: Must run from repository root"
  echo "   Current directory: $(pwd)"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLAVOR="${1:-dev}"
SCHEME="$FLAVOR"
CONFIGURATION="Release-${FLAVOR}"

if [ "$FLAVOR" == "prod" ]; then
  SCHEME="Runner"
  CONFIGURATION="Release"
fi

echo -e "${BLUE}Configuration:${NC}"
echo "  Flavor: $FLAVOR"
echo "  Scheme: $SCHEME"
echo "  Configuration: $CONFIGURATION"
echo ""

# Step 1: Check certificates
echo -e "${BLUE}Step 1: Checking Code Signing Certificates${NC}"
CERT_COUNT=$(security find-identity -v -p codesigning 2>/dev/null | grep "iPhone" | wc -l)

if [ "$CERT_COUNT" -gt 0 ]; then
  echo -e "  ${GREEN}✓${NC} Found $CERT_COUNT certificate(s)"
  security find-identity -v -p codesigning 2>/dev/null | grep "iPhone" | head -3
else
  echo -e "  ${RED}✗${NC} No code signing certificates found"
  echo "  Please import your certificates in Keychain Access"
  exit 1
fi
echo ""

# Step 2: Check provisioning profiles
echo -e "${BLUE}Step 2: Checking Provisioning Profiles${NC}"
PP_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"

if [ -d "$PP_DIR" ]; then
  PP_COUNT=$(ls "$PP_DIR"/*.mobileprovision 2>/dev/null | wc -l)
  echo -e "  ${GREEN}✓${NC} Found $PP_COUNT profile(s) in $PP_DIR"
else
  echo -e "  ${YELLOW}⚠${NC}  Provisioning profiles directory not found"
  echo "  Profiles will be managed by Xcode"
fi
echo ""

# Step 3: Check Team ID
echo -e "${BLUE}Step 3: Checking Development Team${NC}"
cd packages/app/ios

TEAM_ID=$(xcodebuild -project Runner.xcodeproj -showBuildSettings -configuration $CONFIGURATION 2>/dev/null | grep "DEVELOPMENT_TEAM" | head -1 | awk '{print $3}')

if [ -n "$TEAM_ID" ]; then
  echo -e "  ${GREEN}✓${NC} Team ID: $TEAM_ID"
else
  echo -e "  ${RED}✗${NC} Team ID not configured"
  exit 1
fi
echo ""

# Step 4: Flutter build
echo -e "${BLUE}Step 4: Building Flutter iOS${NC}"
cd ..

TARGET="lib/main_${FLAVOR}.dart"
echo "  Target: $TARGET"

flutter build ios \
  --release \
  --flavor $FLAVOR \
  -t $TARGET \
  --no-codesign

if [ $? -eq 0 ]; then
  echo -e "  ${GREEN}✓${NC} Flutter build completed"
else
  echo -e "  ${RED}✗${NC} Flutter build failed"
  exit 1
fi
echo ""

# Step 5: Xcode archive
echo -e "${BLUE}Step 5: Creating Xcode Archive${NC}"
cd ios

# Create temporary directory for archive
ARCHIVE_PATH="/tmp/wegig_test_archive.xcarchive"
rm -rf "$ARCHIVE_PATH"

echo "  Archive path: $ARCHIVE_PATH"
echo "  Building with xcodebuild..."
echo ""

xcodebuild \
  -workspace Runner.xcworkspace \
  -scheme $SCHEME \
  -configuration $CONFIGURATION \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE="Automatic" \
  clean archive | grep -E "^\*\*|Building|Signing|error|warning" || true

if [ -d "$ARCHIVE_PATH" ]; then
  echo ""
  echo -e "  ${GREEN}✓${NC} Archive created successfully"
  ls -lh "$ARCHIVE_PATH" | head -5
else
  echo ""
  echo -e "  ${RED}✗${NC} Archive creation failed"
  exit 1
fi
echo ""

# Step 6: Export IPA
echo -e "${BLUE}Step 6: Exporting IPA${NC}"

# Check if exportOptions.plist exists
if [ ! -f "exportOptions.plist" ]; then
  echo -e "  ${RED}✗${NC} exportOptions.plist not found"
  exit 1
fi

IPA_PATH="/tmp/wegig_test_ipa"
rm -rf "$IPA_PATH"
mkdir -p "$IPA_PATH"

echo "  Export path: $IPA_PATH"
echo "  Exporting with xcodebuild..."
echo ""

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$IPA_PATH" \
  -exportOptionsPlist exportOptions.plist \
  -allowProvisioningUpdates | grep -E "^\*\*|Exporting|error|warning" || true

if [ -f "$IPA_PATH"/*.ipa ]; then
  echo ""
  echo -e "  ${GREEN}✓${NC} IPA exported successfully"
  ls -lh "$IPA_PATH"/*.ipa
  
  IPA_SIZE=$(du -h "$IPA_PATH"/*.ipa | cut -f1)
  echo "  IPA size: $IPA_SIZE"
else
  echo ""
  echo -e "  ${RED}✗${NC} IPA export failed"
  exit 1
fi
echo ""

# Summary
echo -e "${GREEN}✅ All tests passed!${NC}"
echo ""
echo "Summary:"
echo "  Flavor:      $FLAVOR"
echo "  Archive:     $ARCHIVE_PATH"
echo "  IPA:         $IPA_PATH/*.ipa"
echo ""
echo "You can now safely use the GitHub Actions workflow."
echo ""
echo "Cleanup:"
echo "  rm -rf $ARCHIVE_PATH"
echo "  rm -rf $IPA_PATH"
