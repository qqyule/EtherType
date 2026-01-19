@preconcurrency import KeyboardShortcuts

/// 定义全局快捷键名称
/// 使用 KeyboardShortcuts 库管理用户可自定义的全局快捷键
extension KeyboardShortcuts.Name {
    /// 录音快捷键 - 按住开始录音，松开停止录音
    /// 默认值：Option + Space
    static let toggleRecording = Self("toggleRecording", default: .init(.space, modifiers: .option))
}
