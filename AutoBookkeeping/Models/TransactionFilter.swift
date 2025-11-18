//
//  TransactionFilter.swift
//  AutoBookkeeping
//
//  交易筛选模型
//

import Foundation

struct TransactionFilter {
    var searchText: String = ""
    var selectedCategories: Set<String> = []
    var selectedType: TransactionType?
    var dateRange: DateRange?
    var amountRange: AmountRange?
    var selectedPaymentMethods: Set<String> = []

    enum TransactionType: String, CaseIterable, Identifiable {
        case income = "收入"
        case expense = "支出"

        var id: String { self.rawValue }

        var value: String {
            switch self {
            case .income: return "income"
            case .expense: return "expense"
            }
        }
    }

    struct DateRange: Equatable {
        var start: Date
        var end: Date

        static func today() -> DateRange {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: Date())
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return DateRange(start: start, end: end)
        }

        static func thisWeek() -> DateRange {
            let calendar = Calendar.current
            let now = Date()
            let start = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return DateRange(start: start, end: end)
        }

        static func thisMonth() -> DateRange {
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateRange(start: start, end: end)
        }

        static func last7Days() -> DateRange {
            let calendar = Calendar.current
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -7, to: end)!
            return DateRange(start: start, end: end)
        }

        static func last30Days() -> DateRange {
            let calendar = Calendar.current
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -30, to: end)!
            return DateRange(start: start, end: end)
        }
    }

    struct AmountRange: Equatable {
        var min: Double
        var max: Double
    }

    // MARK: - Computed Properties

    var isActive: Bool {
        return !searchText.isEmpty ||
               !selectedCategories.isEmpty ||
               selectedType != nil ||
               dateRange != nil ||
               amountRange != nil ||
               !selectedPaymentMethods.isEmpty
    }

    var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if !selectedCategories.isEmpty { count += selectedCategories.count }
        if selectedType != nil { count += 1 }
        if dateRange != nil { count += 1 }
        if amountRange != nil { count += 1 }
        if !selectedPaymentMethods.isEmpty { count += selectedPaymentMethods.count }
        return count
    }

    // MARK: - Methods

    mutating func clear() {
        searchText = ""
        selectedCategories.removeAll()
        selectedType = nil
        dateRange = nil
        amountRange = nil
        selectedPaymentMethods.removeAll()
    }

    func matches(_ transaction: Transaction) -> Bool {
        // 搜索文本
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            let merchantMatch = transaction.merchant.lowercased().contains(searchLower)
            let noteMatch = transaction.note?.lowercased().contains(searchLower) == true
            let categoryMatch = transaction.categoryName.lowercased().contains(searchLower)

            guard merchantMatch || noteMatch || categoryMatch else {
                return false
            }
        }

        // 分类筛选
        if !selectedCategories.isEmpty {
            guard selectedCategories.contains(transaction.categoryName) else {
                return false
            }
        }

        // 类型筛选
        if let type = selectedType {
            let isExpense = transaction.type == "expense"
            switch type {
            case .income: guard !isExpense else { return false }
            case .expense: guard isExpense else { return false }
            }
        }

        // 日期范围
        if let range = dateRange {
            guard transaction.timestamp >= range.start &&
                  transaction.timestamp < range.end else {
                return false
            }
        }

        // 金额范围
        if let range = amountRange {
            guard transaction.amount >= range.min &&
                  transaction.amount <= range.max else {
                return false
            }
        }

        // 支付方式
        if !selectedPaymentMethods.isEmpty {
            if let paymentMethod = transaction.paymentMethod {
                guard selectedPaymentMethods.contains(paymentMethod) else {
                    return false
                }
            } else {
                return false
            }
        }

        return true
    }
}
