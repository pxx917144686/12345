import NetworkExtension
import os.log
@_exported import NetworkExtension

class FilterDataProvider: NEFilterDataProvider {
    private let logger = Logger(subsystem: "com.pxx917144686.inappproxy", category: "FilterDataProvider")
    
    // 从SatellaJailed的URLHook移植的逻辑
    
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
        
        // 检查是否是验证收据的请求 (从SatellaJailed的URLHook移植)
        if remoteEndpoint.hostname.contains("buy.itunes.apple.com") {
            logger.log("检测到潜在的App Store验证请求")
            return .needMoreData()
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
                
                // 生成虚假收据 (从SatellaJailed的ReceiptGenerator移植)
                if let jsonData = ReceiptGenerator.response(for: productID, bundleID: bundleID) {
                    
                    // 构造HTTP响应
                    let httpResponse = """
                    HTTP/1.1 200 OK
                    Content-Type: application/json
                    Content-Length: \(jsonData.count)
                    Connection: close
                    
                    """
                    
                    guard let headerData = httpResponse.data(using: .utf8) else {
                        return .allow()
                    }
                    
                    var fullResponse = headerData
                    fullResponse.append(jsonData)
                    
                    logger.log("成功生成伪造收据: \(bundleID) / \(productID)")
                    return .reply(fullResponse)
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