#!/bin/bash

# Build script for Seam iOS app
# Usage: ./build.sh [device_name]
# Example: ./build.sh "iPhone 16 Pro"

set -e  # Exit on error

# Default device
DEVICE="${1:-iPhone 16 Pro}"

echo "🔨 Building Seam for $DEVICE..."
echo ""

# Build for simulator
xcodebuild \
  -project Seam.xcodeproj \
  -scheme Seam \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath build \
  build

echo ""
echo "✅ Build completed successfully!"
echo "📱 App is ready to run on $DEVICE"