//
//  BudgetProgressProvider.swift
//  BookkeepingWidget
//
//  预算进度 Timeline Provider
//

import WidgetKit
import SwiftUI

// MARK: - Budget Progress Entry

struct BudgetProgressEntry: TimelineEntry {
    let date: Date
    let budgets: [BudgetData]
}

struct BudgetData: Identifiable {
    let id = UUID()
    let categoryName: String
    let budgetAmount: Double
    let spentAmount: Double
    let percentage: Double
    let isOverBudget: Bool

    var statusColor: Color {
        if isOverBudget {
            return .red
        } else if percentage >= 90 {
            return .orange
        } else if percentage >= 70 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Budget Progress Provider

struct BudgetProgressProvider: TimelineProvider {

    // MARK: - Placeholder

    func placeholder(in context: Context) -> BudgetProgressEntry {
        BudgetProgressEntry(
            date: Date(),
            budgets: [
                BudgetData(
                    categoryName: "餐饮",
                    budgetAmount: 2000,
                    spentAmount: 1650,
                    percentage: 82.5,
                    isOverBudget: false
                ),
                BudgetData(
                    categoryName: "交通",
                    budgetAmount: 500,
                    spentAmount: 420,
                    percentage: 84.0,
                    isOverBudget: false
                ),
                BudgetData(
                    categoryName: "购物",
                    budgetAmount: 1000,
                    spentAmount: 1150,
                    percentage: 115.0,
                    isOverBudget: true
                )
            ]
        )
    }

    // MARK: - Snapshot

    func getSnapshot(in context: Context, completion: @escaping (BudgetProgressEntry) -> Void) {
        let entry: BudgetProgressEntry

        if context.isPreview {
            entry = placeholder(in: context)
        } else {
            entry = loadBudgetProgress()
        }

        completion(entry)
    }

    // MARK: - Timeline

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetProgressEntry>) -> Void) {
        let entry = loadBudgetProgress()

        // 每2小时更新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    // MARK: - Data Loading

    private func loadBudgetProgress() -> BudgetProgressEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.autobookkeeping")

        var budgets: [BudgetData] = []

        if let budgetDataArray = sharedDefaults?.array(forKey: "monthlyBudgets") as? [[String: Any]] {
            for budgetDict in budgetDataArray {
                if let categoryName = budgetDict["categoryName"] as? String,
                   let budgetAmount = budgetDict["budgetAmount"] as? Double,
                   let spentAmount = budgetDict["spentAmount"] as? Double {

                    let percentage = budgetAmount > 0 ? (spentAmount / budgetAmount * 100) : 0
                    let isOverBudget = spentAmount > budgetAmount

                    budgets.append(BudgetData(
                        categoryName: categoryName,
                        budgetAmount: budgetAmount,
                        spentAmount: spentAmount,
                        percentage: percentage,
                        isOverBudget: isOverBudget
                    ))
                }
            }
        }

        return BudgetProgressEntry(date: Date(), budgets: budgets)
    }
}
