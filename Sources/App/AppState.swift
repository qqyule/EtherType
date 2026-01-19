import Foundation
import KeyboardShortcuts

/// 应用全局状态管理
/// 使用 Swift 5.9+ 的 @Observable 宏实现响应式状态
@MainActor
@Observable
final class AppState {
    /// 当前是否正在录音
    var isRecording: Bool = false
    
    /// 初始化并注册快捷键监听
    init() {
        setupKeyboardShortcuts()
    }
    
    /// 配置全局快捷键监听
    /// 实现 "Walkie-Talkie" 模式：按住录音，松开停止
    private func setupKeyboardShortcuts() {
        // 按下快捷键 → 开始录音
        KeyboardShortcuts.onKeyDown(for: .toggleRecording) { [weak self] in
            self?.startRecording()
        }
        
        // 松开快捷键 → 停止录音
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            self?.stopRecording()
        }
    }
    
    /// 开始录音
    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        print("[EtherType] 🎙️ Start Recording")
    }
    
    /// 停止录音
    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        print("[EtherType] 🛑 Stop Recording")
    }
}
