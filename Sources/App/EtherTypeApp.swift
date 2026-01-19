import SwiftUI
import Defaults

/// EtherType 应用入口
/// 作为常驻菜单栏应用运行，无 Dock 图标
@main
struct EtherTypeApp: App {
    /// 应用代理
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 菜单栏图标和下拉菜单
        MenuBarExtra {
            MenuBarView(appState: appDelegate.appState)
        } label: {
            // 菜单栏图标：录音时显示不同状态
            Label {
                Text("EtherType")
            } icon: {
                Image(systemName: appDelegate.appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
                    .symbolEffect(.bounce, value: appDelegate.appState.isRecording)
            }
        }
        
        // 设置窗口
        Settings {
            SettingsView()
        }
    }
}

/// 获取辅助功能检查选项 (非隔离以避免并发警告)
/// 获取辅助功能检查选项 (非隔离以避免并发警告)
private func getAXOptions() -> CFDictionary {
    // kAXTrustedCheckOptionPrompt 的值是 "AXTrustedCheckOptionPrompt"
    // 使用字符串字面量避免 Swift 6 并发检查报错
    return ["AXTrustedCheckOptionPrompt": true] as CFDictionary
}

/// 应用代理
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// 共享的应用状态
    let appState = AppState()
    
    /// 引导窗口 (保持强引用)
    private var onboardingWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[EtherType] 🚀 应用启动")
        
        // 检查辅助功能权限
        let trusted = AXIsProcessTrustedWithOptions(getAXOptions())
        
        print("[EtherType] 🔐 辅助功能权限: \(trusted ? "✅ 已授权" : "❌ 未授权")")
        if !trusted {
            print("[EtherType] ⚠️ 全局快捷键需要辅助功能权限！")
            // 弹窗提示用户
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = NSAlert()
                alert.messageText = "需要辅助功能权限"
                alert.informativeText = "EtherType 需要监听全局快捷键才能正常工作。\n\n请在“系统设置 > 隐私与安全性 > 辅助功能”中授予 EtherType 权限，然后重启应用。"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "打开系统设置")
                alert.addButton(withTitle: "稍后")
                
                if alert.runModal() == .alertFirstButtonReturn {
                     let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                     NSWorkspace.shared.open(url)
                }
            }
        }
        
        print("[EtherType] 引导完成状态: \(Defaults[.onboardingCompleted])")
        
        // 检查是否需要显示引导
        if !Defaults[.onboardingCompleted] {
            print("[EtherType] 📋 需要显示引导页")
            // 延迟弹出窗口
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showOnboardingWindow()
            }
        } else {
            print("[EtherType] ✅ 引导已完成，跳过")
        }
    }
    
    /// 显示引导窗口
    func showOnboardingWindow() {
        print("[EtherType] 🪟 正在创建引导窗口...")
        
        // 如果已有窗口，直接显示
        if let window = onboardingWindow {
            print("[EtherType] 使用现有窗口")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // 创建新窗口
        let contentView = OnboardingView(appState: appState)
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "欢迎使用 EtherType"
        window.identifier = NSUserInterfaceItemIdentifier("onboarding")
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 400, height: 600))
        window.center()
        
        // 确保窗口置顶，防止被其他应用遮挡
        window.level = .floating
        
        // 保持强引用
        self.onboardingWindow = window
        
        // 先激活应用，再显示窗口
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        print("[EtherType] ✅ 引导窗口已显示")
    }
}
