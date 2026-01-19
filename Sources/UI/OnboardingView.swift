import SwiftUI

/// 应用欢迎及模型加载引导页面
struct OnboardingView: View {
    @Bindable var appState: AppState
    @State private var showProgress = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            // 顶部图标与标题
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                    
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text("欢迎使用 EtherType")
                    .font(.system(size: 28, weight: .heavy))
                
                Text("EtherType 是一款运行在菜单栏的 AI 语音输入助手。\n它完全运行在本地，保护您的隐私。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 40)
            
            // 功能特点
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "bolt.fill", color: .yellow, title: "极速识别", subtitle: "使用毫秒级的 base 模型")
                FeatureRow(icon: "keyboard.fill", color: .blue, title: "原生体验", subtitle: "一键录音，自动将结果填入当前输入框")
                FeatureRow(icon: "lock.shield.fill", color: .green, title: "隐私安全", subtitle: "所有数据均在本地处理，无需上传云端")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 底部操作区
            VStack(spacing: 16) {
                if !showProgress {
                    Button(action: {
                        withAnimation {
                            showProgress = true
                            appState.startLoadingModel()
                        }
                    }) {
                        Text("开始使用")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 40)
                } else {
                    // 进度展示
                    loadingSection
                }
                
                Text(showProgress ? "正在加载语音模型 (约 150MB)，请保持网络连接" : "点击按钮后台将下载约 150MB 的基础模型")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 40)
        }
        .frame(width: 400, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    /// 加载进度区域
    private var loadingSection: some View {
        VStack(spacing: 8) {
            ProgressView(value: appState.modelLoadProgress)
                .progressViewStyle(.linear)
                .tint(.blue)
                .frame(width: 300)
            
            HStack {
                Text(appState.isModelLoaded ? "加载完成！" : "模型加载进度...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(appState.modelLoadProgress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 300)
            
            if appState.isModelLoaded {
                Button("完成引导") {
                    withAnimation {
                        appState.onboardingCompleted = true
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

/// 功能行组件
private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
