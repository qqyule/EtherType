# 📝 Project PRD: EtherType (暂定名)

**定位：** macOS 原生、极简、本地优先的 AI 语音输入工具。

## 1. 项目愿景 (Vision)

打造 GitHub 上体验最好的 macOS 本地语音输入开源项目。

* **Privacy First:** 0% 数据上传，完全依赖本地算力（Apple Neural Engine）。
* **Native & Modern:** 遵循 Apple Human Interface Guidelines，适配 macOS 2026 "Fluid & Spatial" 设计语言。
* **Lightweight:** 极致的资源优化，后台静默时 CPU 占用近乎为零。

## 2. 核心功能 (MVP Scope)

### 2.1 交互模式 (The "Walkie-Talkie" Flow)

* **触发机制：** 用户**按住**全局快捷键（默认 `Option + Space`）开始录音。
* **视觉反馈：** 屏幕中央出现一个极简的 **Floating HUD (悬浮胶囊)**，显示动态声波，表示正在聆听。
* **处理机制：** 用户**松开**快捷键，录音结束。后台通过 `WhisperKit` 进行推理。
* **输出机制：** 文字生成后，自动模拟键盘输入（Typewriter Effect）或粘贴（Pasteboard Injection）到当前活跃窗口的光标处。

### 2.2 智能模型 (Intelligence)

* **核心引擎：** 集成 `Argmax/WhisperKit`。
* **语言支持：** 自动识别中/英文（Auto-detect），支持中英混输。
* **模型管理：**
* 首次启动自动下载量化模型（推荐 `whisper-base` 或 `whisper-small` 8-bit 量化版），平衡速度与精度。
* 提供“下载进度”的可视化反馈。



### 2.3 系统集成

* **Menu Bar Extra：** 常驻菜单栏，无 Dock 图标。
* **资源优化：** 模型加载后常驻内存（为了速度），但在不使用时挂起推理线程，降低功耗。

---

## 3. UI/UX 设计规范 (macOS 2026 Style)

### 3.1 设计哲学：Invisible Interface

软件应“招之即来，挥之即去”。

### 3.2 关键界面组件

1. **The HUD (录音悬浮窗):**
* **形态：** 类似于 iPhone 的“灵动岛”或 Vision Pro 的玻璃质感悬浮条。
* **位置：** 屏幕正下方或跟随光标（可配置）。
* **动效：**
* *按住时：* 出现并在内部显示随音量跳动的波形（Siri 风格，但更克制，单色或渐变色）。
* *松开时：* 变为“加载/转圈”动画（<0.5s）。
* *完成时：* 迅速收缩消失。


* **材质：** `UltraThinMaterial` (高斯模糊玻璃)，圆角极大（Capsule shape）。


2. **Settings Window (设置面板):**
* **风格：** 标准 macOS Settings 风格，左侧 Sidebar，右侧内容。
* **内容：**
* **General:** 开机自启、隐藏 HUD 选项。
* **Shortcuts:** 快捷键录制（使用 `KeyboardShortcuts` 提供的原生控件）。
* **Models:** 当前模型显示，重新下载/切换模型（Base/Small/Turbo）。
* **About:** GitHub 链接、版本号、License 声明。





---

## 4. 技术架构与开源规范 (Technical Specs)

### 4.1 技术栈

* **语言:** Swift 6.0
* **UI 框架:** SwiftUI
* **架构模式:** MVVM + Observation (Swift 5.9+ Macro)
* **核心库:**
* `WhisperKit`: 本地推理。
* `KeyboardShortcuts`: 全局快捷键监听。
* `Defaults`: 极简的 UserDefaults 封装（用于设置存储）。
* `LaunchAtLogin`: 开机自启管理。



### 4.2 目录结构 (GitHub Standard)

为了符合开源规范，Antigravity 生成代码时需遵循此结构：

```text
EtherType/
├── .github/
│   ├── workflows/          # CI/CD (Build & Test)
│   └── ISSUE_TEMPLATE/     # Bug report & Feature request templates
├── Assets/                 # AppIcon, Screenshots (for README)
├── Sources/
│   ├── App/                # App entry point, AppDelegate
│   ├── Core/               # AudioEngine, WhisperManager
│   ├── UI/                 # HUDView, SettingsView, MenuBar
│   └── Utils/              # Permissions, PasteboardHelper
├── Tests/                  # Unit Tests
├── Docs/                   # Developer documentation
├── LICENSE                 # MIT License
├── README.md               # 详细的项目介绍
└── Package.swift           # Swift Package Manager definition

```

### 4.3 关键实现难点与方案

1. **权限处理 (Permissions):**
* 必须在 `Info.plist` 优雅处理 `NSMicrophoneUsageDescription` 和 `Accessibility` 权限。
* **首次启动体验 (Onboarding):** 第一次打开 App 时，展示一个引导页，引导用户授予“辅助功能”权限（用于模拟键盘输入）。


2. **文本注入 (Text Injection):**
* **方案 A (推荐):** 使用 `AXUIElement` (Accessibility API) 直接写入当前文本框。
* **方案 B (兼容性):** 将文本写入剪贴板 (`NSPasteboard`), 然后通过 `CGEvent` 模拟 `Cmd+V` 按下。
* *策略:* 优先 A，失败降级为 B。


3. **Qwen 集成 (Future Feature/Plugin):**
* 虽然 MVP 仅使用 Whisper，但在代码中预留 `PostProcessor` 协议。
* 未来允许用户配置本地 Ollama 接口，将 Whisper 的结果传给 Qwen 做“润色”后再输出。



---

## 5. 开发路线图 (Roadmap for Antigravity)

将此 Roadmap 喂给 Agent，让它分步执行：

* **Step 1: Scaffold & Infrastructure**
* 初始化 SPM 项目。
* 设置 MenuBar 模式 (`LSUIElement = YES`)。
* 集成 `KeyboardShortcuts` 并跑通“按下打印 Log”的流程。


* **Step 2: The Ear (WhisperKit)**
* 集成 WhisperKit。
* 实现音频流捕获 (`AVAudioEngine`)。
* 实现 VAD (Voice Activity Detection) 逻辑（可选，或仅依赖按键释放）。
* **里程碑：** 按住说话，松开后在控制台打印出准确的文字。


* **Step 3: The Hand (Injection)**
* 实现 `Accessibility` 注入逻辑。
* 处理权限请求弹窗。


* **Step 4: The Face (UI)**
* 实现悬浮 HUD。
* 设计动态声波动画（使用 SwiftUI Canvas 或 Charts）。
* 构建设置页面。


* **Step 5: Open Source Polish**
* 添加 License。
* 生成 README（Antigravity 可以帮你写）。
* 代码格式化（SwiftLint）。
