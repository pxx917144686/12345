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
        // 检查是否是HTTP流
        guard let httpFlow = flow as? NEFilterHTTPFlow else {
            return .allow()
        }
        
        // 获取URL
        guard let url = httpFlow.request?.url else {
            return .allow()
        }
        
        // 检查是否是Apple的验证服务器
        if isAppleReceiptValidationRequest(url) {
            // 这是一个重要变化：在iOS 15中，返回需要对流进行数据过滤的verdict
            logger.log("检测到Apple收据验证请求: \(url)")
            return .filterData()
        }
        
        // 允许其他所有流量
        return .allow()
    }
    
    // 处理传出数据 - 这个方法会在filterData verdict之后被调用
    override func handleInboundDataComplete(for flow: NEFilterFlow) -> NEFilterDataVerdict {
        // 检查是否是HTTP流
        guard let httpFlow = flow as? NEFilterHTTPFlow,
              let url = httpFlow.request?.url,
              isAppleReceiptValidationRequest(url) else {
            return .allow()
        }
        
        // 从URL中提取产品ID等信息
        guard let bundleID = extractBundleID(from: url),
              let productID = extractProductID(from: url) else {
            return .allow()
        }
        
        // 生成虚假收据响应
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
            
            // 在iOS 15中使用这个API
            return .pass(with: fullResponse)
        }
        
        return .allow()
    }
    
    // 辅助方法：检查URL是否是Apple的验证服务器
    private func isAppleReceiptValidationRequest(_ url: URL) -> Bool {
        let host = url.host ?? ""
        return host.contains("buy.itunes.apple.com") || 
               host.contains("sandbox.itunes.apple.com") ||
               host.contains("buy.itunes.apple.com") ||
               host.contains("buy.itunes")
    }
    
    // 辅助方法：从URL提取Bundle ID
    private func extractBundleID(from url: URL) -> String? {
        // 实现从URL中提取bundleID的逻辑
        return url.pathComponents.last
    }
    
    // 辅助方法：从URL提取Product ID
    private func extractProductID(from url: URL) -> String? {
        // 实现从URL或请求体中提取productID的逻辑
        // 可能需要检查查询参数或请求体
        return "com.example.product" // 默认产品ID，实际应该从请求中提取
    }
}