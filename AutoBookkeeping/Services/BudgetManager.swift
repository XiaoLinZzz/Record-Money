//
//  BudgetManager.swift
//  AutoBookkeeping
//
//  预算管理服务
//

import Foundation
import SwiftData

@MainActor
class BudgetManager: ObservableObject {

    static let shared = BudgetManager()

    @Published var budgets: [Budget] = []
    @Published var totalBudget: Budget?

    private let modelContext: ModelContext

    private init() {
        self.modelContext = DataManager.shared.getModelContainer().mainContext
        Task {
            await loadBudgets()
        }
    }

    // MARK: - CRUD Operations

    func loadBudgets() async {
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            budgets = try modelContext.fetch(descriptor)
            totalBudget = budgets.first(where: { $0.isTotalBudget })
        } catch {
            print("❌ 加载预算失败: \(error)")
        }
    }

    func saveBudget(_ budget: Budget) async throws {
        modelContext.insert(budget)
        try modelContext.save()
        await loadBudgets()

        // 发送通知
        NotificationCenter.default.post(name: .budgetDidChange, object: nil)
    }

    func updateBudget(_ budget: Budget) async throws {
        budget.updatedAt = Date()
        try modelContext.save()
        await loadBudgets()

        NotificationCenter.default.post(name: .budgetDidChange, object: nil)
    }

    func deleteBudget(_ budget: Budget) async throws {
        modelContext.delete(budget)
        try modelContext.save()
        await loadBudgets()

        NotificationCenter.default.post(name: .budgetDidChange, object: nil)
    }

    // MARK: - Budget Calculations

    /// 获取当前周期的支出
    func getCurrentSpending(
        category: String? = nil,
        period: Budget.BudgetPeriod,
        startDate: Date
    ) async -> Double {
        let dateRange = getDateRange(for: period, startDate: startDate)

        let descriptor: FetchDescriptor<Transaction>
        if let category = category {
            descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate {
                    $0.type == "expense" &&
                    $0.categoryName == category &&
                    $0.timestamp >= dateRange.start &&
                    $0.timestamp < dateRange.end
                }
            )
        } else {
            descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate {
                    $0.type == "expense" &&
                    $0.timestamp >= dateRange.start &&
                    $0.timestamp < dateRange.end
                }
            )
        }

        do {
            let transactions = try modelContext.fetch(descriptor)
            return transactions.reduce(0) { $0 + $1.amount }
        } catch {
            print("❌ 获取支出失败: \(error)")
            return 0
        }
    }

    /// 计算预算使用百分比
    func getBudgetUsage(budget: Budget) async -> Double {
        let spending = await getCurrentSpending(
            category: budget.categoryName,
            period: budget.periodEnum,
            startDate: budget.startDate
        )
        return min(spending / budget.amount, 1.0)
    }

    /// 检查是否超支
    func isOverBudget(budget: Budget) async -> Bool {
        let spending = await getCurrentSpending(
            category: budget.categoryName,
            period: budget.periodEnum,
            startDate: budget.startDate
        )
        return spending > budget.amount
    }

    /// 获取超支金额
    func getOverage(budget: Budget) async -> Double {
        let spending = await getCurrentSpending(
            category: budget.categoryName,
            period: budget.periodEnum,
            startDate: budget.startDate
        )
        return max(spending - budget.amount, 0)
    }

    /// 获取剩余预算
    func getRemaining(budget: Budget) async -> Double {
        let spending = await getCurrentSpending(
            category: budget.categoryName,
            period: budget.periodEnum,
            startDate: budget.startDate
        )
        return max(budget.amount - spending, 0)
    }

    /// 获取预算详情
    func getBudgetDetail(budget: Budget) async -> BudgetDetail {
        let spending = await getCurrentSpending(
            category: budget.categoryName,
            period: budget.periodEnum,
            startDate: budget.startDate
        )

        let usage = spending / budget.amount
        let remaining = max(budget.amount - spending, 0)
        let overage = max(spending - budget.amount, 0)
        let isOver = spending > budget.amount

        return BudgetDetail(
            budget: budget,
            spending: spending,
            usage: usage,
            remaining: remaining,
            overage: overage,
            isOver: isOver
        )
    }

    /// 获取所有预算详情
    func getAllBudgetDetails() async -> [BudgetDetail] {
        var details: [BudgetDetail] = []

        for budget in budgets {
            let detail = await getBudgetDetail(budget: budget)
            details.append(detail)
        }

        return details.sorted { !$0.isOver && $1.isOver }
    }

    /// 检查所有预算警告
    func checkBudgetWarnings() async -> [BudgetWarning] {
        var warnings: [BudgetWarning] = []

        for budget in budgets {
            let detail = await getBudgetDetail(budget: budget)

            // 超支警告
            if detail.isOver {
                warnings.append(BudgetWarning(
                    budget: budget,
                    type: .exceeded,
                    message: "\(budget.displayName)已超支 ¥\(detail.overage, specifier: "%.2f")"
                ))
            }
            // 接近预算警告（90%）
            else if detail.usage >= 0.9 {
                warnings.append(BudgetWarning(
                    budget: budget,
                    type: .approaching,
                    message: "\(budget.displayName)已使用 \(Int(detail.usage * 100))%"
                ))
            }
        }

        return warnings
    }

    // MARK: - Helper Methods

    private func getDateRange(for period: Budget.BudgetPeriod, startDate: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .daily:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .weekly:
            let start = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)

        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)

        case .yearly:
            let components = calendar.dateComponents([.year], from: now)
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        }
    }
}

// MARK: - Supporting Types

struct BudgetDetail {
    let budget: Budget
    let spending: Double
    let usage: Double
    let remaining: Double
    let overage: Double
    let isOver: Bool

    var progressColor: String {
        switch usage {
        case 0..<0.7: return "green"
        case 0.7..<0.9: return "orange"
        default: return "red"
        }
    }
}

struct BudgetWarning {
    let budget: Budget
    let type: WarningType
    let message: String

    enum WarningType {
        case exceeded
        case approaching
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let budgetDidChange = Notification.Name("budgetDidChange")
}
