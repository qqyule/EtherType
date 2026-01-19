# 安装

## 系统要求

| 项目 | 最低要求 |
|------|----------|
| macOS | 15.0 (Sequoia) 或更高 |
| 芯片 | Apple Silicon (M1/M2/M3/M4) 推荐 |
| 存储 | 至少 1GB 可用空间 |

::: warning 注意
目前仅支持 Apple Silicon Mac。Intel Mac 的兼容性尚在测试中。
:::

## 从 Release 安装

最简单的方式是直接下载预编译版本：

1. 访问 [Releases 页面](https://github.com/qqyule/EtherType/releases)
2. 下载对应架构的 `.dmg` 文件
3. 双击打开，拖拽到 `Applications`
4. 首次打开时，右键选择「打开」以跳过 Gatekeeper

## 从源码构建

适合开发者或想要自定义的用户：

```bash
# 克隆仓库
git clone https://github.com/qqyule/EtherType.git
cd EtherType

# 构建
swift build -c release

# 运行
./.build/release/EtherType
```

## 权限配置

EtherType 需要以下权限才能正常工作：

### 麦克风权限

用于录制语音。首次使用时系统会自动弹出授权请求。

### 辅助功能权限

用于将文字输入到其他应用。需要手动在系统设置中授权：

1. 打开「系统设置」→「隐私与安全性」→「辅助功能」
2. 点击「+」添加 EtherType
3. 确保开关已打开

::: tip
如果文字无法输入到某些应用，请检查辅助功能权限是否已正确授予。
:::
