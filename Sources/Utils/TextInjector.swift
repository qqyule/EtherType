import AppKit
import Carbon

/// 文字注入器
/// 负责将转录结果注入到当前活跃窗口的光标位置
/// 使用剪贴板 + Cmd+V 模拟按键方案，兼容性最强
final class TextInjector {
    
    // MARK: - 权限检测
    
    /// 检查辅助功能权限
    /// - Returns: 是否已获得辅助功能权限
    static func checkAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        print("[TextInjector] 辅助功能权限状态: \(trusted)")
        return trusted
    }
    
    /// 请求辅助功能权限（打开系统偏好设置）
    static func requestAccessibilityPermission() {
        print("[TextInjector] 请求辅助功能权限...")
        
        // 使用字符串常量避免 Swift 6 并发安全问题
        let promptKey = "AXTrustedCheckOptionPrompt"
        let options = [promptKey: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: - 文字注入
    
    /// 注入文字到当前活跃窗口的光标位置
    /// - Parameter text: 要注入的文字
    /// - Returns: 是否注入成功
    static func inject(text: String) async -> Bool {
        print("[TextInjector] 准备注入文字: \(text)")
        
        // 检查权限
        guard checkAccessibilityPermission() else {
            print("[TextInjector] ❌ 无辅助功能权限，无法注入")
            requestAccessibilityPermission()
            return false
        }
        
        // 直接使用剪贴板 + Cmd+V 方案（兼容性最强）
        if injectViaPasteboard(text) {
            print("[TextInjector] ✅ 注入成功")
            return true
        }
        
        print("[TextInjector] ❌ 注入失败")
        return false
    }
    
    // MARK: - 剪贴板 + 模拟 Cmd+V
    
    /// 使用剪贴板和模拟按键注入文字
    /// - Parameter text: 要注入的文字
    /// - Returns: 是否成功
    private static func injectViaPasteboard(_ text: String) -> Bool {
        print("[TextInjector] 尝试方案 B: 剪贴板 + Cmd+V")
        
        // 保存当前剪贴板内容
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)
        
        // 写入新内容到剪贴板
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("[TextInjector] 已写入剪贴板")
        
        // 模拟 Cmd+V
        let success = simulateCmdV()
        
        // 延迟后恢复原始剪贴板内容
        if success, let previous = previousContents {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
                print("[TextInjector] 已恢复剪贴板内容")
            }
        }
        
        return success
    }
    
    /// 模拟 Cmd+V 按键
    /// - Returns: 是否成功
    private static func simulateCmdV() -> Bool {
        print("[TextInjector] 模拟 Cmd+V...")
        
        // 创建 V 键按下事件
        guard let keyDownEvent = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(kVK_ANSI_V),
            keyDown: true
        ) else {
            print("[TextInjector] 无法创建按下事件")
            return false
        }
        
        // 创建 V 键松开事件
        guard let keyUpEvent = CGEvent(
            keyboardEventSource: nil,
            virtualKey: CGKeyCode(kVK_ANSI_V),
            keyDown: false
        ) else {
            print("[TextInjector] 无法创建松开事件")
            return false
        }
        
        // 添加 Command 修饰键
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand
        
        // 发送事件
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
        
        print("[TextInjector] Cmd+V 已发送")
        return true
    }
}
