import NetworkExtension
import os.log

class NetworkExtensionManager {
    static let shared = NetworkExtensionManager()
    private let logger = Logger(subsystem: "com.pxx917144686.inappproxy", category: "NetworkExtension")
    
    // 启动网络扩展
    func startNetworkExtension(completion: @escaping (Bool, String) -> Void) {
        let filterManager = NEFilterManager.shared()
        
        filterManager.loadFromPreferences { [weak self] error in
            if let error = error {
                self?.logger.error("加载网络扩展配置失败: \(error.localizedDescription)")
                completion(false, "加载配置失败: \(error.localizedDescription)")
                return
            }
            
            // 创建过滤器配置
            let config = NEFilterProviderConfiguration()
            config.filterBrowsers = false
            config.filterSockets = true
            
            // 设置过滤提供者 - 改为使用Bundle标识符
            let bundleId = Bundle.main.bundleIdentifier!
            filterManager.providerConfiguration = config
            
            // 启用过滤器
            filterManager.isEnabled = true
            
            // 保存配置
            filterManager.saveToPreferences { error in
                if let error = error {
                    self?.logger.error("保存网络扩展配置失败: \(error.localizedDescription)")
                    completion(false, "保存配置失败: \(error.localizedDescription)")
                } else {
                    self?.logger.info("网络扩展启动成功")
                    completion(true, "网络扩展已启动")
                }
            }
        }
    }
    
    // 停止网络扩展
    func stopNetworkExtension(completion: @escaping (Bool, String) -> Void) {
        let filterManager = NEFilterManager.shared()
        
        filterManager.loadFromPreferences { [weak self] error in
            if let error = error {
                self?.logger.error("加载网络扩展配置失败: \(error.localizedDescription)")
                completion(false, "加载配置失败: \(error.localizedDescription)")
                return
            }
            
            // 禁用过滤器
            filterManager.isEnabled = false
            
            // 保存配置
            filterManager.saveToPreferences { error in
                if let error = error {
                    self?.logger.error("停止网络扩展失败: \(error.localizedDescription)")
                    completion(false, "停止失败: \(error.localizedDescription)")
                } else {
                    self?.logger.info("网络扩展已停止")
                    completion(true, "网络扩展已停止")
                }
            }
        }
    }
    
    // 获取当前状态
    func getStatus(completion: @escaping (Bool, String) -> Void) {
        NEFilterManager.shared().loadFromPreferences { [weak self] error in
            if let error = error {
                self?.logger.error("获取状态失败: \(error.localizedDescription)")
                completion(false, "无法获取状态: \(error.localizedDescription)")
            } else {
                let isEnabled = NEFilterManager.shared().isEnabled
                self?.logger.info("网络扩展状态: \(isEnabled ? "已启用" : "未启用")")
                completion(isEnabled, isEnabled ? "已启用" : "未启用")
            }
        }
    }
}