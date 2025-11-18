//
//  ChartDataProvider.swift
//  AutoBookkeeping
//
//  图表数据提供者
//  为各种图表提供聚合数据
//

import Foundation
import SwiftData

@MainActor
class ChartDataProvider {

    static let shared = ChartDataProvider()

    private let modelContext: ModelContext

    private init() {
        self.modelContext = DataManager.shared.getModelContainer().mainContext
    }

    // MARK: - Daily Expenses (折线图数据)

    /// 获取每日支出数据
    func getDailyExpenses(days: Int) async -> [DailyExpense] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        // 获取交易
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate {
                $0.type == "expense" &&
                $0.timestamp >= startDate &&
                $0.timestamp <= endDate
            }
        )

        do {
            let transactions = try modelContext.fetch(descriptor)

            // 按日期分组
            var dailyMap: [Date: Double] = [:]
            for transaction in transactions {
                let day = calendar.startOfDay(for: transaction.timestamp)
                dailyMap[day, default: 0] += transaction.amount
            }

            // 填充所有日期（包括没有数据的日期）
            var result: [DailyExpense] = []
            for dayOffset in 0..<days {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) {
                    let day = calendar.startOfDay(for: date)
                    let amount = dailyMap[day] ?? 0
                    result.append(DailyExpense(date: day, amount: amount))
                }
            }

            return result.reversed()
        } catch {
            print("❌ 获取每日支出失败: \(error)")
            return []
        }
    }

    // MARK: - Category Expenses (饼图数据)

    /// 获取分类支出数据
    func getCategoryExpenses(period: TimePeriod) async -> [CategoryExpense] {
        let dateRange = getDateRange(for: period)

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate {
                $0.type == "expense" &&
                $0.timestamp >= dateRange.start &&
                $0.timestamp < dateRange.end
            }
        )

        do {
            let transactions = try modelContext.fetch(descriptor)

            // 按分类分组
            var categoryMap: [String: Double] = [:]
            for transaction in transactions {
                categoryMap[transaction.categoryName, default: 0] += transaction.amount
            }

            return categoryMap.map { CategoryExpense(category: $0.key, amount: $0.value) }
                .sorted { $0.amount > $1.amount }
        } catch {
            print("❌ 获取分类支出失败: \(error)")
            return []
        }
    }

    // MARK: - Income vs Expense (柱状图数据)

    /// 获取收支对比数据
    func getIncomeVsExpense(months: Int) async -> [MonthlyData] {
        let calendar = Calendar.current
        let endDate = Date()
        var result: [MonthlyData] = []

        for monthOffset in 0..<months {
            guard let targetDate = calendar.date(byAdding: .month, value: -monthOffset, to: endDate) else {
                continue
            }

            let components = calendar.dateComponents([.year, .month], from: targetDate)
            guard let monthStart = calendar.date(from: components),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                continue
            }

            // 获取收入
            let incomeDescriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate {
                    $0.type == "income" &&
                    $0.timestamp >= monthStart &&
                    $0.timestamp < monthEnd
                }
            )

            // 获取支出
            let expenseDescriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate {
                    $0.type == "expense" &&
                    $0.timestamp >= monthStart &&
                    $0.timestamp < monthEnd
                }
            )

            do {
                let incomeTransactions = try modelContext.fetch(incomeDescriptor)
                let expenseTransactions = try modelContext.fetch(expenseDescriptor)

                let income = incomeTransactions.reduce(0) { $0 + $1.amount }
                let expense = expenseTransactions.reduce(0) { $0 + $1.amount }

                result.append(MonthlyData(
                    month: monthStart,
                    income: income,
                    expense: expense
                ))
            } catch {
                print("❌ 获取月度数据失败: \(error)")
            }
        }

        return result.reversed()
    }

    // MARK: - Trend Analysis

    /// 获取支出趋势
    func getExpenseTrend(days: Int) async -> TrendData {
        let dailyExpenses = await getDailyExpenses(days: days)

        guard !dailyExpenses.isEmpty else {
            return TrendData(average: 0, total: 0, highest: 0, lowest: 0, trend: .stable)
        }

        let amounts = dailyExpenses.map { $0.amount }
        let total = amounts.reduce(0, +)
        let average = total / Double(dailyExpenses.count)
        let highest = amounts.max() ?? 0
        let lowest = amounts.min() ?? 0

        // 计算趋势（简单线性回归）
        let trend = calculateTrend(dailyExpenses)

        return TrendData(
            average: average,
            total: total,
            highest: highest,
            lowest: lowest,
            trend: trend
        )
    }

    // MARK: - Helper Methods

    private func getDateRange(for period: TimePeriod) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .thisWeek:
            let start = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)

        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)

        case .thisYear:
            let components = calendar.dateComponents([.year], from: now)
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)

        case .last7Days:
            let end = now
            let start = calendar.date(byAdding: .day, value: -7, to: end)!
            return (start, end)

        case .last30Days:
            let end = now
            let start = calendar.date(byAdding: .day, value: -30, to: end)!
            return (start, end)
        }
    }

    private func calculateTrend(_ dailyExpenses: [DailyExpense]) -> TrendDirection {
        guard dailyExpenses.count >= 2 else { return .stable }

        // 简单比较前半段和后半段的平均值
        let midPoint = dailyExpenses.count / 2
        let firstHalf = dailyExpenses[0..<midPoint].map { $0.amount }.reduce(0, +) / Double(midPoint)
        let secondHalf = dailyExpenses[midPoint...].map { $0.amount }.reduce(0, +) / Double(dailyExpenses.count - midPoint)

        let change = (secondHalf - firstHalf) / firstHalf

        if change > 0.1 {
            return .increasing
        } else if change < -0.1 {
            return .decreasing
        } else {
            return .stable
        }
    }
}

// MARK: - Data Models

struct DailyExpense: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct CategoryExpense: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double

    var percentage: Double = 0  // 将由视图计算
}

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: Date
    let income: Double
    let expense: Double

    var net: Double {
        income - expense
    }
}

struct TrendData {
    let average: Double
    let total: Double
    let highest: Double
    let lowest: Double
    let trend: TrendDirection
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable

    var displayText: String {
        switch self {
        case .increasing: return "上升"
        case .decreasing: return "下降"
        case .stable: return "稳定"
        }
    }

    var color: String {
        switch self {
        case .increasing: return "red"
        case .decreasing: return "green"
        case .stable: return "blue"
        }
    }
}

enum TimePeriod: String, CaseIterable, Identifiable {
    case today = "今天"
    case thisWeek = "本周"
    case thisMonth = "本月"
    case thisYear = "今年"
    case last7Days = "最近7天"
    case last30Days = "最近30天"

    var id: String { self.rawValue }
}
