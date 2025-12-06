#!/bin/bash

# ================================================================
# WeGig - Build Release Script (Monorepo)
# ================================================================
# Builds release APK/AAB with proper flavor configuration
# Supports: dev, staging, prod
# Features: Obfuscation, code shrinking, Firebase checks
# Usage: ./build_release.sh [dev|staging|prod]
# ================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}WeGig Build Release Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ================================================================
# VALIDATE FLAVOR
# ================================================================

FLAVOR=${1:-prod}

if [[ ! "$FLAVOR" =~ ^(dev|staging|prod)$ ]]; then
  echo -e "${RED}❌ Invalid flavor: $FLAVOR${NC}"
  echo -e "${YELLOW}Usage: $0 [dev|staging|prod]${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Flavor: $FLAVOR${NC}"

# ================================================================
# VALIDATE ENVIRONMENT
# ================================================================

echo ""
echo -e "${BLUE}Validating environment...${NC}"

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
  echo -e "${RED}❌ Flutter not found. Install Flutter first.${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Flutter installed${NC}"

# Check project structure
cd "$PROJECT_ROOT"

if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}❌ pubspec.yaml not found in $PROJECT_ROOT${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Project structure valid${NC}"

# Check main entry points
if [ ! -f "lib/main_$FLAVOR.dart" ]; then
  echo -e "${RED}❌ Entry point lib/main_$FLAVOR.dart not found${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Entry point found: lib/main_$FLAVOR.dart${NC}"

# Check config files
if [ ! -f "lib/config/${FLAVOR}_config.dart" ]; then
  echo -e "${YELLOW}⚠️  Config file lib/config/${FLAVOR}_config.dart not found${NC}"
else
  echo -e "${GREEN}✓ Config file found${NC}"
fi

# Check Android manifests
if [ ! -f "android/app/src/$FLAVOR/AndroidManifest.xml" ]; then
  echo -e "${YELLOW}⚠️  Android manifest for $FLAVOR not found${NC}"
else
  echo -e "${GREEN}✓ Android manifest found${NC}"
fi

# Check Firebase config (only for prod/staging)
if [[ "$FLAVOR" != "dev" ]]; then
  if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${YELLOW}⚠️  google-services.json not found (required for $FLAVOR)${NC}"
  else
    echo -e "${GREEN}✓ Firebase config found (Android)${NC}"
  fi
  
  if [ ! -f "ios/WeGig/GoogleService-Info.plist" ]; then
    echo -e "${YELLOW}⚠️  GoogleService-Info.plist not found (required for $FLAVOR)${NC}"
  else
    echo -e "${GREEN}✓ Firebase config found (iOS)${NC}"
  fi
fi

# ================================================================
# CLEAN BUILD
# ================================================================

echo ""
echo -e "${BLUE}Cleaning build artifacts...${NC}"
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"

# ================================================================
# GET DEPENDENCIES
# ================================================================

echo ""
echo -e "${BLUE}Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"

# ================================================================
# BUILD CONFIGURATION
# ================================================================

echo ""
echo -e "${BLUE}Build configuration:${NC}"
echo -e "  Flavor: ${GREEN}$FLAVOR${NC}"

# Set obfuscation based on flavor
if [ "$FLAVOR" == "dev" ]; then
  OBFUSCATE=""
  echo -e "  Obfuscation: ${YELLOW}disabled (dev mode)${NC}"
else
  OBFUSCATE="--obfuscate --split-debug-info=build/symbols/$FLAVOR"
  echo -e "  Obfuscation: ${GREEN}enabled${NC}"
  echo -e "  Debug symbols: ${GREEN}build/symbols/$FLAVOR${NC}"
fi

# Bundle ID mapping
case "$FLAVOR" in
  dev)
    BUNDLE_ID="com.wegig.wegig.dev"
    ;;
  staging)
    BUNDLE_ID="com.wegig.wegig.staging"
    ;;
  prod)
    BUNDLE_ID="com.wegig.wegig"
    ;;
esac

echo -e "  Bundle ID: ${GREEN}$BUNDLE_ID${NC}"

# ================================================================
# BUILD APK
# ================================================================

echo ""
echo -e "${BLUE}Building APK for $FLAVOR...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"
echo ""

flutter build apk \
  --release \
  --flavor "$FLAVOR" \
  -t "lib/main_$FLAVOR.dart" \
  $OBFUSCATE

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✓ APK build successful!${NC}"
  
  APK_PATH="build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"
  if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}📦 APK location: $APK_PATH${NC}"
    echo -e "${GREEN}📊 APK size: $APK_SIZE${NC}"
  fi
else
  echo -e "${RED}❌ APK build failed${NC}"
  exit 1
fi

# ================================================================
# BUILD AAB (App Bundle for Google Play)
# ================================================================

echo ""
read -p "$(echo -e ${YELLOW}Build AAB for Google Play? [y/N]: ${NC})" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${BLUE}Building AAB for $FLAVOR...${NC}"
  
  flutter build appbundle \
    --release \
    --flavor "$FLAVOR" \
    -t "lib/main_$FLAVOR.dart" \
    $OBFUSCATE
  
  if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ AAB build successful!${NC}"
    
    AAB_PATH="build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"
    if [ -f "$AAB_PATH" ]; then
      AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
      echo -e "${GREEN}📦 AAB location: $AAB_PATH${NC}"
      echo -e "${GREEN}📊 AAB size: $AAB_SIZE${NC}"
    fi
  else
    echo -e "${RED}❌ AAB build failed${NC}"
    exit 1
  fi
fi

# ================================================================
# BUILD SUMMARY
# ================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ BUILD COMPLETE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Flavor: ${GREEN}$FLAVOR${NC}"
echo -e "Bundle ID: ${GREEN}$BUNDLE_ID${NC}"
echo -e "Obfuscation: ${GREEN}$([ -z "$OBFUSCATE" ] && echo "disabled" || echo "enabled")${NC}"
echo ""

if [ "$FLAVOR" != "prod" ]; then
  echo -e "${YELLOW}⚠️  This is a $FLAVOR build. Do NOT publish to production stores.${NC}"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Test the APK on a real device"
echo -e "2. Verify app name and bundle ID"
echo -e "3. Check Firebase configuration"

if [[ "$FLAVOR" == "prod" ]]; then
  echo -e "4. Upload AAB to Google Play Console"
  echo -e "5. Submit to App Store Connect (iOS)"
fi

echo ""
