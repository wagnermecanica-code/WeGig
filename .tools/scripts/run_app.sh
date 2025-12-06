#!/bin/bash
# WeGig Run Script
# Usage: ./scripts/run_app.sh [dev|staging|prod] [device-id]

set -e

# Default values
FLAVOR=${1:-dev}
DEVICE_ID=${2}

# Validate flavor
if [[ ! "$FLAVOR" =~ ^(dev|staging|prod)$ ]]; then
  echo "❌ Invalid flavor: $FLAVOR"
  echo "Usage: $0 [dev|staging|prod] [device-id]"
  exit 1
fi

echo "🚀 Running WeGig app..."
echo "📦 Flavor: $FLAVOR"
if [ -n "$DEVICE_ID" ]; then
  echo "📱 Device: $DEVICE_ID"
fi
echo ""

# Navigate to app package
cd "$(dirname "$0")/../packages/app"

# Run command
TARGET="lib/main_${FLAVOR}.dart"

if [ -n "$DEVICE_ID" ]; then
  flutter run -t "$TARGET" --device-id="$DEVICE_ID"
else
  flutter run -t "$TARGET"
fi
