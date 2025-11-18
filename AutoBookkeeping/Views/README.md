# 视图层

此目录包含所有 SwiftUI 视图组件。

## 目录结构

```
Views/
├── Onboarding/           # 用户引导流程
│   ├── OnboardingView.swift
│   ├── WelcomeView.swift
│   ├── ShortcutInstallView.swift
│   └── TestAutomationView.swift
├── Transaction/          # 交易相关视图
│   ├── TransactionListView.swift
│   ├── TransactionDetailView.swift
│   ├── AddTransactionView.swift
│   └── TransactionRow.swift
├── Statistics/           # 统计分析视图
│   ├── StatisticsView.swift
│   ├── ChartView.swift
│   └── CategoryBreakdownView.swift
├── Settings/             # 设置页面
│   ├── SettingsView.swift
│   ├── CategoryManagementView.swift
│   └── AboutView.swift
└── Components/           # 可复用组件
    ├── CategoryPicker.swift
    ├── AmountTextField.swift
    └── DateRangePicker.swift
```

## 设计原则

1. **MVVM 架构**: 每个复杂视图都有对应的 ViewModel
2. **组件化**: 可复用的组件放在 Components 目录
3. **命名规范**: 视图文件以 View 结尾
4. **状态管理**: 使用 @State, @Binding, @ObservedObject 等

## 示例代码

```swift
import SwiftUI

struct TransactionListView: View {
    @StateObject private var viewModel = TransactionListViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
            .navigationTitle("交易记录")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("添加") {
                        viewModel.showAddTransaction = true
                    }
                }
            }
        }
        .task {
            await viewModel.loadTransactions()
        }
    }
}
```
