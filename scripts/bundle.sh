#!/bin/bash
set -e

# 获取版本号，如果没有提供则默认为 "1.0.0"
VERSION=${1:-"1.0.0"}
# 移除版本号可能包含的 'v' 前缀
VERSION=${VERSION#v}

APP_NAME="EtherType"
BUILD_PATH=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🚀 开始打包 $APP_NAME v$VERSION..."

# 1. 编译 Release 版本
echo "🔨 正在编译..."
swift build -c release

# 2. 创建 App Bundle 结构
echo "📂 创建目录结构..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# 3. 复制二进制文件
echo "📦 复制核心文件..."
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
# 如果有 Assets.xcassets，这里需要编译它。目前项目似乎只作为 SPM 包。
# 如果 WhisperKit 等依赖有资源 bundle，需要处理。
# 简易处理：将 .build/release 目录下所有的 .bundle 复制到 Plugins 或 Resources
# SwiftPM 通常会将资源打包成 .bundle
echo "📦 复制资源 Bundle..."
find "$BUILD_PATH" -maxdepth 1 -name "*.bundle" -exec cp -r {} "$RESOURCES/" \;

# 6. 设置图标 (可选，如果有 AppIcon.icns)
if [ -f "Assets/AppIcon.icns" ]; then
    cp "Assets/AppIcon.icns" "$RESOURCES/"
fi

# 7. 清理并签名 (Ad-hoc)
# 这对于本地运行是必要的，可以防止 crash，也能让系统识别
echo "📝 应用 Ad-hoc 签名..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ 打包完成: $APP_BUNDLE"
