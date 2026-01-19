import Foundation
import WhisperKit
import Combine
import Defaults

/// WhisperKit 语音识别管理器
/// 使用类 + Sendable 封装
final class WhisperManager: @unchecked Sendable {
    /// WhisperKit 实例
    private var whisperKit: WhisperKit?
    
    /// 当前加载的模型
    private(set) var currentModel: WhisperModel?
    
    /// 模型加载状态
    private(set) var isModelLoaded: Bool = false
    
    /// 模型加载进度 (0.0 - 1.0)
    private(set) var loadProgress: Double = 0.0
    
    /// 是否正在加载模型
    private(set) var isLoading: Bool = false
    
    /// 进度回调
    var onProgressUpdate: ((Double) -> Void)?
    
    /// 初始化
    init() {}
    
    /// 下载并加载 Whisper 模型
    /// - Parameter model: 要加载的模型，默认使用用户设置中的模型
    func loadModel(_ model: WhisperModel? = nil) async {
        guard !isLoading else {
            print("[WhisperManager] ⏭️ 跳过加载：正在加载中")
            return
        }
        
        let targetModel = model ?? Defaults[.selectedWhisperModel]
        
        // 如果模型已加载且相同，直接返回
        if isModelLoaded && currentModel == targetModel {
            print("[WhisperManager] ⏭️ 跳过加载：模型已加载 \(targetModel.displayName)")
            return
        }
        
        isLoading = true
        loadProgress = 0.0
        
        let modelVariant = targetModel.rawValue
        print("[WhisperManager] 📦 开始加载模型: \(targetModel.displayName) (\(modelVariant))")
        
        do {
            print("[WhisperManager] 📥 开始下载模型...")
            
            // 步骤 1: 下载模型
            let modelFolder = try await WhisperKit.download(variant: modelVariant) { [weak self] progress in
                guard let self = self else { return }
                let percent = Int(progress.fractionCompleted * 100)
                
                // 减少日志输出频率
                if percent % 5 == 0 && self.loadProgress != progress.fractionCompleted {
                    self.loadProgress = progress.fractionCompleted
                    self.onProgressUpdate?(self.loadProgress)
                    print("[WhisperManager] 📥 下载进度: \(percent)%")
                }
            }
            
            print("[WhisperManager] ✅ 下载完成，模型路径: \(modelFolder.path)")
            print("[WhisperManager] 🔧 正在加载模型到内存...")
            
            // 步骤 2: 加载模型
            let config = WhisperKitConfig(
                model: modelVariant,
                modelFolder: modelFolder.path,
                verbose: true,
                logLevel: .info,
                prewarm: true,
                load: true
            )
            
            let kit = try await WhisperKit(config)
            whisperKit = kit
            currentModel = targetModel
            
            isModelLoaded = true
            loadProgress = 1.0
            onProgressUpdate?(1.0)
            isLoading = false
            
            print("[WhisperManager] ✅ 模型 \(targetModel.displayName) 加载完成，准备就绪！")
            
        } catch {
            isLoading = false
            print("[WhisperManager] ❌ 模型加载失败: \(error)")
            print("[WhisperManager] ❌ 错误详情: \(error.localizedDescription)")
            onProgressUpdate?(0.0)
        }
    }
    
    /// 切换到指定模型
    /// - Parameter model: 目标模型
    func switchModel(to model: WhisperModel) async {
        print("[WhisperManager] 🔄 切换模型: \(currentModel?.displayName ?? "无") -> \(model.displayName)")
        
        // 卸载当前模型
        if isModelLoaded {
            whisperKit = nil
            isModelLoaded = false
            currentModel = nil
            print("[WhisperManager] 🗑️ 已卸载旧模型")
        }
        
        // 保存选择
        Defaults[.selectedWhisperModel] = model
        
        // 加载新模型
        await loadModel(model)
    }
    
    /// 转录音频样本
    func transcribe(audioSamples: [Float]) async -> String {
        guard isModelLoaded, let kit = whisperKit else {
            print("[WhisperManager] ⚠️ 无法转录：模型未加载")
            return ""
        }
        
        print("[WhisperManager] 🎤 开始转录 \(audioSamples.count) 个样本")
        
        do {
            var promptTokens: [Int]? = nil
            if let tokenizer = kit.tokenizer {
                promptTokens = tokenizer.encode(text: "以下是简体中文和英文。")
            }
            
            let results = try await kit.transcribe(
                audioArray: audioSamples,
                decodeOptions: DecodingOptions(
                    language: "zh",
                    temperature: 0.0,
                    usePrefillPrompt: true,
                    promptTokens: promptTokens
                )
            )
            
            let transcribedText = results
                .compactMap { $0.text }
                .joined(separator: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("[WhisperManager] ✅ 转录完成: \(transcribedText)")
            return transcribedText
        } catch {
            print("[WhisperManager] ❌ 转录失败: \(error.localizedDescription)")
            return ""
        }
    }
}
