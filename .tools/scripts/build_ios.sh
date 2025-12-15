#!/bin/bash
# WeGig iOS Build Script
# Usage: ./scripts/build_ios.sh [dev|staging|prod] [debug|release]

set -e

# Default values
FLAVOR=${1:-dev}
BUILD_MODE=${2:-debug}

# Validate flavor
if [[ ! "$FLAVOR" =~ ^(dev|staging|prod)$ ]]; then
  echo "❌ Invalid flavor: $FLAVOR"
  echo "Usage: $0 [dev|staging|prod] [debug|release]"
  exit 1
fi

# Validate build mode
if [[ ! "$BUILD_MODE" =~ ^(debug|release)$ ]]; then
  echo "❌ Invalid build mode: $BUILD_MODE"
  echo "Usage: $0 [dev|staging|prod] [debug|release]"
  exit 1
fi

echo "🚀 Building WeGig iOS app..."
echo "📦 Flavor: $FLAVOR"
echo "🔨 Mode: $BUILD_MODE"
echo ""

# Navigate to app package
cd "$(dirname "$0")/../packages/app"

# Build command
TARGET="lib/main_${FLAVOR}.dart"

if [ "$BUILD_MODE" == "debug" ]; then
  flutter build ios --debug --no-codesign -t "$TARGET"
else
  flutter build ios --release -t "$TARGET"
fi

echo ""
echo "✅ iOS build completed successfully!"
echo "📍 Output: packages/app/build/ios/iphoneos/"
