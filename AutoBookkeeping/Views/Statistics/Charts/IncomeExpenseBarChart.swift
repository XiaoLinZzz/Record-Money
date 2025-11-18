//
//  IncomeExpenseBarChart.swift
//  AutoBookkeeping
//
//  收支对比柱状图
//

import SwiftUI
import Charts

struct IncomeExpenseBarChart: View {

    // MARK: - Properties

    let data: [MonthlyData]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            Text("收支对比")
                .font(.headline)

            if data.isEmpty {
                emptyState
            } else {
                chart
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    // MARK: - Subviews

    private var chart: some View {
        VStack(spacing: 16) {
            // 柱状图
            Chart {
                ForEach(data) { item in
                    // 收入
                    BarMark(
                        x: .value("月份", item.month, unit: .month),
                        y: .value("金额", item.income)
                    )
                    .foregroundStyle(.green)
                    .position(by: .value("类型", "收入"))

                    // 支出
                    BarMark(
                        x: .value("月份", item.month, unit: .month),
                        y: .value("金额", item.expense)
                    )
                    .foregroundStyle(.red)
                    .position(by: .value("类型", "支出"))
                }
            }
            .chartForegroundStyleScale([
                "收入": .green,
                "支出": .red
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("¥\(amount, specifier: "%.0f")")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartLegend(position: .bottom)
            .frame(height: 250)

            // 统计摘要
            HStack(spacing: 20) {
                summaryItem(title: "总收入", amount: totalIncome, color: .green)
                summaryItem(title: "总支出", amount: totalExpense, color: .red)
                summaryItem(title: "净收益", amount: totalIncome - totalExpense, color: totalIncome >= totalExpense ? .green : .red)
            }
            .padding(.vertical, 8)
        }
    }

    private func summaryItem(title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("¥\(amount, specifier: "%.0f")")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("暂无数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var totalIncome: Double {
        data.reduce(0) { $0 + $1.income }
    }

    private var totalExpense: Double {
        data.reduce(0) { $0 + $1.expense }
    }
}

// MARK: - Preview

#Preview {
    IncomeExpenseBarChart(data: [
        MonthlyData(month: Date(), income: 5000, expense: 3000),
        MonthlyData(month: Date().addingTimeInterval(-2592000), income: 4500, expense: 3500)
    ])
    .padding()
}
