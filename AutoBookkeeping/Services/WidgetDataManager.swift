//
//  WidgetDataManager.swift
//  AutoBookkeeping
//
//  Widget 数据共享管理器
//  负责将主 App 数据同步到 Widget Extension
//

import Foundation
import WidgetKit

/// Widget 数据管理器
class WidgetDataManager {

    // MARK: - Singleton

    static let shared = WidgetDataManager()

    // MARK: - Properties

    private let sharedDefaults: UserDefaults?
    private let appGroupID = "group.com.yourcompany.autobookkeeping"

    // MARK: - Initialization

    private init() {
        self.sharedDefaults = UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Public Methods

    /// 更新所有 Widget 数据
    func updateAllWidgetData() async {
        await updateTodayExpenseData()
        await updateBudgetProgressData()
        reloadAllWidgets()
    }

    /// 重新加载所有 Widget
    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Today Expense Data

    /// 更新今日支出数据
    private func updateTodayExpenseData() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        do {
            // 获取今日交易
            let transactions = try await DataManager.shared.fetchTransactions()
            let todayTransactions = transactions.filter { transaction in
                transaction.date >= startOfDay && transaction.date < endOfDay && transaction.isExpense
            }

            // 计算总支出
            let totalExpense = todayTransactions.reduce(0) { $0 + $1.amount }

            // 计算分类统计
            var categoryExpenses: [String: Double] = [:]
            for transaction in todayTransactions {
                categoryExpenses[transaction.categoryName, default: 0] += transaction.amount
            }

            // 找出最高支出分类
            let topCategory = categoryExpenses.max(by: { $0.value < $1.value })

            // 保存数据
            sharedDefaults?.set(totalExpense, forKey: "todayTotalExpense")
            sharedDefaults?.set(todayTransactions.count, forKey: "todayTransactionCount")
            sharedDefaults?.set(topCategory?.key, forKey: "todayTopCategory")
            sharedDefaults?.set(topCategory?.value ?? 0, forKey: "todayTopCategoryAmount")
            sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "todayExpenseLastUpdate")

        } catch {
            print("❌ 更新今日支出数据失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Budget Progress Data

    /// 更新预算进度数据
    private func updateBudgetProgressData() async {
        do {
            let budgets = try await DataManager.shared.fetchBudgets()
            let monthlyBudgets = budgets.filter { $0.period == "monthly" && $0.isEnabled }

            var budgetDataArray: [[String: Any]] = []

            for budget in monthlyBudgets {
                // 计算本月已用金额
                let spentAmount = await BudgetManager.shared.getCurrentSpending(
                    category: budget.categoryName,
                    period: .monthly,
                    startDate: budget.startDate
                )

                budgetDataArray.append([
                    "categoryName": budget.categoryName,
                    "budgetAmount": budget.amount,
                    "spentAmount": spentAmount
                ])
            }

            // 保存数据
            sharedDefaults?.set(budgetDataArray, forKey: "monthlyBudgets")
            sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "budgetProgressLastUpdate")

        } catch {
            print("❌ 更新预算进度数据失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    /// 交易数据变化通知
    static let transactionDidChange = Notification.Name("transactionDidChange")
    /// 预算数据变化通知
    static let budgetDidChange = Notification.Name("budgetDidChange")
}

// MARK: - DataManager Extension

extension DataManager {

    /// 在数据变化时更新 Widget
    func notifyWidgetDataChanged() {
        Task {
            await WidgetDataManager.shared.updateAllWidgetData()
        }
    }
}
