#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🔨 Compiling EasyFinder in release mode..."
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
APP_NAME="EasyFinder"
BUILD_BIN="$BIN_DIR/$APP_NAME"
OUTPUT_APP="$DIR/$APP_NAME.app"

echo "📦 Packaging $OUTPUT_APP from $BUILD_BIN..."
rm -rf "$OUTPUT_APP"
mkdir -p "$OUTPUT_APP/Contents/MacOS"
mkdir -p "$OUTPUT_APP/Contents/Resources"

cp "$BUILD_BIN" "$OUTPUT_APP/Contents/MacOS/$APP_NAME"
cp "$DIR/Resources/Info.plist" "$OUTPUT_APP/Contents/Info.plist"
chmod +x "$OUTPUT_APP/Contents/MacOS/$APP_NAME"

# Copy AppIcon.icns
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$OUTPUT_APP/Contents/Resources/AppIcon.icns"
fi

# Create a clean release zip archive for GitHub Releases
ZIP_NAME="EasyFinder-v2.0.0-macos-arm64.zip"
echo "🗜️ Creating distribution archive $ZIP_NAME..."
rm -f "$DIR/$ZIP_NAME"
zip -r -q "$DIR/$ZIP_NAME" "$APP_NAME.app"

echo "✅ Successfully built $OUTPUT_APP"
echo "✅ Deployment zip archive: $DIR/$ZIP_NAME"
echo "Launch with: open \"$OUTPUT_APP\""
