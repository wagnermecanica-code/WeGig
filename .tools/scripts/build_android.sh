#!/bin/bash
# WeGig Android Build Script
# Usage: ./scripts/build_android.sh [dev|staging|prod] [debug|release]

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

echo "🚀 Building WeGig Android app..."
echo "📦 Flavor: $FLAVOR"
echo "🔨 Mode: $BUILD_MODE"
echo ""

# Navigate to app package
cd "$(dirname "$0")/../packages/app"

# Build command
TARGET="lib/main_${FLAVOR}.dart"

if [ "$BUILD_MODE" == "debug" ]; then
  flutter build apk --debug --flavor "$FLAVOR" -t "$TARGET"
else
  flutter build apk --release --flavor "$FLAVOR" -t "$TARGET"
fi

echo ""
echo "✅ Android build completed successfully!"
echo "📍 Output: packages/app/build/app/outputs/flutter-apk/"
