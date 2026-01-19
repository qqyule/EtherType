# 模型说明

EtherType 使用 [WhisperKit](https://github.com/argmaxinc/WhisperKit) 进行本地语音识别，支持多种模型。

## 可用模型

| 模型 | 大小 | 特点 | 推荐场景 |
|------|------|------|----------|
| **Small** | ~500MB | 速度快，资源占用低 | 日常使用 ✅ |
| **Large V3** | ~3GB | 精度更高，识别更准 | 专业场景 |

## 切换模型

1. 点击菜单栏中的 EtherType 图标
2. 选择「设置」
3. 在「模型」选项卡中选择目标模型
4. 等待模型下载完成

::: tip
首次切换模型需要下载，请确保网络畅通。下载完成后，模型会缓存在本地。
:::

## 模型对比

### Small 模型

- ⚡ 推理速度快，适合快速输入
- 📱 内存占用约 500MB
- 🎯 日常对话、短消息足够准确
- 🔋 功耗更低

### Large V3 模型

- 🎯 识别精度更高
- 🌍 多语言混合识别更强
- 📱 内存占用约 3GB
- ⏱️ 处理时间稍长

## 技术细节

所有模型都经过 Apple Neural Engine 优化，在 Apple Silicon Mac 上可以获得最佳性能。

模型文件存储在：
```
~/Library/Application Support/EtherType/Models/
```
