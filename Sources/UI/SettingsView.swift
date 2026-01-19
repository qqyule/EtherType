import SwiftUI
import KeyboardShortcuts

/// 设置页面视图
/// 提供快捷键自定义、通用设置等功能
struct SettingsView: View {
    var body: some View {
        TabView {
            // 通用设置
            GeneralSettingsTab()
                .tabItem {
                    Label("通用", systemImage: "gear")
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
        .frame(width: 450, height: 250)
    }
}

// MARK: - 通用设置

/// 通用设置标签页
struct GeneralSettingsTab: View {
    var body: some View {
        Form {
            // 开机自启（占位，后续实现）
            Toggle("开机时自动启动", isOn: .constant(false))
                .disabled(true)
            
            Text("更多设置将在后续版本中添加")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding()
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
            Link(destination: URL(string: "https://github.com/yourusername/EtherType")!) {
                Label("GitHub 开源", systemImage: "link")
            }
            .buttonStyle(.link)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
