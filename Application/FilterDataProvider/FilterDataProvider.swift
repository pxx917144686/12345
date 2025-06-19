import NetworkExtension
import os.log

// 添加简化版的ReceiptGenerator到扩展中，避免跨模块引用问题
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
    private let logger = Logger(subsystem: "com.pxx917144686.inappproxy", category: "FilterDataProvider")
    
    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        logger.log("网络过滤服务已启动")
        completionHandler(nil)
    }
    
    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.log("网络过滤服务已停止，原因: \(reason.rawValue)")
        completionHandler()
    }
    
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        guard let httpFlow = flow as? NEFilterSocketFlow else {
            return .allow()
        }
        
        // 获取远程端点信息
        guard let remoteEndpoint = httpFlow.remoteEndpoint as? NWHostEndpoint else {
            return .allow()
        }
        
        // 检查是否是验证收据的请求
        if remoteEndpoint.hostname.contains("buy.itunes.apple.com") {
            logger.log("检测到潜在的App Store验证请求")
            // 修正: 使用正确的API
            return .needRules()
        }
        
        return .allow()
    }
    
    override func handleInboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        // 处理入站数据
        return .allow()
    }
    
    override func handleOutboundData(from flow: NEFilterFlow, readBytesStartOffset offset: Int, readBytes: Data) -> NEFilterDataVerdict {
        guard let httpFlow = flow as? NEFilterSocketFlow,
              let remoteEndpoint = httpFlow.remoteEndpoint as? NWHostEndpoint else {
            return .allow()
        }
        
        // 检测App Store验证请求
        if remoteEndpoint.hostname.contains("buy.itunes.apple.com") {
            if let requestStr = String(data: readBytes, encoding: .utf8),
               requestStr.contains("verifyReceipt") {
                
                logger.log("检测到验证收据请求")
                
                // 尝试解析请求，查找bundle_id和product_id
                let bundleID = extractBundleID(from: readBytes) ?? "unknown.bundle"
                let productID = extractProductID(from: readBytes) ?? "\(bundleID).yearly"
                
                logger.log("提取的信息 - bundleID: \(bundleID), productID: \(productID)")
                
                // 使用内联版本的ReceiptGenerator
                if let jsonData = ReceiptGeneratorHelper.response(for: productID, bundleID: bundleID) {
                    
                    // 构造HTTP响应
                    let httpResponse = """
                    HTTP/1.1 200 OK
                    Content-Type: application/json
                    Content-Length: \(jsonData.count)
                    Connection: close
                    
                    """
                    
                    guard let headerData = httpResponse.data(using: String.Encoding.utf8) else {
                        return .allow()
                    }
                    
                    var fullResponse = headerData
                    fullResponse.append(jsonData)
                    
                    logger.log("成功生成伪造收据: \(bundleID) / \(productID)")
                    return NEFilterDataVerdict.responseData(fullResponse)
                }
            }
        }
        
        return .allow()
    }
    
    // 辅助方法：从请求中提取bundle_id
    private func extractBundleID(from data: Data) -> String? {
        guard let jsonString = String(data: data, encoding: .utf8) else { return nil }
        
        // 尝试找出bundle_id
        let patterns = ["\"bundle_id\"\\s*:\\s*\"([^\"]+)\"", "\"Bundle_Id\"\\s*:\\s*\"([^\"]+)\""]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: jsonString, options: [], range: NSRange(location: 0, length: jsonString.utf16.count)) {
                
                if let range = Range(match.range(at: 1), in: jsonString) {
                    return String(jsonString[range])
                }
            }
        }
        
        return nil
    }
    
    // 辅助方法：从请求中提取product_id
    private func extractProductID(from data: Data) -> String? {
        guard let jsonString = String(data: data, encoding: .utf8) else { return nil }
        
        // 尝试找出product_id
        let pattern = "\"product_id\"\\s*:\\s*\"([^\"]+)\""
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: jsonString, options: [], range: NSRange(location: 0, length: jsonString.utf16.count)) {
            
            if let range = Range(match.range(at: 1), in: jsonString) {
                return String(jsonString[range])
            }
        }
        
        return nil
    }
}