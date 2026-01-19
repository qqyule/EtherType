# 开机自启

::: warning 🚧 开发中
此功能正在开发中，预计将在 **v0.2.0** 版本推出。
:::

## 功能概述

开机自启功能将允许 EtherType 在系统启动时自动运行，无需手动打开。

## 计划功能

- **设置面板开关** — 在设置中一键开启/关闭
- **静默启动** — 仅常驻菜单栏，不弹出窗口
- **系统集成** — 使用 macOS 原生 `LaunchAtLogin` 机制

## 技术说明

使用 [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) 库实现，该库已集成到项目中。

## 等待发布

此功能已在开发计划中，你可以：

- ⭐ 关注 [GitHub 仓库](https://github.com/qqyule/EtherType) 获取更新
- 📋 在 [Issues](https://github.com/qqyule/EtherType/issues) 中提出建议
