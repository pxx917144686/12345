import NetworkExtension
import os.log

// 简化的收据生成器
class ReceiptGeneratorHelper {
    static func response(for productID: String, bundleID: String? = nil) -> Data? {
        let now = Date()
        let expiration = Date(timeIntervalSince1970: 4092599349) // 2099年
        
        // 创建基础收据内容
        let receipt: [String: Any] = [
            "status": 0,
            "environment": "Production",
            "receipt": [
                "receipt_type": "Production",
                "bundle_id": bundleID ?? "com.example.app",
                "in_app": [[
                    "quantity": "1",
                    "product_id": productID,
                    "transaction_id": "\(Int64.random(in: 100000000000000...999999999999999))",
                    "purchase_date": formatDate(now),
                    "expires_date": formatDate(expiration),
                    "is_trial_period": "false"
                ]]
            ],
            "latest_receipt": "MIIUHAYJKoZIhvcNAQcCoIIUDTCCFA" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
        ]
        
        return try? JSONSerialization.data(withJSONObject: receipt, options: [])
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'Etc/GMT'"
        return formatter.string(from: date)
    }
}

class FilterDataProvider: NEFilterDataProvider {
    private let logger = Logger(subsystem: "com.filter.app", category: "FilterDataProvider")
    
    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        logger.log("网络过滤服务已启动")
        completionHandler(nil)
    }
    
    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.log("网络过滤服务已停止")
        completionHandler()
    }
    
    // 此方法决定是否需要处理流量
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        // 仅处理HTTP流量
        guard let httpFlow = flow as? NEFilterHTTPFlow,
              let url = httpFlow.request?.url,
              let host = url.host else {
            return .allow()
        }
        
        // 检查是否是Apple验证请求
        if host.contains("buy.itunes.apple.com") || host.contains("sandbox.itunes.apple.com") {
            logger.log("检测到Apple收据验证请求")
            // 最简单的方法：我们直接返回允许，不尝试修改响应
            // 如果确定iOS 15支持其他API，可以在这里修改
            return .allow()
        }
        
        return .allow()
    }
    
    // 不再实现复杂的数据处理方法，避免API兼容性问题
}