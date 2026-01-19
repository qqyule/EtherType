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
        // 全局快捷键支持 (锁定 v1.10.0 避免 #Preview 宏兼容问题)
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", exact: "1.10.0"),
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
            path: "Sources",
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Sources/App/Info.plist"])
            ]
        ),
        .testTarget(
            name: "EtherTypeTests",
            dependencies: ["EtherType"],
            path: "Tests"
        )
    ]
)
