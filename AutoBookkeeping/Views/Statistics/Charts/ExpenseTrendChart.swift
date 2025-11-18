//
//  ExpenseTrendChart.swift
//  AutoBookkeeping
//
//  支出趋势折线图
//

import SwiftUI
import Charts

struct ExpenseTrendChart: View {

    // MARK: - Properties

    let data: [DailyExpense]
    let period: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            Text("支出趋势")
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
        Chart(data) { item in
            // 折线
            LineMark(
                x: .value("日期", item.date),
                y: .value("金额", item.amount)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)

            // 面积填充
            AreaMark(
                x: .value("日期", item.date),
                y: .value("金额", item.amount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            // 数据点
            PointMark(
                x: .value("日期", item.date),
                y: .value("金额", item.amount)
            )
            .foregroundStyle(.blue)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(data.count / 5, 1))) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
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
        .frame(height: 250)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("暂无数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ExpenseTrendChart(
        data: [
            DailyExpense(date: Date(), amount: 100),
            DailyExpense(date: Date().addingTimeInterval(-86400), amount: 150),
            DailyExpense(date: Date().addingTimeInterval(-172800), amount: 80)
        ],
        period: "最近7天"
    )
    .padding()
}
