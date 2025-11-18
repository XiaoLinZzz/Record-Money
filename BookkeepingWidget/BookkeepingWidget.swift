//
//  BookkeepingWidget.swift
//  BookkeepingWidget
//
//  Widget Extension 主入口
//

import WidgetKit
import SwiftUI

@main
struct BookkeepingWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayExpenseWidget()
        BudgetProgressWidget()
        QuickAddWidget()
    }
}

// MARK: - Today Expense Widget

struct TodayExpenseWidget: Widget {
    let kind: String = "TodayExpenseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayExpenseProvider()) { entry in
            TodayExpenseWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("今日支出")
        .description("查看今天的支出统计")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Budget Progress Widget

struct BudgetProgressWidget: Widget {
    let kind: String = "BudgetProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetProgressProvider()) { entry in
            BudgetProgressWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("预算进度")
        .description("查看本月预算使用情况")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Quick Add Widget

struct QuickAddWidget: Widget {
    let kind: String = "QuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { entry in
            QuickAddWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("快速记账")
        .description("一键打开记账页面")
        .supportedFamilies([.systemSmall])
    }
}
