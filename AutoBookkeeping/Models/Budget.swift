//
//  Budget.swift
//  AutoBookkeeping
//
//  预算数据模型
//

import Foundation
import SwiftData

/// 预算模型
@Model
class Budget {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 分类名称
    var categoryName: String

    /// 预算金额
    var amount: Double

    /// 预算周期类型 (monthly/yearly)
    var period: String

    /// 开始日期
    var startDate: Date

    /// 是否启用
    var isEnabled: Bool

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    // MARK: - Computed Properties

    /// 预算周期显示文本
    var periodDisplayText: String {
        switch period {
        case "monthly":
            return "每月"
        case "yearly":
            return "每年"
        default:
            return "未知"
        }
    }

    /// 格式化预算金额
    var formattedAmount: String {
        String(format: "¥%.2f", amount)
    }

    // MARK: - Initialization

    /// 初始化预算
    /// - Parameters:
    ///   - categoryName: 分类名称
    ///   - amount: 预算金额
    ///   - period: 周期（monthly/yearly）
    ///   - startDate: 开始日期
    init(
        categoryName: String,
        amount: Double,
        period: String = "monthly",
        startDate: Date = Date()
    ) {
        self.id = UUID()
        self.categoryName = categoryName
        self.amount = amount
        self.period = period
        self.startDate = startDate
        self.isEnabled = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// 更新预算金额
    func updateAmount(_ newAmount: Double) {
        self.amount = newAmount
        self.updatedAt = Date()
    }

    /// 切换启用状态
    func toggleEnabled() {
        self.isEnabled.toggle()
        self.updatedAt = Date()
    }
}

// MARK: - Extensions

extension Budget {
    /// 预览数据
    static var preview: Budget {
        Budget(
            categoryName: "餐饮",
            amount: 2000.0,
            period: "monthly"
        )
    }

    /// 多个预览数据
    static var previews: [Budget] {
        [
            Budget(categoryName: "餐饮", amount: 2000.0),
            Budget(categoryName: "交通", amount: 500.0),
            Budget(categoryName: "购物", amount: 1000.0),
            Budget(categoryName: "娱乐", amount: 800.0)
        ]
    }
}
