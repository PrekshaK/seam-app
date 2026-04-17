#!/bin/bash

# Run script for Seam iOS app
# Usage: ./run.sh [device_name]
# Example: ./run.sh "iPhone 16 Pro"

set -e  # Exit on error

# Default device
DEVICE="${1:-iPhone 16 Pro}"

echo "🚀 Building and running Seam on $DEVICE..."
echo ""

# Build and run
xcodebuild \
  -project Seam.xcodeproj \
  -scheme Seam \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath build \
  clean build

# Find the app bundle
APP_PATH=$(find build/Build/Products/Debug-iphonesimulator -name "Seam.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
  echo "❌ Error: Could not find Seam.app"
  exit 1
fi

echo ""
echo "📱 Starting simulator..."

# Boot the simulator if not already running
DEVICE_UUID=$(xcrun simctl list devices available | grep "$DEVICE" | head -n 1 | grep -o '[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}')

if [ -z "$DEVICE_UUID" ]; then
  echo "❌ Error: Device '$DEVICE' not found"
  echo "Available devices:"
  xcrun simctl list devices available | grep iPhone | grep -o '"iPhone[^"]*"' | tr -d '"'
  exit 1
fi

# Boot simulator
xcrun simctl boot "$DEVICE_UUID" 2>/dev/null || true

# Open Simulator app
open -a Simulator

# Wait a moment for simulator to be ready
sleep 2

# Install and launch the app
echo "📲 Installing app..."
xcrun simctl install "$DEVICE_UUID" "$APP_PATH"

echo "🎉 Launching Seam..."
xcrun simctl launch "$DEVICE_UUID" com.prekshakoirala.Seam

echo ""
echo "✅ Seam is now running on $DEVICE!"