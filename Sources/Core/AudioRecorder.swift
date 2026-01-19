@preconcurrency import AVFoundation
import Foundation

/// 音频录制器
/// 使用 actor 确保多线程环境下状态访问的安全性
actor AudioRecorder {
    /// 音频引擎
    private var audioEngine: AVAudioEngine?
    
    /// 录制的音频样本缓冲区
    private var audioSamples: [Float] = []
    
    /// WhisperKit 要求的采样率：16kHz
    private let targetSampleRate: Double = 16000
    
    /// 是否正在录音
    private(set) var isRecording: Bool = false
    
    init() {}
    
    /// 开始录音
    /// - Throws: 如果音频引擎启动失败
    func startRecording() async throws {
        if isRecording { return }
        
        audioSamples = []
        
        let engine = AVAudioEngine()
        audioEngine = engine
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioRecorderError.formatCreationFailed
        }
        
        // 创建局部转换器，它是线程安全的，因为它不被跨 actor 共享
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioRecorderError.converterCreationFailed
        }
        
        let targetSampleRate = self.targetSampleRate
        
        // 安装 Tap
        // 注意：Tap 闭包在音频后台线程执行
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // 在后台线程进行转换计算
            let ratio = targetSampleRate / inputFormat.sampleRate
            let frameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
            
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else { return }
            
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            
            if error == nil, let channelData = convertedBuffer.floatChannelData?[0] {
                let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(convertedBuffer.frameLength)))
                
                // 将数据同步回 actor
                Task {
                    await self.appendSamples(samples)
                }
            }
        }
        
        try engine.start()
        isRecording = true
        
        print("[AudioRecorder] 🎙️ 开始录音 (采样率: \(Int(targetSampleRate))Hz)")
    }
    
    /// 内部方法：将样本追加到缓冲区
    private func appendSamples(_ samples: [Float]) {
        self.audioSamples.append(contentsOf: samples)
    }
    
    /// 停止录音并返回音频样本
    /// - Returns: 录制的音频样本（16kHz, Float32）
    func stopRecording() async -> [Float] {
        guard isRecording else { return [] }
        
        isRecording = false
        
        // 停止并清理音频引擎
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        
        let samples = audioSamples
        let duration = Double(samples.count) / targetSampleRate
        print("[AudioRecorder] 🛑 停止录音 (时长: \(String(format: "%.2f", duration))s, 样本数: \(samples.count))")
        
        return samples
    }
}

/// 音频录制错误
enum AudioRecorderError: Error, LocalizedError {
    case formatCreationFailed
    case converterCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .formatCreationFailed:
            return "无法创建目标音频格式"
        case .converterCreationFailed:
            return "无法创建音频格式转换器"
        }
    }
}
