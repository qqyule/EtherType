// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EtherType",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "EtherType",
            targets: ["EtherType"]
        )
    ],
    dependencies: [
        // 本地语音识别引擎
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
        // 全局快捷键支持
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0"),
        // 开机自启管理
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin.git", from: "5.0.0"),
        // UserDefaults 封装
        .package(url: "https://github.com/sindresorhus/Defaults.git", from: "8.0.0")
    ],
    targets: [
        .executableTarget(
            name: "EtherType",
            dependencies: [
                "WhisperKit",
                "KeyboardShortcuts",
                "LaunchAtLogin",
                "Defaults"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "EtherTypeTests",
            dependencies: ["EtherType"],
            path: "Tests"
        )
    ]
)
