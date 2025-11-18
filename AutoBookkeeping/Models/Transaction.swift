//
//  Transaction.swift
//  AutoBookkeeping
//
//  交易记录数据模型
//

import Foundation
import SwiftData

/// 交易记录模型
@Model
class Transaction {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 交易金额
    var amount: Double

    /// 商家名称
    var merchant: String

    /// 分类名称
    var categoryName: String

    /// 交易类型 (expense/income)
    var type: String

    /// 支付方式 (微信/支付宝等)
    var paymentMethod: String?

    /// OCR 识别的原始文本
    var rawText: String?

    /// 交易时间
    var timestamp: Date

    /// 备注
    var note: String?

    /// 是否已删除 (软删除)
    var isDeleted: Bool

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    // MARK: - Computed Properties

    /// 格式化金额字符串
    var formattedAmount: String {
        String(format: "¥%.2f", amount)
    }

    /// 格式化日期字符串
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: timestamp)
    }

    /// 简短日期（今天/昨天/具体日期）
    var shortDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(timestamp) {
            return "今天"
        } else if calendar.isDateInYesterday(timestamp) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日"
            return formatter.string(from: timestamp)
        }
    }

    /// 是否为支出
    var isExpense: Bool {
        type == "expense"
    }

    /// 是否为收入
    var isIncome: Bool {
        type == "income"
    }

    // MARK: - Initialization

    /// 初始化交易记录
    /// - Parameters:
    ///   - amount: 金额
    ///   - merchant: 商家名称
    ///   - categoryName: 分类名称
    ///   - type: 交易类型
    ///   - paymentMethod: 支付方式
    ///   - rawText: 原始文本
    ///   - timestamp: 交易时间（默认当前时间）
    ///   - note: 备注
    init(
        amount: Double,
        merchant: String,
        categoryName: String,
        type: String = "expense",
        paymentMethod: String? = nil,
        rawText: String? = nil,
        timestamp: Date = Date(),
        note: String? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.merchant = merchant
        self.categoryName = categoryName
        self.type = type
        self.paymentMethod = paymentMethod
        self.rawText = rawText
        self.timestamp = timestamp
        self.note = note
        self.isDeleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// 更新交易信息
    func update(
        amount: Double? = nil,
        merchant: String? = nil,
        categoryName: String? = nil,
        note: String? = nil
    ) {
        if let amount = amount {
            self.amount = amount
        }
        if let merchant = merchant {
            self.merchant = merchant
        }
        if let categoryName = categoryName {
            self.categoryName = categoryName
        }
        if let note = note {
            self.note = note
        }
        self.updatedAt = Date()
    }

    /// 软删除
    func softDelete() {
        self.isDeleted = true
        self.updatedAt = Date()
    }

    /// 恢复删除
    func restore() {
        self.isDeleted = false
        self.updatedAt = Date()
    }
}

// MARK: - Extensions

extension Transaction {
    /// 示例数据（用于预览和测试）
    static var preview: Transaction {
        Transaction(
            amount: 35.0,
            merchant: "星巴克",
            categoryName: "餐饮",
            type: "expense",
            paymentMethod: "微信支付",
            rawText: "微信支付 ¥35.00 星巴克",
            timestamp: Date()
        )
    }

    /// 多个示例数据
    static var previews: [Transaction] {
        [
            Transaction(
                amount: 35.0,
                merchant: "星巴克",
                categoryName: "餐饮",
                paymentMethod: "微信支付",
                timestamp: Date()
            ),
            Transaction(
                amount: 15.0,
                merchant: "地铁",
                categoryName: "交通",
                paymentMethod: "支付宝",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            Transaction(
                amount: 128.0,
                merchant: "淘宝",
                categoryName: "购物",
                paymentMethod: "支付宝",
                timestamp: Date().addingTimeInterval(-7200)
            ),
            Transaction(
                amount: 3000.0,
                merchant: "工资",
                categoryName: "收入",
                type: "income",
                timestamp: Date().addingTimeInterval(-86400)
            )
        ]
    }
}
