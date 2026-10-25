#!/bin/bash
# Builds CinemaHUD.app (release) and packages it into build/CinemaHUD-<version>.dmg.
# The version and build number come from Resources/Info.plist, so the file name and the
# volume name Finder shows always say which build this is.
set -euo pipefail
cd "$(dirname "$0")/.."
APP_NAME=CinemaHUD
BUILD=build
PLIST=Resources/Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST")
APP="$BUILD/$APP_NAME.app"
DMG="$BUILD/$APP_NAME-$VERSION.dmg"
VOLNAME="$APP_NAME $VERSION"

echo "▸ 版本 $VERSION（构建号 $BUILD_NUMBER）"

echo "▸ 正在以发布模式编译 Swift 应用"
swift build -c release --product "$APP_NAME" 2>&1 | grep -E "error|warning: unre|Compiling|Build complete" || true
BIN="$(swift build -c release --product "$APP_NAME" --show-bin-path)/$APP_NAME"
test -x "$BIN"

echo "▸ 正在组装 $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources/zh-Hans.lproj"
cp Resources/zh-Hans.lproj/Localizable.strings "$APP/Contents/Resources/zh-Hans.lproj/Localizable.strings"
echo -n "APPL????" > "$APP/Contents/PkgInfo"
if [ -f design/icon/AppIcon.icns ]; then cp design/icon/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"; else python3 scripts/make-icon.py "$APP/Contents/Resources/AppIcon.icns"; fi

echo "▸ 正在进行临时签名"
codesign --force --deep --sign - --timestamp=none "$APP"
codesign --verify --verbose=2 "$APP" 2>&1 | tail -1

echo "▸ 正在创建 DMG 安装镜像"
STAGE="$BUILD/dmg-stage"
rm -rf "$STAGE" "$DMG"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
# Older builds wrote an unversioned CinemaHUD.dmg; remove it so the newest file is unambiguous.
rm -f "$BUILD/$APP_NAME.dmg"
echo "✔ $DMG ($(du -h "$DMG" | cut -f1)) — mounts as \"$VOLNAME\""
