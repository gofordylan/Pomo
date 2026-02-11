#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Pomo"
BUNDLE_ID="com.pomo.app"
APP_DIR="$SCRIPT_DIR/$APP_NAME.app"
DMG_DIR="$SCRIPT_DIR/dist"
DMG_PATH="$DMG_DIR/$APP_NAME.dmg"
ICNS_PATH="$SCRIPT_DIR/$APP_NAME.icns"

# ── Code signing & notarization config ──────────────────────────────
# Fill these in after enrolling in the Apple Developer Program ($99/yr).
# Then run:  ./build.sh sign
#
# DEVELOPER_ID  — Find via:  security find-identity -v -p codesigning
#                 Looks like: "Developer ID Application: Your Name (XXXXXXXXXX)"
# APPLE_ID      — Your Apple ID email
# TEAM_ID       — Your 10-character Team ID (developer.apple.com → Membership)
# NOTARIZE_PASS — App-specific password stored in keychain. Create at
#                 appleid.apple.com → Sign-In and Security → App-Specific Passwords
#                 Then store:  xcrun notarytool store-credentials "AC_PASSWORD" \
#                                --apple-id "dylanmichaelbrodeur@gmail.com" --team-id "$TEAM_ID"
DEVELOPER_ID="${DEVELOPER_ID:-}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
NOTARIZE_PROFILE="${NOTARIZE_PROFILE:-AC_PASSWORD}"

SIGN_MODE="adhoc"
if [[ "${1:-}" == "sign" ]]; then
    if [[ -z "$DEVELOPER_ID" ]]; then
        echo "Error: Set DEVELOPER_ID env var or edit build.sh to use 'sign' mode."
        echo "  Example: DEVELOPER_ID='Developer ID Application: ...' ./build.sh sign"
        exit 1
    fi
    SIGN_MODE="developer"
fi

# ── Generate app icon ───────────────────────────────────────────────
if [[ ! -f "$ICNS_PATH" ]]; then
    echo "Generating app icon..."
    swift "$SCRIPT_DIR/scripts/generate-icon.swift" "$SCRIPT_DIR"
fi

# ── Build universal binary (Apple Silicon + Intel) ──────────────────
echo "Building $APP_NAME for arm64..."
swift build -c release --arch arm64

echo "Building $APP_NAME for x86_64..."
swift build -c release --arch x86_64

echo "Creating universal binary..."
mkdir -p .build/universal
lipo -create \
    .build/arm64-apple-macosx/release/$APP_NAME \
    .build/x86_64-apple-macosx/release/$APP_NAME \
    -output .build/universal/$APP_NAME

# ── Create app bundle ───────────────────────────────────────────────
echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp .build/universal/$APP_NAME "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ICNS_PATH" "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Pomo</string>
    <key>CFBundleDisplayName</key>
    <string>Pomo</string>
    <key>CFBundleIdentifier</key>
    <string>com.pomo.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Pomo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSUserNotificationAlertStyle</key>
    <string>alert</string>
</dict>
</plist>
PLIST

# ── Code sign ───────────────────────────────────────────────────────
if [[ "$SIGN_MODE" == "developer" ]]; then
    echo "Signing with Developer ID..."
    codesign --force --options runtime --timestamp \
        --sign "$DEVELOPER_ID" "$APP_DIR"
else
    echo "Ad-hoc signing (use './build.sh sign' for Developer ID signing)..."
    codesign --force --deep --sign - "$APP_DIR"
fi

# ── Create DMG ──────────────────────────────────────────────────────
echo "Creating DMG..."
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

TEMP_DMG="$DMG_DIR/temp.dmg"
rm -f "$DMG_PATH" "$TEMP_DMG"

STAGING="$DMG_DIR/staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -r "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" \
    -ov -format UDRW "$TEMP_DMG" > /dev/null

hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_PATH" > /dev/null
rm -f "$TEMP_DMG"
rm -rf "$STAGING"

# ── Sign & notarize DMG ────────────────────────────────────────────
if [[ "$SIGN_MODE" == "developer" ]]; then
    echo "Signing DMG..."
    codesign --force --sign "$DEVELOPER_ID" "$DMG_PATH"

    if [[ -n "$APPLE_ID" && -n "$TEAM_ID" ]]; then
        echo "Submitting for notarization (this may take a few minutes)..."
        xcrun notarytool submit "$DMG_PATH" \
            --keychain-profile "$NOTARIZE_PROFILE" \
            --wait

        echo "Stapling notarization ticket..."
        xcrun stapler staple "$DMG_PATH"
    else
        echo ""
        echo "Skipping notarization — set APPLE_ID and TEAM_ID to enable."
    fi
fi

# ── Done ────────────────────────────────────────────────────────────
echo ""
echo "Done!"
echo "  App:  $APP_DIR"
echo "  DMG:  $DMG_PATH"
echo ""
if [[ "$SIGN_MODE" == "developer" ]]; then
    echo "App is signed and notarized — ready to distribute!"
else
    echo "To run:  open $APP_DIR"
    echo ""
    echo "Current build is ad-hoc signed. Users will need to:"
    echo "  Right-click the app → Open → Open (bypasses Gatekeeper)"
    echo ""
    echo "To distribute without the malware warning:"
    echo "  1. Enroll at https://developer.apple.com/programs/ (\$99/yr)"
    echo "  2. Create a Developer ID certificate in Xcode → Settings → Accounts"
    echo "  3. Run: DEVELOPER_ID='Developer ID Application: ...' ./build.sh sign"
fi
