import SwiftUI

/// 悬浮 HUD 视图
/// 类似"灵动岛"风格的录音状态指示器
struct HUDView: View {
    /// 应用状态
    @Bindable var appState: AppState
    
    /// HUD 宽度
    private let hudWidth: CGFloat = 160
    
    /// HUD 高度
    private let hudHeight: CGFloat = 44
    
    var body: some View {
        ZStack {
            // 玻璃材质背景
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            
            // 内容
            HStack(spacing: 12) {
                if appState.isRecording {
                    // 录音状态：显示声波动画
                    AudioWaveView(isAnimating: true)
                        .frame(width: 30, height: 24)
                    
                    Text("正在聆听...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    
                } else if appState.isProcessing {
                    // 处理状态：显示加载动画
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 24, height: 24)
                    
                    Text("思考中...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(width: hudWidth, height: hudHeight)
    }
}
