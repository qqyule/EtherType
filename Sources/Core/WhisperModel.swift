import Foundation
import Defaults

/// Whisper 模型配置
/// 支持 small 和 large-v3 两种模型
enum WhisperModel: String, CaseIterable, Identifiable, Codable, Defaults.Serializable {
    /// small 模型 - 速度快，适合日常使用
    case small = "openai_whisper-small"
    
    /// large-v3 模型 - 精度高，适合专业场景
    case largeV3 = "openai_whisper-large-v3"
    
    /// 唯一标识符
    var id: String { rawValue }
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .small:
            return "Small"
        case .largeV3:
            return "Large V3"
        }
    }
    
    /// 模型描述
    var description: String {
        switch self {
        case .small:
            return "速度快，适合日常使用"
        case .largeV3:
            return "精度更高，适合专业场景"
        }
    }
    
    /// 模型大小描述
    var sizeDescription: String {
        switch self {
        case .small:
            return "~500MB"
        case .largeV3:
            return "~3GB"
        }
    }
    
    /// 推荐标识
    var isRecommended: Bool {
        self == .small
    }
}

// MARK: - UserDefaults 键

extension Defaults.Keys {
    /// 选中的 Whisper 模型
    static let selectedWhisperModel = Key<WhisperModel>("selectedWhisperModel", default: .small)
}
