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
            Circle()
                .fill(appState.isRecording ? Color.red : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
            
            Text(appState.isRecording ? "正在录音..." : "待机中")
                .font(.headline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    /// 快捷键提示
    @ViewBuilder
    private var shortcutHint: some View {
        HStack {
            Text("快捷键")
                .foregroundStyle(.secondary)
            Spacer()
            Text("⌥ Space")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
    
    /// 操作按钮区域
    @ViewBuilder
    private var actionButtons: some View {
        // 设置按钮
        SettingsLink {
            Label("设置…", systemImage: "gear")
        }
        .keyboardShortcut(",", modifiers: .command)
        
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
