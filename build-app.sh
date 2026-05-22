#!/usr/bin/env bash
set -euo pipefail

APP_NAME="QuickCapture"
DISPLAY_NAME="Quick Capture"
BUNDLE_ID="com.charliexue.quick-capture"
BUILD_DIR=".build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
INSTALL_DIR="/Applications/$APP_NAME.app"

if [[ "${1:-}" == "install" ]]; then
    if [[ ! -d "$APP_DIR" ]]; then
        echo "No build found at $APP_DIR. Run ./build-app.sh first." >&2
        exit 1
    fi
    if [[ "${2:-}" == "--reset-tcc" ]]; then
        echo "==> resetting Accessibility TCC for $BUNDLE_ID"
        tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true
    fi
    echo "==> installing to $INSTALL_DIR"
    # Overwrite in place rather than rm -rf + cp, to preserve the bundle's
    # on-disk identity for TCC. Quit the running app first if any.
    osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true
    ditto "$APP_DIR" "$INSTALL_DIR"
    echo ""
    echo "Installed: $INSTALL_DIR"
    echo "Launch with: open $INSTALL_DIR"
    echo "If perms got lost, re-run with: ./build-app.sh install --reset-tcc"
    exit 0
fi

echo "==> swift build -c release"
swift build -c release

echo "==> assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp ".build/release/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$DISPLAY_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Quick Capture uses system events for its global hotkey.</string>
</dict>
</plist>
EOF

# Sign with Charlie's Apple Development identity so TCC grants survive
# across rebuilds (TCC matches Apple-signed apps by Team ID + bundle ID,
# not by the per-build cdhash). Fall back to ad-hoc if the identity is
# missing — the resulting build will still run but each rebuild will
# require re-granting Accessibility.
SIGN_IDENTITY="Apple Development: charlie.l.xue@gmail.com (2L525PQAPB)"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "$SIGN_IDENTITY"; then
    codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR" >/dev/null
else
    echo "==> WARNING: '$SIGN_IDENTITY' not found in keychain, falling back to ad-hoc"
    codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

echo ""
echo "Built: $APP_DIR"
echo ""
echo "Run it:"
echo "  open $APP_DIR"
