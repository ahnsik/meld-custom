#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_DIR="$SCRIPT_DIR/meld-for-mac-src"
BUILD_DIR="$SCRIPT_DIR/.build/meld-for-mac"
APP_TEMPLATE="/Applications/Meld.app"
APP_DIR="$SCRIPT_DIR/Meld_for_mac.app"
PYTHON_PACKAGE="$APP_DIR/Contents/Resources/lib/python3.10/site-packages/meld"
BUNDLED_PYTHON="$APP_DIR/Contents/Frameworks/Python.framework/Versions/3.10/Resources/Python.app/Contents/MacOS/Python"

for command in meson ninja xmllint codesign rsync; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "build_meld_for_mac: '$command' 명령이 필요합니다." >&2
        exit 127
    fi
done

if [ ! -d "$APP_TEMPLATE" ]; then
    echo "build_meld_for_mac: $APP_TEMPLATE 이 필요합니다." >&2
    echo "brew install --cask meld" >&2
    exit 127
fi

rm -rf "$BUILD_DIR" "$APP_DIR"
mkdir -p "$BUILD_DIR"

xmllint --noout \
    "$SOURCE_DIR/meld/resources/ui/appwindow.ui" \
    "$SOURCE_DIR/meld/resources/ui/filediff-actions.ui" \
    "$SOURCE_DIR/meld/resources/ui/new-diff-tab.ui"

meson setup "$BUILD_DIR" "$SOURCE_DIR"
meson compile -C "$BUILD_DIR"

ditto "$APP_TEMPLATE" "$APP_DIR"
rm -rf "$PYTHON_PACKAGE"
mkdir -p "$PYTHON_PACKAGE"
rsync -a \
    --include='*/' \
    --include='*.py' \
    --include='COPYING' \
    --include='README' \
    --exclude='*' \
    "$SOURCE_DIR/meld/" "$PYTHON_PACKAGE/"

cp "$SOURCE_DIR/bin/meld" "$PYTHON_PACKAGE/meld"
cp "$BUILD_DIR/meld/conf.py" "$PYTHON_PACKAGE/conf.py"
cp "$SOURCE_DIR/meld/resources/icons/button_copy0.png" \
    "$PYTHON_PACKAGE/button_copy0.png"
cp "$SOURCE_DIR/meld/resources/icons/button_copy1.png" \
    "$PYTHON_PACKAGE/button_copy1.png"
cp "$BUILD_DIR/meld/resources/org.gnome.Meld.gresource" \
    "$APP_DIR/Contents/Resources/share/meld/org.gnome.Meld.gresource"

PLIST="$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy \
    -c "Add :CFBundleDisplayName string Meld_for_mac" "$PLIST" 2>/dev/null ||
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Meld_for_mac" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.ahnsik.MeldForMac" "$PLIST"
/usr/libexec/PlistBuddy \
    -c "Set :CFBundleShortVersionString 3.22.2-for-mac" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string Meld_for_mac" "$PLIST" \
    2>/dev/null ||
    /usr/libexec/PlistBuddy -c "Set :CFBundleName Meld_for_mac" "$PLIST"

env -u PYTHONDONTWRITEBYTECODE \
    "$BUNDLED_PYTHON" -m compileall -q "$PYTHON_PACKAGE"
codesign --force --deep --sign - "$APP_DIR"
chmod 755 "$SCRIPT_DIR/meld_for_mac"

echo "Built $APP_DIR"
echo "Run $SCRIPT_DIR/meld_for_mac"
