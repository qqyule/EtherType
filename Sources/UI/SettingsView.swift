import SwiftUI
import KeyboardShortcuts
import Defaults
import LaunchAtLogin

/// 设置页面视图
/// 提供快捷键自定义、模型选择、通用设置等功能
struct SettingsView: View {
    var body: some View {
        TabView {
            // 通用设置
            GeneralSettingsTab()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            // 模型设置
            ModelSettingsTab()
                .tabItem {
                    Label("模型", systemImage: "cpu")
                }
            
            // 快捷键设置
            ShortcutsSettingsTab()
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }
            
            // 关于页面
            AboutSettingsTab()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 300)
        .onAppear {
            // 激活应用程序，确保设置窗口置顶
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - 通用设置

/// 通用设置标签页
struct GeneralSettingsTab: View {
    /// 开机自启状态（与系统同步）
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    
    var body: some View {
        Form {
            // 开机自启开关
            Toggle("开机时自动启动", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    LaunchAtLogin.isEnabled = newValue
                    print("[Settings] 开机自启设置: \(newValue)")
                }
            
            Text("启用后，系统重启时将自动运行 EtherType")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding()
        .onAppear {
            // 同步系统状态
            launchAtLogin = LaunchAtLogin.isEnabled
        }
    }
}

// MARK: - 模型设置

/// 模型设置标签页
struct ModelSettingsTab: View {
    /// 当前选择的模型
    @Default(.selectedWhisperModel) private var selectedModel
    
    /// 是否显示切换确认对话框
    @State private var showSwitchConfirmation = false
    
    /// 待切换的目标模型
    @State private var pendingModel: WhisperModel?
    
    /// 获取 AppState（通过 Environment 注入）
    @Environment(AppState.self) private var appState: AppState?
    
    var body: some View {
        Form {
            // 模型选择
            Section {
                Picker("语音识别模型", selection: $selectedModel) {
                    ForEach(WhisperModel.allCases) { model in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(model.displayName)
                                    if model.isRecommended {
                                        Text("推荐")
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text("\(model.sizeDescription) · \(model.description)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .tag(model)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: selectedModel) { oldValue, newValue in
                    if oldValue != newValue {
                        pendingModel = newValue
                        showSwitchConfirmation = true
                        // 恢复旧值，等待确认
                        selectedModel = oldValue
                    }
                }
            }
            
            // 当前状态
            Section {
                if let appState = appState {
                    HStack {
                        Text("当前模型")
                        Spacer()
                        if appState.isModelLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                Text("\(Int(appState.modelLoadProgress * 100))%")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text(appState.currentModelName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // 错误提示
                    if let error = appState.modelLoadError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Text("切换模型需要重新下载，Large V3 模型约 3GB，请确保网络畅通")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding()
        .confirmationDialog(
            "切换模型",
            isPresented: $showSwitchConfirmation,
            titleVisibility: .visible
        ) {
            Button("确认切换到 \(pendingModel?.displayName ?? "")") {
                if let model = pendingModel {
                    selectedModel = model
                    appState?.switchModel(to: model)
                }
                pendingModel = nil
            }
            Button("取消", role: .cancel) {
                pendingModel = nil
            }
        } message: {
            if let model = pendingModel {
                Text("将切换到 \(model.displayName) 模型（\(model.sizeDescription)），需要重新下载。")
            }
        }
    }
}

// MARK: - 快捷键设置

/// 快捷键设置标签页
struct ShortcutsSettingsTab: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("录音快捷键:", name: .toggleRecording)
            
            Text("按住此快捷键开始录音，松开停止并转换文字")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding()
    }
}

// MARK: - 关于页面

/// 关于信息标签页
struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 16) {
            // 应用图标占位
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("EtherType")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("版本 0.1.0")
                .foregroundStyle(.secondary)
            
            Text("极简、隐私优先的本地语音输入工具")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // GitHub 链接
            Link(destination: URL(string: "https://github.com/qqyule/EtherType")!) {
                Label("GitHub 开源", systemImage: "link")
            }
            .buttonStyle(.link)
        }
        .padding()
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
