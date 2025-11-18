//
//  TodayExpenseProvider.swift
//  BookkeepingWidget
//
//  今日支出 Timeline Provider
//

import WidgetKit
import SwiftUI

// MARK: - Today Expense Entry

struct TodayExpenseEntry: TimelineEntry {
    let date: Date
    let totalExpense: Double
    let transactionCount: Int
    let topCategory: String?
    let topCategoryAmount: Double
}

// MARK: - Today Expense Provider

struct TodayExpenseProvider: TimelineProvider {

    // MARK: - Placeholder

    func placeholder(in context: Context) -> TodayExpenseEntry {
        TodayExpenseEntry(
            date: Date(),
            totalExpense: 128.50,
            transactionCount: 5,
            topCategory: "餐饮",
            topCategoryAmount: 65.00
        )
    }

    // MARK: - Snapshot

    func getSnapshot(in context: Context, completion: @escaping (TodayExpenseEntry) -> Void) {
        let entry: TodayExpenseEntry

        if context.isPreview {
            entry = placeholder(in: context)
        } else {
            entry = loadTodayExpense()
        }

        completion(entry)
    }

    // MARK: - Timeline

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayExpenseEntry>) -> Void) {
        let entry = loadTodayExpense()

        // 每小时更新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    // MARK: - Data Loading

    private func loadTodayExpense() -> TodayExpenseEntry {
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.autobookkeeping")

        let totalExpense = sharedDefaults?.double(forKey: "todayTotalExpense") ?? 0.0
        let transactionCount = sharedDefaults?.integer(forKey: "todayTransactionCount") ?? 0
        let topCategory = sharedDefaults?.string(forKey: "todayTopCategory")
        let topCategoryAmount = sharedDefaults?.double(forKey: "todayTopCategoryAmount") ?? 0.0

        return TodayExpenseEntry(
            date: Date(),
            totalExpense: totalExpense,
            transactionCount: transactionCount,
            topCategory: topCategory,
            topCategoryAmount: topCategoryAmount
        )
    }
}
