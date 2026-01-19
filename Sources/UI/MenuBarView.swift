import SwiftUI

/// 菜单栏下拉菜单视图
/// 显示应用状态和常用操作
struct MenuBarView: View {
    /// 应用状态引用
    let appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 录音状态指示
            statusSection
            
            Divider()
            
            // 快捷键提示
            shortcutHint
            
            Divider()
            
            // 操作按钮
            actionButtons
        }
    }
    
    /// 状态显示区域
    @ViewBuilder
    private var statusSection: some View {
        HStack(spacing: 8) {
            // 状态指示灯
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.headline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    /// 状态颜色
    private var statusColor: Color {
        if !appState.onboardingCompleted {
            return .orange
        } else if !appState.isModelLoaded {
            return .yellow
        } else if appState.isRecording {
            return .red
        } else if appState.isProcessing {
            return .blue
        } else {
            return .green
        }
    }
    
    /// 状态文字
    private var statusText: String {
        if !appState.onboardingCompleted {
            return "等待初始设置"
        } else if appState.isModelLoading {
            let percent = Int(appState.modelLoadProgress * 100)
            return "模型加载中 \(percent)%"
        } else if !appState.isModelLoaded {
            return "模型未加载"
        } else if appState.isRecording {
            return "正在录音..."
        } else if appState.isProcessing {
            return "识别中..."
        } else {
            return "就绪"
        }
    }
    
    /// 快捷键提示
    @ViewBuilder
    private var shortcutHint: some View {
        HStack {
            Text("按住录音")
                .foregroundStyle(.secondary)
            Spacer()
            Text("⌥ Space")
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    /// 操作按钮区域
    @ViewBuilder
    private var actionButtons: some View {
        // 设置按钮
        SettingsLink {
            Label("设置…", systemImage: "gear")
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Button {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.showOnboardingWindow()
            }
        } label: {
            Label("欢迎页…", systemImage: "hand.wave")
        }
        
        Divider()
        
        // 退出按钮
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("退出 EtherType", systemImage: "power")
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
