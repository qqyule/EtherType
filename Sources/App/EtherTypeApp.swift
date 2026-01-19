import SwiftUI

/// EtherType 应用入口
/// 作为常驻菜单栏应用运行，无 Dock 图标
@main
struct EtherTypeApp: App {
    /// 全局应用状态
    @State private var appState = AppState()
    
    var body: some Scene {
        // 菜单栏图标和下拉菜单
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            // 菜单栏图标：录音时显示不同状态
            Label {
                Text("EtherType")
            } icon: {
                Image(systemName: appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
            }
        }
        
        // 设置窗口
        Settings {
            SettingsView()
        }
    }
}
