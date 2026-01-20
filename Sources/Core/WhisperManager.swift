import Combine
import Defaults
import OSLog
import WhisperKit

// MARK: - 模型加载错误类型

/// 模型加载过程中可能发生的错误
enum ModelError: Error, LocalizedError {
    /// 网络不可用
    case networkUnavailable
    /// 模型下载失败
    case downloadFailed(underlying: Error)
    /// 模型加载失败
    case loadFailed(underlying: Error)
    /// 重试次数耗尽
    case maxRetriesExceeded(lastError: Error)
    
    /// 用户友好的错误描述
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "网络连接不可用，请检查网络设置"
        case .downloadFailed:
            return "模型下载失败，请检查网络连接后重试"
        case .loadFailed:
            return "模型加载失败，请尝试重新启动应用或重新选择模型"
        case .maxRetriesExceeded:
            return "已尝试多次，仍无法完成下载，请检查网络并稍后重试"
        }
    }
}

// MARK: - WhisperManager

/// WhisperKit 语音识别管理器
/// 使用类 + Sendable 封装
final class WhisperManager: @unchecked Sendable {
    /// 日志记录器
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.ethertype.app", category: "WhisperManager")
    
    /// 最大重试次数
    private let maxRetryCount = 3
    
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
    
    /// 最近一次错误
    private(set) var lastError: ModelError?
    
    /// 进度回调
    var onProgressUpdate: ((Double) -> Void)?
    
    /// 错误回调
    var onError: ((ModelError) -> Void)?
    
    /// 初始化
    init() {}
    
    /// 下载并加载 Whisper 模型（带重试机制）
    /// - Parameter model: 要加载的模型，默认使用用户设置中的模型
    func loadModel(_ model: WhisperModel? = nil) async {
        guard !isLoading else {
            logger.info("⏭️ 跳过加载：正在加载中")
            return
        }
        
        let targetModel = model ?? Defaults[.selectedWhisperModel]
        
        // 如果模型已加载且相同，直接返回
        if isModelLoaded && currentModel == targetModel {
            logger.info("⏭️ 跳过加载：模型已加载 \(targetModel.displayName)")
            return
        }
        
        // 检查网络状态
        if !NetworkMonitor.shared.isConnected {
            let error = ModelError.networkUnavailable
            handleError(error)
            return
        }
        
        isLoading = true
        loadProgress = 0.0
        lastError = nil
        
        var lastDownloadError: Error?
        
        // 重试逻辑
        for attempt in 1...maxRetryCount {
            do {
                try await loadModelInternal(targetModel)
                // 成功，清除错误状态并退出
                lastError = nil
                return
            } catch let error as ModelError {
                // 只对下载失败进行重试
                guard case .downloadFailed(let underlyingError) = error else {
                    // 对于其他 ModelError（如 loadFailed），直接失败
                    handleError(error)
                    isLoading = false
                    return
                }
            
                lastDownloadError = underlyingError
            
                if attempt < maxRetryCount {
                    // 计算指数退避延迟
                    let delaySeconds = pow(2.0, Double(attempt)) // 2s, 4s
                    logger.warning("⚠️ 下载失败（第 \(attempt) 次），\(Int(delaySeconds)) 秒后重试...")
                
                    // 重新检查网络状态
                    if !NetworkMonitor.shared.isConnected {
                        let networkError = ModelError.networkUnavailable
                        handleError(networkError)
                        isLoading = false
                        return
                    }
                
                    try? await Task.sleep(for: .seconds(delaySeconds))
                }
            } catch {
                // 捕获 loadModelInternal 中未预期的其他错误
                lastDownloadError = error
                if attempt < maxRetryCount {
                    let delaySeconds = pow(2.0, Double(attempt))
                    logger.warning("⚠️ 发生未知错误（第 \(attempt) 次），\(Int(delaySeconds)) 秒后重试...")
                    try? await Task.sleep(for: .seconds(delaySeconds))
                }
            }
        }
        
        // 所有重试都失败
        isLoading = false
        if let underlyingError = lastDownloadError {
            let error = ModelError.maxRetriesExceeded(lastError: underlyingError)
            handleError(error)
        }
    }
    
    /// 内部加载模型逻辑（无重试）
    private func loadModelInternal(_ targetModel: WhisperModel) async throws {
        let modelVariant = targetModel.rawValue
        logger.info("📦 开始加载模型: \(targetModel.displayName) (\(modelVariant))")
        logger.info("📥 开始下载模型...")
        
        // 步骤 1: 下载模型
        let modelFolder: URL
        do {
            modelFolder = try await WhisperKit.download(variant: modelVariant) { [weak self] progress in
                guard let self = self else { return }
                let percent = Int(progress.fractionCompleted * 100)
                
                // 减少日志输出频率
                if percent % 5 == 0 && self.loadProgress != progress.fractionCompleted {
                    self.loadProgress = progress.fractionCompleted
                    self.onProgressUpdate?(self.loadProgress)
                    self.logger.info("📥 下载进度: \(percent)%")
                }
            }
        } catch {
            throw ModelError.downloadFailed(underlying: error)
        }
        
        logger.info("✅ 下载完成")
        logger.info("🔧 正在加载模型到内存...")
        
        // 步骤 2: 加载模型
        let config = WhisperKitConfig(
            model: modelVariant,
            modelFolder: modelFolder.path,
            verbose: true,
            logLevel: .info,
            prewarm: true,
            load: true
        )
        
        let kit: WhisperKit
        do {
            kit = try await WhisperKit(config)
        } catch {
            throw ModelError.loadFailed(underlying: error)
        }
        
        whisperKit = kit
        currentModel = targetModel
        
        isModelLoaded = true
        loadProgress = 1.0
        onProgressUpdate?(1.0)
        isLoading = false
        
        logger.info("✅ 模型 \(targetModel.displayName) 加载完成，准备就绪！")
    }
    
    /// 处理错误
    private func handleError(_ error: ModelError) {
        lastError = error
        logger.error("❌ 模型操作失败: \(error.errorDescription ?? "未知错误")")
        onProgressUpdate?(0.0)
        onError?(error)
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
            logger.info("🗑️ 已卸载旧模型")
        }
        
        // 保存选择
        Defaults[.selectedWhisperModel] = model
        
        // 加载新模型
        await loadModel(model)
    }
    
    /// 转录音频样本
    func transcribe(audioSamples: [Float]) async -> String {
        guard isModelLoaded, let kit = whisperKit else {
            logger.warning("⚠️ 无法转录：模型未加载")
            return ""
        }
        
        logger.info("🎤 开始转录音频数据")
        
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
            
            logger.info("✅ 转录完成")
            return transcribedText
        } catch {
            logger.error("❌ 转录失败")
            return ""
        }
    }
}
