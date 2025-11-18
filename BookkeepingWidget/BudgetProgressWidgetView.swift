//
//  BudgetProgressWidgetView.swift
//  BookkeepingWidget
//
//  预算进度 Widget 视图
//

import SwiftUI
import WidgetKit

struct BudgetProgressWidgetView: View {

    @Environment(\.widgetFamily) var widgetFamily
    let entry: BudgetProgressEntry

    var body: some View {
        switch widgetFamily {
        case .systemMedium:
            MediumBudgetProgressView(entry: entry)
        case .systemLarge:
            LargeBudgetProgressView(entry: entry)
        default:
            MediumBudgetProgressView(entry: entry)
        }
    }
}

// MARK: - Medium Widget

struct MediumBudgetProgressView: View {
    let entry: BudgetProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                Text("本月预算")
                    .font(.headline)
                Spacer()
                Text("\(Calendar.current.component(.month, from: entry.date))月")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if entry.budgets.isEmpty {
                Spacer()
                Text("暂无预算数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                // 显示前2个预算
                ForEach(entry.budgets.prefix(2)) { budget in
                    BudgetProgressRow(budget: budget, isCompact: true)
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Large Widget

struct LargeBudgetProgressView: View {
    let entry: BudgetProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                Text("本月预算进度")
                    .font(.headline)
                Spacer()
                Text("\(Calendar.current.component(.month, from: entry.date))月")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            if entry.budgets.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无预算数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // 显示所有预算（最多5个）
                        ForEach(entry.budgets.prefix(5)) { budget in
                            BudgetProgressRow(budget: budget, isCompact: false)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Budget Progress Row

struct BudgetProgressRow: View {
    let budget: BudgetData
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 分类名称和百分比
            HStack {
                Text(budget.categoryName)
                    .font(isCompact ? .caption : .subheadline)
                    .fontWeight(.medium)

                Spacer()

                if budget.isOverBudget {
                    Text("超支")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                }

                Text("\(budget.percentage, specifier: "%.0f")%")
                    .font(isCompact ? .caption : .subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(budget.statusColor)
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // 进度
                    RoundedRectangle(cornerRadius: 4)
                        .fill(budget.statusColor)
                        .frame(width: min(geometry.size.width * CGFloat(budget.percentage / 100), geometry.size.width))
                }
            }
            .frame(height: isCompact ? 6 : 8)

            // 金额
            if !isCompact {
                HStack {
                    Text("¥\(budget.spentAmount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.primary)

                    Text("/")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("¥\(budget.budgetAmount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if budget.isOverBudget {
                        let overage = budget.spentAmount - budget.budgetAmount
                        Text("超 ¥\(overage, specifier: "%.0f")")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else {
                        let remaining = budget.budgetAmount - budget.spentAmount
                        Text("剩 ¥\(remaining, specifier: "%.0f")")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}
