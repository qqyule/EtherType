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
    
    /// HUD 悬浮窗口
    private var hudWindow: NSWindow?
    
    /// HUD 显示状态跟踪
    private var lastHUDState: Bool = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[EtherType] 🚀 应用启动")
        
        // 检查辅助功能权限
        let trusted = AXIsProcessTrustedWithOptions(getAXOptions())
        
        print("[EtherType] 🔐 辅助功能权限: \(trusted ? "✅ 已授权" : "❌ 未授权")")
        // 移除启动时的强制弹窗，改为在引导页中引导用户授权
                
        print("[EtherType] 引导完成状态: \(Defaults[.onboardingCompleted])")
        
        // 检查是否需要显示引导 (未完成引导 OR 权限丢失)
        if !Defaults[.onboardingCompleted] || !trusted {
            print("[EtherType] 📋 需要显示引导页 (引导未完成 或 权限缺失)")
            // 延迟弹出窗口
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showOnboardingWindow()
            }
        } else {
            print("[EtherType] ✅ 引导已完成且权限正常，跳过")
        }
        
        // 设置 HUD 窗口
        setupHUDWindow()
        
        // 监听 showHUD 状态变化
        observeHUDState()
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
    
    // MARK: - HUD 窗口管理
    
    /// 初始化 HUD 窗口
    private func setupHUDWindow() {
        let hudView = HUDView(appState: appState)
        let hostingController = NSHostingController(rootView: hudView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = NSUserInterfaceItemIdentifier("hud")
        
        // 无标题栏、透明、不可调整大小
        window.styleMask = [.borderless]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true  // 不阻挡鼠标事件
        
        // 设置窗口大小和位置
        let hudWidth: CGFloat = 160
        let hudHeight: CGFloat = 44
        window.setContentSize(NSSize(width: hudWidth, height: hudHeight))
        
        // 居中放置在屏幕底部 Dock 上方
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - hudWidth / 2
            let y = screenFrame.minY + 80  // Dock 上方 80px
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.hudWindow = window
        print("[EtherType] 🟢 HUD 窗口已初始化")
    }
    
    /// 监听 HUD 状态变化
    private func observeHUDState() {
        // 使用 Timer 轮询状态，在 MainActor 上执行
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                // 仅在状态变化时执行显隐操作
                let currentState = self.appState.showHUD
                if currentState != self.lastHUDState {
                    self.lastHUDState = currentState
                    if currentState {
                        self.showHUD()
                    } else {
                        self.hideHUD()
                    }
                }
            }
        }
    }
    
    /// 显示 HUD
    private func showHUD() {
        guard let window = hudWindow, !window.isVisible else { return }
        
        // 重新计算位置（屏幕可能切换）
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - window.frame.width / 2
            let y = screenFrame.minY + 80
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // 淡入动画
        window.alphaValue = 0
        window.orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1
        }
        
        print("[EtherType] 🟢 HUD 显示")
    }
    
    /// 隐藏 HUD
    private func hideHUD() {
        guard let window = hudWindow, window.isVisible else { return }
        
        // 淡出动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor in
                window.orderOut(nil)
            }
        })
        
        print("[EtherType] 🟡 HUD 隐藏")
    }
}
