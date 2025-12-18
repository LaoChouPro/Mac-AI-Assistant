#!/bin/bash

APP_NAME="FastCallAI"
BUNDLE_ID="com.laochou.FastCallAI"
OUTPUT_DIR="build"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"

# 1. Build
echo "Building Release..."
swift build -c release

# 2. Create Structure
echo "Creating .app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy Binary
cp .build/release/$APP_NAME "$APP_BUNDLE/Contents/MacOS/"

# 4. Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 5. Ad-hoc Sign
echo "Signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Done! App is at $APP_BUNDLE"
