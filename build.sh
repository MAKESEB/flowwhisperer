#!/bin/bash

# FlowWhisperer Build Script
set -e

echo "🎙️  Building FlowWhisperer..."

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found. Please install Xcode command line tools."
    exit 1
fi

# Clean build directory
echo "🧹 Cleaning build directory..."
rm -rf .build/
rm -rf FlowWhisperer/build/

# Build the app with Swift Package Manager
echo "🔨 Building app with Swift Package Manager..."
swift build -c release

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✅ Swift build completed successfully!"
else
    echo "❌ Swift build failed!"
    exit 1
fi

# Create app bundle structure manually
echo "📦 Creating app bundle..."
APP_DIR="FlowWhisperer/build/FlowWhisperer.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Create directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp .build/release/FlowWhisperer "$MACOS_DIR/"

# Copy Info.plist
cp FlowWhisperer/Resources/Info.plist "$CONTENTS_DIR/"

# Copy icon
if [ -f "FlowWhisperer/Resources/AppIcon.icns" ]; then
    cp FlowWhisperer/Resources/AppIcon.icns "$RESOURCES_DIR/"
fi

# Make executable
chmod +x "$MACOS_DIR/FlowWhisperer"

echo "✅ App bundle created: $APP_DIR"

# Create DMG (requires create-dmg)
echo "📦 Creating DMG..."
if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "FlowWhisperer-FIXED" \
        --volicon "FlowWhisperer/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "FlowWhisperer.app" 175 120 \
        --hide-extension "FlowWhisperer.app" \
        --app-drop-link 425 120 \
        "FlowWhisperer-FIXED.dmg" \
        "FlowWhisperer/build/"
    
    echo "✅ DMG created: FlowWhisperer-FIXED.dmg"
else
    echo "⚠️  create-dmg not found. Install with: brew install create-dmg"
    echo "📍 You can manually create a DMG from: FlowWhisperer/build/FlowWhisperer.app"
fi

echo "🎉 Build process complete!"