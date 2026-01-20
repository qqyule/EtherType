import Foundation
import Network

/// 网络状态监控器
/// 使用 Network 框架监测网络连接状态
final class NetworkMonitor: @unchecked Sendable {
    /// 全局单例
    static let shared = NetworkMonitor()
    
    /// 网络状态监控器
    private let monitor = NWPathMonitor()
    
    /// 调度队列
    private let queue = DispatchQueue(label: "com.ethertype.networkmonitor")
    
    /// 当前是否联网
    private(set) var isConnected: Bool = true
    
    /// 网络状态变化回调
    var onStatusChange: ((Bool) -> Void)?
    
    /// 私有初始化，确保单例
    private init() {}
    
    /// 启动网络监控
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            self?.isConnected = connected
            print("[NetworkMonitor] 网络状态: \(connected ? "已连接" : "已断开")")
            
            DispatchQueue.main.async {
                self?.onStatusChange?(connected)
            }
        }
        monitor.start(queue: queue)
        print("[NetworkMonitor] 网络监控已启动")
    }
    
    /// 停止网络监控
    func stop() {
        monitor.cancel()
        print("[NetworkMonitor] 网络监控已停止")
    }
}
