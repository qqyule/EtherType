import SwiftUI

/// 动态声波动画视图
/// 使用 5 根随机跳动的声波条展示录音状态
struct AudioWaveView: View {
    /// 是否正在播放动画
    var isAnimating: Bool
    
    /// 声波条数量
    private let barCount = 5
    
    /// 声波条宽度
    private let barWidth: CGFloat = 3
    
    /// 声波条间距
    private let barSpacing: CGFloat = 2
    
    /// 最小高度比例
    private let minHeightRatio: CGFloat = 0.2
    
    /// 动画状态
    @State private var animationPhases: [Double] = Array(repeating: 0.5, count: 5)
    
    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: barWidth,
                        height: isAnimating ? animatedHeight(for: index) : minHeight
                    )
                    .animation(
                        isAnimating ? animation(for: index) : .easeOut(duration: 0.2),
                        value: animationPhases[index]
                    )
            }
        }
        .onAppear {
            if isAnimating {
                startAnimation()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    /// 计算最小高度
    private var minHeight: CGFloat {
        return 8 * minHeightRatio
    }
    
    /// 计算动画高度
    private func animatedHeight(for index: Int) -> CGFloat {
        let phase = animationPhases[index]
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 24
        return baseHeight + (maxHeight - baseHeight) * phase
    }
    
    /// 生成动画
    private func animation(for index: Int) -> Animation {
        let baseDuration = 0.3
        let randomOffset = Double.random(in: 0...0.2)
        return Animation
            .easeInOut(duration: baseDuration + randomOffset)
            .repeatForever(autoreverses: true)
            .delay(Double(index) * 0.1)
    }
    
    /// 开始动画
    private func startAnimation() {
        for index in 0..<barCount {
            withAnimation(animation(for: index)) {
                animationPhases[index] = Double.random(in: 0.3...1.0)
            }
        }
    }
    
    /// 停止动画
    private func stopAnimation() {
        for index in 0..<barCount {
            withAnimation(.easeOut(duration: 0.2)) {
                animationPhases[index] = minHeightRatio
            }
        }
    }
}
