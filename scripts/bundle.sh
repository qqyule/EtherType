#!/bin/bash
set -e

# 获取版本号，如果没有提供则默认为 "1.0.0"
VERSION=${1:-"0.1.1"}
# 移除版本号可能包含的 'v' 前缀
VERSION=${VERSION#v}

# 获取架构，默认为当前机器架构
HOST_ARCH=$(uname -m)
ARCH=${2:-$HOST_ARCH}

APP_NAME="EtherType"
# SPM 的构建路径会包含架构信息，例如 .build/arm64-apple-macosx/release
BUILD_PATH=".build/$ARCH-apple-macosx/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🚀 开始打包 $APP_NAME v$VERSION ($ARCH)..."

# 1. 编译 Release 版本
echo "🔨 正在编译 ($ARCH)..."
swift build -c release --arch "$ARCH"

# 2. 创建 App Bundle 结构
echo "📂 创建目录结构..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# 3. 复制二进制文件
echo "📦 复制核心文件..."
if [ ! -f "$BUILD_PATH/$APP_NAME" ]; then
    echo "❌ 错误: 找不到编译产物: $BUILD_PATH/$APP_NAME"
    exit 1
fi
cp "$BUILD_PATH/$APP_NAME" "$MACOS/"

# 4. 复制 Info.plist 并更新版本号
# 优先使用 .build 目录生成的 Info.plist (如果有)，否则使用 Sources 中的
if [ -f "$BUILD_PATH/$APP_NAME.o/Info.plist" ]; then
    PLIST_SRC="$BUILD_PATH/$APP_NAME.o/Info.plist"
elif [ -f "Sources/App/Info.plist" ]; then
    PLIST_SRC="Sources/App/Info.plist"
else
    echo "❌ 错误: 找不到 Info.plist"
    exit 1
fi

cp "$PLIST_SRC" "$CONTENTS/Info.plist"

# 更新版本号
# 使用 plutil 更新 Info.plist 需要文件可以写
chmod +w "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS/Info.plist"

# 5. 复制资源文件 (如果有)
echo "📦 复制资源 Bundle..."
# 仅复制对应架构构建目录下的 bundle
find "$BUILD_PATH" -maxdepth 1 -name "*.bundle" -exec cp -r {} "$RESOURCES/" \;

# 6. 设置图标 (可选，如果有 AppIcon.icns)
if [ -f "Assets/AppIcon.icns" ]; then
    cp "Assets/AppIcon.icns" "$RESOURCES/"
fi

# 7. 清理并签名 (Ad-hoc)
echo "📝 应用 Ad-hoc 签名..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ 应用签名完成"

# 8. 打包 DMG
echo "💿 创建 DMG..."
DMG_NAME="$APP_NAME-$VERSION-$ARCH.dmg"
DMG_STAGING="dmg_staging"

# 清理旧文件
rm -rf "$DMG_NAME" "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

# 复制 App 和创建 Applications 软链接
cp -r "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# 生成 DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" -ov -format UDZO "$DMG_NAME"

# 清理临时文件
rm -rf "$DMG_STAGING"

echo "🎉 全部完成!"
echo "   📱 App: $APP_BUNDLE"
echo "   💿 DMG: $DMG_NAME"
