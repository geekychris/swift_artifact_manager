#!/bin/bash
# Launch the native macOS version of ArtifactCollector

# Kill any running instances
killall ArtifactCollector 2>/dev/null

# Find and launch the macOS app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/ArtifactCollector-*/Build/Products/Debug -name "ArtifactCollector.app" -not -path "*/Debug-iphoneos/*" -not -path "*/Debug-iphonesimulator/*" | head -1)

if [ -n "$APP_PATH" ]; then
    echo "Launching native macOS app from: $APP_PATH"
    open "$APP_PATH"
else
    echo "Error: Could not find the macOS app. Please build it first with:"
    echo "  xcodebuild -project ArtifactCollector.xcodeproj -scheme ArtifactCollector_macOS build"
fi
