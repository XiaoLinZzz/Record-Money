//
//  CategoryPieChart.swift
//  AutoBookkeeping
//
//  分类支出饼图
//

import SwiftUI
import Charts

struct CategoryPieChart: View {

    // MARK: - Properties

    let data: [CategoryExpense]

    // MARK: - Computed Properties

    private var dataWithPercentages: [CategoryExpense] {
        let total = data.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        return data.map { expense in
            var updated = expense
            updated.percentage = expense.amount / total
            return updated
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            Text("分类占比")
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
            // 饼图
            Chart(dataWithPercentages) { item in
                SectorMark(
                    angle: .value("金额", item.amount),
                    innerRadius: .ratio(0.5),  // 环形图
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("分类", item.category))
                .cornerRadius(5)
            }
            .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
            .frame(height: 250)

            // 详细列表
            VStack(spacing: 8) {
                ForEach(dataWithPercentages.prefix(5)) { item in
                    HStack {
                        Circle()
                            .fill(categoryColor(item.category))
                            .frame(width: 12, height: 12)

                        Text(item.category)
                            .font(.subheadline)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("¥\(item.amount, specifier: "%.2f")")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(Int(item.percentage * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("暂无数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 250)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "餐饮": return .orange
        case "交通": return .blue
        case "购物": return .pink
        case "娱乐": return .purple
        case "医疗": return .red
        case "教育": return .indigo
        case "生活": return .cyan
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    CategoryPieChart(data: [
        CategoryExpense(category: "餐饮", amount: 500),
        CategoryExpense(category: "交通", amount: 200),
        CategoryExpense(category: "购物", amount: 300)
    ])
    .padding()
}
