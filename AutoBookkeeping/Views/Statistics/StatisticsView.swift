//
//  StatisticsView.swift
//  AutoBookkeeping
//
//  统计分析视图
//

import SwiftUI

struct StatisticsView: View {

    // MARK: - Environment

    @EnvironmentObject private var dataManager: DataManager

    // MARK: - State

    @State private var summary: StatisticsSummary?
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var isLoading = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间选择
                    periodPicker

                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let summary = summary {
                        // 总览卡片
                        overviewCards(summary: summary)

                        // 分类统计
                        categoryBreakdown(summary: summary)
                    }
                }
                .padding()
            }
            .navigationTitle("统计")
            .task {
                await loadStatistics()
            }
            .onChange(of: selectedPeriod) { _, _ in
                Task {
                    await loadStatistics()
                }
            }
        }
    }

    // MARK: - Subviews

    private var periodPicker: some View {
        Picker("时间范围", selection: $selectedPeriod) {
            Text("今天").tag(TimePeriod.today)
            Text("本周").tag(TimePeriod.thisWeek)
            Text("本月").tag(TimePeriod.thisMonth)
            Text("本年").tag(TimePeriod.thisYear)
        }
        .pickerStyle(.segmented)
    }

    private func overviewCards(summary: StatisticsSummary) -> some View {
        VStack(spacing: 16) {
            // 支出卡片
            StatCard(
                title: "总支出",
                amount: summary.totalExpense,
                color: .red,
                icon: "arrow.down.circle.fill"
            )

            // 收入卡片
            StatCard(
                title: "总收入",
                amount: summary.totalIncome,
                color: .green,
                icon: "arrow.up.circle.fill"
            )

            // 结余卡片
            StatCard(
                title: "结余",
                amount: summary.balance,
                color: summary.balance >= 0 ? .green : .red,
                icon: "equal.circle.fill"
            )
        }
    }

    private func categoryBreakdown(summary: StatisticsSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类统计")
                .font(.headline)
                .padding(.horizontal)

            if summary.categoryBreakdown.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(sortedCategories(summary.categoryBreakdown), id: \.key) { category, amount in
                        CategoryStatRow(
                            category: category,
                            amount: amount,
                            percentage: amount / summary.totalExpense
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }
        }
    }

    // MARK: - Methods

    private func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }

        let (startDate, endDate) = selectedPeriod.dateRange

        do {
            summary = try await dataManager.getStatisticsSummary(
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            print("加载统计数据失败: \(error.localizedDescription)")
        }
    }

    private func sortedCategories(_ breakdown: [String: Double]) -> [(key: String, value: Double)] {
        breakdown.sorted { $0.value > $1.value }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(String(format: "¥%.2f", amount))
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - Category Stat Row

struct CategoryStatRow: View {
    let category: String
    let amount: Double
    let percentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "¥%.2f", amount))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(String(format: "%.1f%%", percentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * percentage, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Time Period

enum TimePeriod {
    case today
    case thisWeek
    case thisMonth
    case thisYear

    var dateRange: (Date, Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)!.start
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
        }
    }
}

// MARK: - Preview

#Preview {
    StatisticsView()
        .environmentObject(DataManager.shared)
}
