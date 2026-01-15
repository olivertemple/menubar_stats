#!/bin/bash

# Build script for MenuBarStats
# This script builds the MenuBarStats application

set -e

echo "Building MenuBarStats..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This project can only be built on macOS"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: Xcode or Xcode Command Line Tools not found"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# Build the project
xcodebuild \
    -project MenuBarStats.xcodeproj \
    -scheme MenuBarStats \
    -configuration Release \
    -derivedDataPath ./build \
    build

echo "Build complete!"
echo "The application can be found at: ./build/Build/Products/Release/MenuBarStats.app"
echo ""
echo "To install:"
echo "  cp -r ./build/Build/Products/Release/MenuBarStats.app /Applications/"
echo ""
echo "To run:"
echo "  open ./build/Build/Products/Release/MenuBarStats.app"
