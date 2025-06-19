import Foundation
import UIKit

struct ReceiptInfo: Codable {
    let quantity: String
    let productID: String
    let transactionID: String
    let originalTransactionID: String
    let purchaseDate: String
    let purchaseDateMs: String
    let purchaseDatePst: String
    let originalPurchaseDate: String
    let originalPurchaseDateMs: String
    let originalPurchaseDatePst: String
    let expiresDate: String
    let expiresDateMs: String
    let expiresDatePst: String
    let webOrderLineItemID: String
    let isTrialPeriod: String
    let isInIntroOfferPeriod: String
    
    enum CodingKeys: String, CodingKey {
        case quantity
        case productID = "product_id"
        case transactionID = "transaction_id"
        case originalTransactionID = "original_transaction_id"
        case purchaseDate = "purchase_date"
        case purchaseDateMs = "purchase_date_ms"
        case purchaseDatePst = "purchase_date_pst"
        case originalPurchaseDate = "original_purchase_date"
        case originalPurchaseDateMs = "original_purchase_date_ms"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case expiresDate = "expires_date"
        case expiresDateMs = "expires_date_ms"
        case expiresDatePst = "expires_date_pst"
        case webOrderLineItemID = "web_order_line_item_id"
        case isTrialPeriod = "is_trial_period"
        case isInIntroOfferPeriod = "is_in_intro_offer_period"
    }
}

class ReceiptGenerator {
    // 从SatellaJailed的ReceiptGenerator.swift移植

    static func generateUUID() -> String {
        return UUID().uuidString
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'Etc/GMT'"
        return formatter.string(from: date)
    }
    
    static func formatDatePST(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'America/Los_Angeles'"
        let pstDate = Date(timeIntervalSince1970: date.timeIntervalSince1970 - 7 * 3600)
        return formatter.string(from: pstDate)
    }
    
    static func response(for productID: String, bundleID: String? = nil) -> Data? {
        let now = Date()
        let expiration = Date(timeIntervalSince1970: 4092599349) // 2099年
        let actualBundleID = bundleID ?? "com.example.app"
        
        // 移植自SatellaJailed的收据结构
        let receipt: [String: Any] = [
            "receipt_type": "Production",
            "adam_id": Int64.random(in: 1000000000...9999999999),
            "app_item_id": Int64.random(in: 1000000000...9999999999),
            "bundle_id": actualBundleID,
            "application_version": "1.0",
            "download_id": Int64.random(in: 1000000000...9999999999),
            "version_external_identifier": Int(arc4random_uniform(10000)),
            "receipt_creation_date": formatDate(now),
            "receipt_creation_date_ms": "\(Int64(now.timeIntervalSince1970 * 1000))",
            "receipt_creation_date_pst": formatDatePST(now),
            "request_date": formatDate(now),
            "request_date_ms": "\(Int64(now.timeIntervalSince1970 * 1000))",
            "request_date_pst": formatDatePST(now),
            "original_purchase_date": formatDate(now),
            "original_purchase_date_ms": "\(Int64(now.timeIntervalSince1970 * 1000))",
            "original_purchase_date_pst": formatDatePST(now),
            "original_application_version": "1.0",
            "in_app": [createReceiptInfo(productID: productID, now: now, expiration: expiration)]
        ]
        
        // 创建完整响应
        let response: [String: Any] = [
            "status": 0,
            "environment": "Production",
            "receipt": receipt,
            "latest_receipt_info": [createReceiptInfo(productID: productID, now: now, expiration: expiration)],
            "pending_renewal_info": [
                [
                    "product_id": productID,
                    "original_transaction_id": generateTransactionId(),
                    "auto_renew_product_id": productID,
                    "auto_renew_status": "1"
                ]
            ],
            "latest_receipt": generateFakeReceipt()
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: [])
            return data
        } catch {
            print("生成收据JSON失败: \(error)")
            return nil
        }
    }
    
    // 创建单个收据信息
    private static func createReceiptInfo(productID: String, now: Date, expiration: Date) -> [String: Any] {
        let transactionId = generateTransactionId()
        
        return [
            "quantity": "1",
            "product_id": productID,
            "transaction_id": transactionId,
            "original_transaction_id": transactionId,
            "purchase_date": formatDate(now),
            "purchase_date_ms": "\(Int64(now.timeIntervalSince1970 * 1000))",
            "purchase_date_pst": formatDatePST(now),
            "original_purchase_date": formatDate(now),
            "original_purchase_date_ms": "\(Int64(now.timeIntervalSince1970 * 1000))",
            "original_purchase_date_pst": formatDatePST(now),
            "expires_date": formatDate(expiration),
            "expires_date_ms": "\(Int64(expiration.timeIntervalSince1970 * 1000))",
            "expires_date_pst": formatDatePST(expiration),
            "web_order_line_item_id": generateTransactionId(),
            "is_trial_period": "false",
            "is_in_intro_offer_period": "false",
            "in_app_ownership_type": "PURCHASED"
        ]
    }
    
    // 生成交易ID
    private static func generateTransactionId() -> String {
        return "\(Int64.random(in: 100000000000000...999999999999999))"
    }
    
    // 生成伪造收据
    private static func generateFakeReceipt() -> String {
        let prefix = "MIIUHAYJKoZIhvcNAQcCoIIUDTCCFAkCAQExCzAJBgUrDgMCGgUAMIIDvQYJKoZIhvcN"
        let random = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return prefix + random
    }
}