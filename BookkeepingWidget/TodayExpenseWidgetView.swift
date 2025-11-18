//
//  TodayExpenseWidgetView.swift
//  BookkeepingWidget
//
//  今日支出 Widget 视图
//

import SwiftUI
import WidgetKit

struct TodayExpenseWidgetView: View {

    @Environment(\.widgetFamily) var widgetFamily
    let entry: TodayExpenseEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallTodayExpenseView(entry: entry)
        case .systemMedium:
            MediumTodayExpenseView(entry: entry)
        case .systemLarge:
            LargeTodayExpenseView(entry: entry)
        default:
            SmallTodayExpenseView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallTodayExpenseView: View {
    let entry: TodayExpenseEntry

    var body: some View {
        VStack(spacing: 8) {
            // 标题
            HStack {
                Image(systemName: "yensign.circle.fill")
                    .foregroundColor(.blue)
                Text("今日支出")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }

            Spacer()

            // 金额
            VStack(spacing: 4) {
                Text("¥\(entry.totalExpense, specifier: "%.2f")")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("\(entry.transactionCount) 笔交易")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Medium Widget

struct MediumTodayExpenseView: View {
    let entry: TodayExpenseEntry

    var body: some View {
        HStack(spacing: 16) {
            // 左侧：今日支出
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "yensign.circle.fill")
                        .foregroundColor(.blue)
                    Text("今日支出")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                Text("¥\(entry.totalExpense, specifier: "%.2f")")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("\(entry.transactionCount) 笔交易")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 右侧：最高分类
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.orange)
                    Text("最高分类")
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                if let topCategory = entry.topCategory {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topCategory)
                            .font(.headline)
                            .lineLimit(1)

                        Text("¥\(entry.topCategoryAmount, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("暂无数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

// MARK: - Large Widget

struct LargeTodayExpenseView: View {
    let entry: TodayExpenseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("今日账单")
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 今日支出
            VStack(alignment: .leading, spacing: 8) {
                Text("今日支出")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline) {
                    Text("¥")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("\(entry.totalExpense, specifier: "%.2f")")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .foregroundColor(.primary)

                Text("\(entry.transactionCount) 笔交易")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 最高分类
            if let topCategory = entry.topCategory {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最高支出分类")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(topCategory)
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("¥\(entry.topCategoryAmount, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        let percentage = entry.totalExpense > 0 ? (entry.topCategoryAmount / entry.totalExpense * 100) : 0
                        Text("\(percentage, specifier: "%.0f")%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange.opacity(0.7))
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
    }
}
