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
    
    /// 模型加载进度 (0.0 - 1.0)
    var modelLoadProgress: Double = 0.0
    
    /// 是否正在加载模型
    var isModelLoading: Bool = false
    
    /// 模型是否加载完成
    var isModelLoaded: Bool = false
    
    /// 最近的转录结果
    var lastTranscription: String = ""
    
    /// 音频录制器
    private let audioRecorder = AudioRecorder()
    
    /// WhisperKit 管理器
    private let whisperManager = WhisperManager()
    
    /// 初始化
    init() {
        print("[AppState] 初始化中...")
        setupKeyboardShortcuts()
        
        // 设置进度回调
        whisperManager.onProgressUpdate = { [weak self] progress in
            Task { @MainActor in
                self?.modelLoadProgress = progress
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
        print("[AppState] 开始加载模型...")
        
        Task {
            await whisperManager.loadModel()
            isModelLoaded = whisperManager.isModelLoaded
            isModelLoading = false
            print("[AppState] 模型加载完成: \(isModelLoaded)")
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
        print("[AppState] 状态: isProcessing=\(isProcessing), isModelLoaded=\(isModelLoaded)")
        
        let alreadyRecording = await audioRecorder.isRecording
        
        if alreadyRecording {
            print("[AppState] ⚠️ 已在录音中")
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
        
        do {
            try await audioRecorder.startRecording()
            isRecording = true
            print("[AppState] 🎤 录音开始")
        } catch {
            print("[AppState] ❌ 录音开始失败: \(error)")
        }
    }
    
    private func stopRecordingAndTranscribe() async {
        let recordingStatus = await audioRecorder.isRecording
        guard recordingStatus else {
            print("[AppState] ⚠️ 未在录音中，跳过")
            return
        }
        
        print("[AppState] 🛑 停止录音...")
        let audioSamples = await audioRecorder.stopRecording()
        isRecording = false
        
        guard !audioSamples.isEmpty else {
            print("[AppState] ⚠️ 音频样本为空")
            return
        }
        
        print("[AppState] 🔄 开始转录...")
        isProcessing = true
        let transcription = await whisperManager.transcribe(audioSamples: audioSamples)
        isProcessing = false
        
        if !transcription.isEmpty {
            lastTranscription = transcription
            print("[AppState] ✅ 转录结果: \(transcription)")
            // TODO: 未来在这里执行文字注入
        }
    }
}
