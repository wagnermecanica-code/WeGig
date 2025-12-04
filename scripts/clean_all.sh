#!/bin/bash
# WeGig Clean Script
# Cleans all build artifacts and caches across the monorepo

set -e

echo "🧹 Cleaning WeGig monorepo..."
echo ""

# Clean root
echo "📦 Cleaning root..."
cd "$(dirname "$0")/.."
flutter clean

# Clean app package
echo "📦 Cleaning packages/app..."
cd packages/app
flutter clean
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -f ios/Podfile.lock

# Clean core_ui package
echo "📦 Cleaning packages/core_ui..."
cd ../core_ui
flutter clean

# Clear build_runner cache
echo "🗑️  Clearing build_runner cache..."
cd ../app
flutter packages pub run build_runner clean

# Clear DerivedData (iOS only)
if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
  echo "🗑️  Clearing Xcode DerivedData..."
  rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
fi

echo ""
echo "✅ Clean completed successfully!"
echo ""
echo "Next steps:"
echo "  1. cd packages/app"
echo "  2. flutter pub get"
echo "  3. cd ios && pod install"
