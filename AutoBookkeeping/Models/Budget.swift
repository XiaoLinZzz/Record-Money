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

    // MARK: - Nested Types

    /// 预算周期枚举
    enum BudgetPeriod: String, Codable, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"

        var displayText: String {
            switch self {
            case .daily: return "每日"
            case .weekly: return "每周"
            case .monthly: return "每月"
            case .yearly: return "每年"
            }
        }
    }

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 分类名称（nil 表示总预算）
    var categoryName: String

    /// 预算金额
    var amount: Double

    /// 预算周期类型 (daily/weekly/monthly/yearly)
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

    /// 是否为总预算（兼容性属性）
    var isTotalBudget: Bool {
        categoryName.isEmpty || categoryName == "总预算"
    }

    /// 是否激活（isEnabled 的别名，用于兼容性）
    var isActive: Bool {
        get { isEnabled }
        set { isEnabled = newValue }
    }

    /// 预算周期枚举
    var periodEnum: BudgetPeriod {
        BudgetPeriod(rawValue: period) ?? .monthly
    }

    /// 显示名称
    var displayName: String {
        isTotalBudget ? "总预算" : categoryName
    }

    /// 预算周期显示文本
    var periodDisplayText: String {
        periodEnum.displayText
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
