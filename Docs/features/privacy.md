# 隐私说明

EtherType 的核心设计原则是 **隐私优先**。

## 承诺

### ✅ 我们做的

- **完全本地推理** — 所有语音识别都在你的 Mac 上完成
- **数据不外传** — 没有服务器，没有云端，没有账号
- **开源透明** — 代码完全开源，接受审查

### ❌ 我们不做的

- ❌ 不上传你的语音
- ❌ 不收集使用数据
- ❌ 不追踪用户行为
- ❌ 不需要注册/登录

## 技术实现

### 语音识别

使用 [WhisperKit](https://github.com/argmaxinc/WhisperKit)，这是一个完全离线的语音识别引擎。

- 模型运行在 Apple Neural Engine 上
- 音频数据仅在内存中处理
- 识别完成后立即释放

### 文字注入

使用 macOS 原生 Accessibility API 将文字输入到目标应用。

- 使用 `AXUIElement` 直接写入
- 失败时降级为剪贴板粘贴
- 不会修改你的剪贴板历史（除非降级）

### 数据存储

EtherType 仅在本地存储：

| 数据 | 位置 | 用途 |
|------|------|------|
| 设置 | UserDefaults | 快捷键、模型选择 |
| 模型 | Application Support | 语音识别模型文件 |

::: tip
所有数据都存储在你的 Mac 上，卸载应用时可以一并删除。
:::

## 开源审计

EtherType 是完全开源的项目：

- 📦 源代码：[GitHub](https://github.com/yourusername/EtherType)
- 📜 许可证：MIT License

欢迎审查代码，提出问题或建议。
