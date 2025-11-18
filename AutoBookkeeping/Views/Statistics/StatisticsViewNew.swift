//
//  StatisticsViewNew.swift
//  AutoBookkeeping
//
//  统计视图（新版 Swift Charts）
//  展示各类图表和数据分析
//

import SwiftUI

struct StatisticsViewNew: View {

    // MARK: - State

    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var trendDays: Int = 7

    @State private var dailyExpenses: [DailyExpense] = []
    @State private var categoryExpenses: [CategoryExpense] = []
    @State private var monthlyData: [MonthlyData] = []
    @State private var trendData: TrendData?

    @State private var isLoading = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 周期选择器
                    periodSelector

                    // 趋势摘要卡片
                    if let trend = trendData {
                        trendSummaryCard(trend)
                    }

                    // 支出趋势折线图
                    if !dailyExpenses.isEmpty {
                        ExpenseTrendChart(
                            data: dailyExpenses,
                            period: "\(trendDays)天"
                        )
                        .padding(.horizontal)
                    }

                    // 分类占比饼图
                    if !categoryExpenses.isEmpty {
                        CategoryPieChart(data: categoryExpenses)
                            .padding(.horizontal)
                    }

                    // 收支对比柱状图
                    if !monthlyData.isEmpty {
                        IncomeExpenseBarChart(data: monthlyData)
                            .padding(.horizontal)
                    }

                    // 空状态
                    if dailyExpenses.isEmpty && categoryExpenses.isEmpty && monthlyData.isEmpty && !isLoading {
                        emptyStateView
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("统计")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("趋势天数", selection: $trendDays) {
                            Text("7天").tag(7)
                            Text("14天").tag(14)
                            Text("30天").tag(30)
                            Text("90天").tag(90)
                        }
                        .onChange(of: trendDays) { _, _ in
                            Task { await loadTrendData() }
                            HapticManager.shared.selectionChanged()
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .task {
                await loadAllData()
            }
            .refreshable {
                await loadAllData()
                HapticManager.shared.mediumImpact()
            }
            .overlay {
                if isLoading {
                    ProgressView("加载中...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Subviews

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TimePeriod.allCases) { period in
                    Button {
                        selectedPeriod = period
                        Task { await loadPeriodData() }
                        HapticManager.shared.selectionChanged()
                    } label: {
                        Text(period.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedPeriod == period
                                    ? Color.blue
                                    : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(selectedPeriod == period ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func trendSummaryCard(_ trend: TrendData) -> some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("支出分析")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: trendIcon(trend.trend))
                    Text(trend.trend.displayText)
                }
                .font(.caption)
                .foregroundColor(trendColor(trend.trend))
            }

            // 统计数据
            HStack(spacing: 0) {
                statisticItem(title: "总支出", value: trend.total, color: .blue)
                Divider().frame(height: 40)
                statisticItem(title: "日均", value: trend.average, color: .orange)
                Divider().frame(height: 40)
                statisticItem(title: "最高", value: trend.highest, color: .red)
                Divider().frame(height: 40)
                statisticItem(title: "最低", value: trend.lowest, color: .green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func statisticItem(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("¥\(value, specifier: "%.0f")")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无统计数据")
                .font(.title2)
                .fontWeight(.semibold)

            Text("开始记账后即可查看统计信息")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }

    // MARK: - Helper Methods

    private func trendIcon(_ trend: TrendDirection) -> String {
        switch trend {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .blue
        }
    }

    // MARK: - Data Loading

    private func loadAllData() async {
        isLoading = true
        defer { isLoading = false }

        await loadTrendData()
        await loadPeriodData()
        await loadMonthlyData()
    }

    private func loadTrendData() async {
        dailyExpenses = await ChartDataProvider.shared.getDailyExpenses(days: trendDays)
        trendData = await ChartDataProvider.shared.getExpenseTrend(days: trendDays)
    }

    private func loadPeriodData() async {
        categoryExpenses = await ChartDataProvider.shared.getCategoryExpenses(period: selectedPeriod)
    }

    private func loadMonthlyData() async {
        monthlyData = await ChartDataProvider.shared.getIncomeVsExpense(months: 6)
    }
}

// MARK: - Preview

#Preview {
    StatisticsViewNew()
}
