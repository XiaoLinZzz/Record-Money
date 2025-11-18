//
//  DataManager.swift
//  AutoBookkeeping
//
//  数据管理器 - 统一的数据访问接口
//  负责所有 SwiftData 数据的 CRUD 操作
//

import Foundation
import SwiftData

/// 数据管理器
/// 单例模式，提供统一的数据访问接口
@MainActor
class DataManager: ObservableObject {

    // MARK: - Singleton

    static let shared = DataManager()

    // MARK: - Properties

    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!

    /// App Group 共享容器（用于 Intent 访问）
    private let appGroupIdentifier = "group.com.autobookkeeping.shared"

    private lazy var sharedContainer: URL = {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            fatalError("无法获取 App Group 容器")
        }
        return url
    }()

    // MARK: - Initialization

    private init() {
        setupModelContainer()
    }

    /// 设置 Model Container
    private func setupModelContainer() {
        do {
            // 定义数据模型 Schema
            let schema = Schema([
                Transaction.self,
                Category.self,
                Budget.self
            ])

            // 配置数据库路径（使用 App Group 共享）
            let configuration = ModelConfiguration(
                schema: schema,
                url: sharedContainer.appendingPathComponent("AutoBookkeeping.sqlite"),
                cloudKitDatabase: .none // 暂不启用 iCloud 同步
            )

            // 创建 Model Container
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // 获取主上下文
            self.modelContext = modelContainer.mainContext

            // 初始化默认数据
            initializeDefaultData()

        } catch {
            fatalError("无法初始化数据库: \(error.localizedDescription)")
        }
    }

    /// 获取 Model Container（用于 SwiftUI 环境）
    func getModelContainer() -> ModelContainer {
        return modelContainer
    }

    // MARK: - Transaction Operations

    /// 保存交易记录
    /// - Parameter transaction: 交易对象
    func saveTransaction(_ transaction: Transaction) async throws {
        modelContext.insert(transaction)
        try modelContext.save()

        // 发送数据变更通知
        NotificationCenter.default.post(
            name: .transactionDidChange,
            object: nil
        )
    }

    /// 获取所有交易记录
    /// - Parameters:
    ///   - startDate: 开始日期（可选）
    ///   - endDate: 结束日期（可选）
    ///   - category: 分类筛选（可选）
    ///   - type: 类型筛选（可选）
    /// - Returns: 交易记录数组
    func fetchTransactions(
        startDate: Date? = nil,
        endDate: Date? = nil,
        category: String? = nil,
        type: String? = nil
    ) async throws -> [Transaction] {
        var descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        // 构建谓词
        var predicates: [Predicate<Transaction>] = [
            #Predicate { !$0.isDeleted }
        ]

        if let start = startDate, let end = endDate {
            predicates.append(#Predicate { transaction in
                transaction.timestamp >= start && transaction.timestamp <= end
            })
        }

        if let category = category {
            predicates.append(#Predicate { transaction in
                transaction.categoryName == category
            })
        }

        if let type = type {
            predicates.append(#Predicate { transaction in
                transaction.type == type
            })
        }

        // 组合所有谓词
        descriptor.predicate = #Predicate { transaction in
            predicates.allSatisfy { $0.evaluate(transaction) }
        }

        return try modelContext.fetch(descriptor)
    }

    /// 更新交易记录
    /// - Parameter transaction: 交易对象
    func updateTransaction(_ transaction: Transaction) async throws {
        transaction.updatedAt = Date()
        try modelContext.save()

        NotificationCenter.default.post(
            name: .transactionDidChange,
            object: nil
        )
    }

    /// 删除交易记录（软删除）
    /// - Parameter transaction: 交易对象
    func deleteTransaction(_ transaction: Transaction) async throws {
        transaction.softDelete()
        try modelContext.save()

        NotificationCenter.default.post(
            name: .transactionDidChange,
            object: nil
        )
    }

    /// 永久删除交易记录
    /// - Parameter transaction: 交易对象
    func permanentlyDeleteTransaction(_ transaction: Transaction) async throws {
        modelContext.delete(transaction)
        try modelContext.save()

        NotificationCenter.default.post(
            name: .transactionDidChange,
            object: nil
        )
    }

    // MARK: - Category Operations

    /// 获取所有分类
    /// - Returns: 分类数组
    func fetchCategories() async throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.order)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 保存分类
    /// - Parameter category: 分类对象
    func saveCategory(_ category: Category) async throws {
        modelContext.insert(category)
        try modelContext.save()
    }

    /// 删除分类
    /// - Parameter category: 分类对象
    func deleteCategory(_ category: Category) async throws {
        guard !category.isSystem else {
            throw DataError.cannotDeleteSystemCategory
        }
        modelContext.delete(category)
        try modelContext.save()
    }

    // MARK: - Budget Operations

    /// 获取预算
    /// - Parameter categoryName: 分类名称
    /// - Returns: 预算对象（如果存在）
    func getBudget(for categoryName: String) async -> Budget? {
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { budget in
                budget.categoryName == categoryName && budget.isEnabled
            }
        )

        return try? modelContext.fetch(descriptor).first
    }

    /// 获取所有预算
    /// - Returns: 预算数组
    func fetchBudgets() async throws -> [Budget] {
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { $0.isEnabled }
        )
        return try modelContext.fetch(descriptor)
    }

    /// 保存预算
    /// - Parameter budget: 预算对象
    func saveBudget(_ budget: Budget) async throws {
        modelContext.insert(budget)
        try modelContext.save()
    }

    /// 更新预算
    /// - Parameter budget: 预算对象
    func updateBudget(_ budget: Budget) async throws {
        budget.updatedAt = Date()
        try modelContext.save()
    }

    /// 删除预算
    /// - Parameter budget: 预算对象
    func deleteBudget(_ budget: Budget) async throws {
        modelContext.delete(budget)
        try modelContext.save()
    }

    // MARK: - Statistics

    /// 获取月度支出总额
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    /// - Returns: 支出总额
    func getMonthlyExpense(year: Int, month: Int) async throws -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!

        let transactions = try await fetchTransactions(
            startDate: startDate,
            endDate: endDate,
            type: "expense"
        )

        return transactions.reduce(0) { $0 + $1.amount }
    }

    /// 获取月度收入总额
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    /// - Returns: 收入总额
    func getMonthlyIncome(year: Int, month: Int) async throws -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!

        let transactions = try await fetchTransactions(
            startDate: startDate,
            endDate: endDate,
            type: "income"
        )

        return transactions.reduce(0) { $0 + $1.amount }
    }

    /// 获取指定分类的月度支出
    /// - Parameter categoryName: 分类名称
    /// - Returns: 支出总额
    func getMonthlySpent(for categoryName: String) async -> Double {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)

        guard let startDate = calendar.date(from: components),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return 0
        }

        let transactions = (try? await fetchTransactions(
            startDate: startDate,
            endDate: endDate,
            category: categoryName,
            type: "expense"
        )) ?? []

        return transactions.reduce(0) { $0 + $1.amount }
    }

    /// 按分类统计支出
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: [分类名: 金额]
    func getCategoryStats(startDate: Date, endDate: Date) async throws -> [String: Double] {
        let transactions = try await fetchTransactions(
            startDate: startDate,
            endDate: endDate,
            type: "expense"
        )

        var stats: [String: Double] = [:]
        for transaction in transactions {
            stats[transaction.categoryName, default: 0] += transaction.amount
        }

        return stats
    }

    /// 获取统计摘要
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 统计摘要
    func getStatisticsSummary(
        startDate: Date,
        endDate: Date
    ) async throws -> StatisticsSummary {
        let allTransactions = try await fetchTransactions(
            startDate: startDate,
            endDate: endDate
        )

        let expenses = allTransactions.filter { $0.type == "expense" }
        let incomes = allTransactions.filter { $0.type == "income" }

        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        let totalIncome = incomes.reduce(0) { $0 + $1.amount }

        var categoryBreakdown: [String: Double] = [:]
        for transaction in expenses {
            categoryBreakdown[transaction.categoryName, default: 0] += transaction.amount
        }

        return StatisticsSummary(
            totalExpense: totalExpense,
            totalIncome: totalIncome,
            balance: totalIncome - totalExpense,
            transactionCount: allTransactions.count,
            categoryBreakdown: categoryBreakdown
        )
    }

    // MARK: - Initialization

    /// 初始化默认数据
    private func initializeDefaultData() {
        Task {
            do {
                // 检查是否已初始化
                let categories = try await fetchCategories()
                if !categories.isEmpty {
                    return
                }

                // 插入默认分类
                for category in Category.defaultCategories {
                    modelContext.insert(category)
                }

                try modelContext.save()
                print("[DataManager] 默认数据初始化完成")

            } catch {
                print("[DataManager] 初始化默认数据失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Data Management

    /// 清除所有数据
    func clearAllData() async throws {
        // 删除所有交易
        let transactions = try await fetchTransactions()
        for transaction in transactions {
            try await permanentlyDeleteTransaction(transaction)
        }

        // 删除所有自定义分类
        let categories = try await fetchCategories()
        for category in categories where !category.isSystem {
            try await deleteCategory(category)
        }

        // 删除所有预算
        let budgets = try await fetchBudgets()
        for budget in budgets {
            try await deleteBudget(budget)
        }
    }
}

// MARK: - Data Models

/// 统计摘要
struct StatisticsSummary {
    let totalExpense: Double
    let totalIncome: Double
    let balance: Double
    let transactionCount: Int
    let categoryBreakdown: [String: Double]
}

// MARK: - Errors

enum DataError: Error, LocalizedError {
    case cannotDeleteSystemCategory

    var errorDescription: String? {
        switch self {
        case .cannotDeleteSystemCategory:
            return "无法删除系统预设分类"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let transactionDidChange = Notification.Name("transactionDidChange")
}
