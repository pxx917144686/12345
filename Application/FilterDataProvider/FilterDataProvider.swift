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
    
    // 处理新的网络流
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        // 检查是否是iTunes验证请求 - 不使用HTTPFlow类型，直接从通用Flow中获取信息
        if let remoteEndpoint = flow.remoteEndpoint as? NWHostEndpoint,
           let host = remoteEndpoint.hostname,
           (host.contains("buy.itunes.apple.com") || 
            host.contains("sandbox.itunes.apple.com")) {
            
            logger.log("检测到Apple收据验证请求: \(host)")
        }
        
        // 简化处理：仅允许所有流量通过
        // 在iOS 15上不尝试修改响应数据
        return .allow()
    }
}