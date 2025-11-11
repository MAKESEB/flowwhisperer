#!/bin/bash

# FlowWhisperer Build Script
set -e

echo "🎙️  Building FlowWhisperer..."

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode command line tools not found. Please install Xcode."
    exit 1
fi

# Clean build directory
echo "🧹 Cleaning build directory..."
rm -rf build/

# Build the app
echo "🔨 Building app..."
xcodebuild -project FlowWhisperer.xcodeproj \
           -scheme FlowWhisperer \
           -configuration Release \
           -derivedDataPath build \
           build

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully!"
    echo "📍 App location: build/Build/Products/Release/FlowWhisperer.app"
else
    echo "❌ Build failed!"
    exit 1
fi

# Create DMG (requires create-dmg)
echo "📦 Creating DMG..."
if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "FlowWhisperer" \
        --volicon "FlowWhisperer/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "FlowWhisperer.app" 175 120 \
        --hide-extension "FlowWhisperer.app" \
        --app-drop-link 425 120 \
        "FlowWhisperer.dmg" \
        "build/Build/Products/Release/"
    
    echo "✅ DMG created: FlowWhisperer.dmg"
else
    echo "⚠️  create-dmg not found. Install with: brew install create-dmg"
    echo "📍 You can manually create a DMG from: build/Build/Products/Release/FlowWhisperer.app"
fi

echo "🎉 Build process complete!"