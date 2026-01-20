import Foundation
import KeyboardShortcuts
import SwiftUI
import Defaults

// 定义持久化键
extension Defaults.Keys {
    static let onboardingCompleted = Key<Bool>("onboardingCompleted", default: false)
}

/// 应用全局状态管理
@MainActor
@Observable
final class AppState {
    /// 引导是否完成
    var onboardingCompleted: Bool {
        get { Defaults[.onboardingCompleted] }
        set { Defaults[.onboardingCompleted] = newValue }
    }
    
    /// 当前是否正在录音
    var isRecording: Bool = false
    
    /// 是否正在处理（转录中）
    var isProcessing: Bool = false
    
    /// 是否显示 HUD
    var showHUD: Bool = false
    
    /// 模型加载进度 (0.0 - 1.0)
    var modelLoadProgress: Double = 0.0
    
    /// 是否正在加载模型
    var isModelLoading: Bool = false
    
    /// 模型是否加载完成
    var isModelLoaded: Bool = false
    
    /// 当前选中的模型
    var selectedModel: WhisperModel {
        get { Defaults[.selectedWhisperModel] }
        set { Defaults[.selectedWhisperModel] = newValue }
    }
    
    /// 当前已加载的模型名称
    var currentModelName: String {
        whisperManager.currentModel?.displayName ?? "未加载"
    }
    
    /// 最近的转录结果
    var lastTranscription: String = ""
    
    /// 模型加载错误信息（用于 UI 展示）
    var modelLoadError: String?
    
    /// 音频录制器
    private let audioRecorder = AudioRecorder()
    
    /// WhisperKit 管理器
    private let whisperManager = WhisperManager()
    
    /// 初始化
    init() {
        print("[AppState] 初始化中...")
        
        // 启动网络监控
        NetworkMonitor.shared.start()
        
        setupKeyboardShortcuts()
        
        // 设置进度回调
        whisperManager.onProgressUpdate = { [weak self] progress in
            Task { @MainActor in
                self?.modelLoadProgress = progress
            }
        }
        
        // 设置错误回调
        whisperManager.onError = { [weak self] error in
            Task { @MainActor in
                self?.modelLoadError = error.localizedDescription
                self?.isModelLoading = false
                print("[AppState] 模型错误: \(error.localizedDescription)")
            }
        }
        
        // 如果已经完成引导，自动加载模型
        if onboardingCompleted {
            print("[AppState] 引导已完成，开始加载模型")
            startLoadingModel()
        } else {
            print("[AppState] 等待引导完成")
        }
    }
    
    /// 开始加载模型 (由引导页触发)
    func startLoadingModel() {
        guard !isModelLoading && !isModelLoaded else {
            print("[AppState] 跳过模型加载：isModelLoading=\(isModelLoading), isModelLoaded=\(isModelLoaded)")
            return
        }
        isModelLoading = true
        modelLoadError = nil  // 清除之前的错误
        print("[AppState] 开始加载模型...")
        
        Task {
            await whisperManager.loadModel()
            isModelLoaded = whisperManager.isModelLoaded
            isModelLoading = false
            print("[AppState] 模型加载完成: \(isModelLoaded)")
        }
    }
    
    /// 切换到指定模型
    /// - Parameter model: 目标模型
    func switchModel(to model: WhisperModel) {
        guard !isModelLoading else {
            print("[AppState] 正在加载中，无法切换")
            return
        }
        
        isModelLoading = true
        isModelLoaded = false
        modelLoadProgress = 0.0
        modelLoadError = nil  // 清除之前的错误
        print("[AppState] 开始切换模型到: \(model.displayName)")
        
        Task {
            await whisperManager.switchModel(to: model)
            isModelLoaded = whisperManager.isModelLoaded
            isModelLoading = false
            print("[AppState] 模型切换完成: \(isModelLoaded)")
        }
    }
    
    private func setupKeyboardShortcuts() {
        print("[AppState] 设置快捷键监听...")
        
        KeyboardShortcuts.onKeyDown(for: .toggleRecording) { [weak self] in
            print("[AppState] ⌨️ 快捷键按下")
            Task { @MainActor in
                await self?.startRecording()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            print("[AppState] ⌨️ 快捷键松开")
            Task { @MainActor in
                await self?.stopRecordingAndTranscribe()
            }
        }
        
        print("[AppState] 快捷键监听已设置")
    }
    
    private func startRecording() async {
        print("[AppState] 尝试开始录音...")
        
        // 1. 优先检查本地状态 (MainActor 串行保护)
        if isRecording {
            print("[AppState] ⚠️ 已在录音中 (Local)，跳过")
            return
        }
        
        if isProcessing {
            print("[AppState] ⚠️ 正在处理中")
            return
        }
        if !isModelLoaded {
            print("[AppState] ⚠️ 模型未加载，无法录音")
            return
        }
        
        // 2. 立即设置状态以阻止后续调用
        isRecording = true
        showHUD = true
        
        do {
            // 3. 异步启动
            try await audioRecorder.startRecording()
            print("[AppState] 🎤 录音开始")
        } catch {
            print("[AppState] ❌ 录音开始失败: \(error)")
            // 回滚状态
            isRecording = false
            showHUD = false
        }
    }
    
    private func stopRecordingAndTranscribe() async {
        // 1. 优先检查本地状态
        guard isRecording else {
            print("[AppState] ⚠️ 未在录音中 (Local)，跳过")
            return
        }
        
        // 2. 立即更新状态，防止重入
        print("[AppState] 🛑 停止录音...")
        isRecording = false
        
        // 3. 获取音频 (即便此时 AudioRecorder 还没完全停下，我们也只取这一次)
        let audioSamples = await audioRecorder.stopRecording()
        
        guard !audioSamples.isEmpty else {
            print("[AppState] ⚠️ 音频样本为空")
            // 延迟隐藏 HUD
            try? await Task.sleep(for: .milliseconds(300))
            showHUD = false
            return
        }
        
        print("[AppState] 🔄 开始转录...")
        isProcessing = true
        let transcription = await whisperManager.transcribe(audioSamples: audioSamples)
        isProcessing = false
        
        if !transcription.isEmpty {
            lastTranscription = transcription
            print("[AppState] ✅ 转录结果: \(transcription)")
            
            // 执行文字注入
            let injected = await TextInjector.inject(text: transcription)
            if injected {
                print("[AppState] ✅ 文字注入成功")
            } else {
                print("[AppState] ⚠️ 文字注入失败")
            }
        }
        
        // 延迟隐藏 HUD
        try? await Task.sleep(for: .milliseconds(300))
        showHUD = false
    }
}
