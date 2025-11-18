# UX 功能技术实现规划

## 概述

本文档详细规划了剩余 UX 功能的技术实现方案，遵循 Apple Human Interface Guidelines 和用户体验最佳实践。

**总估算时间**: 38 小时
**实现优先级**: 按用户价值和 UX 影响排序

---

## Phase 1: 核心功能增强（最高优先级）

### 1. 搜索和筛选功能 (6 小时)

#### 功能需求
- ✅ 实时搜索交易（商家名称、备注）
- ✅ 按分类筛选
- ✅ 按交易类型筛选（收入/支出）
- ✅ 按日期范围筛选
- ✅ 组合筛选
- ✅ 清除筛选

#### 技术实现

**1.1 数据模型**
```swift
struct TransactionFilter {
    var searchText: String = ""
    var selectedCategories: Set<String> = []
    var selectedType: TransactionType? = nil
    var dateRange: DateRange? = nil

    enum TransactionType {
        case income
        case expense
    }

    struct DateRange {
        var start: Date
        var end: Date
    }
}
```

**1.2 核心文件**
- `AutoBookkeeping/Models/TransactionFilter.swift` - 筛选模型
- `AutoBookkeeping/Views/Transaction/TransactionSearchBar.swift` - 搜索栏组件
- `AutoBookkeeping/Views/Transaction/FilterTagsView.swift` - 横向标签
- `AutoBookkeeping/Views/Transaction/AdvancedFilterSheet.swift` - 高级筛选

**1.3 TransactionListView 改造**
```swift
@State private var filter = TransactionFilter()
@State private var showAdvancedFilter = false

var filteredTransactions: [Transaction] {
    transactions.filter { transaction in
        // 搜索文本
        if !filter.searchText.isEmpty {
            let searchLower = filter.searchText.lowercased()
            guard transaction.merchant.lowercased().contains(searchLower) ||
                  transaction.note?.lowercased().contains(searchLower) == true else {
                return false
            }
        }

        // 分类筛选
        if !filter.selectedCategories.isEmpty {
            guard filter.selectedCategories.contains(transaction.categoryName) else {
                return false
            }
        }

        // 类型筛选
        if let type = filter.selectedType {
            let isExpense = transaction.type == "expense"
            switch type {
            case .income: guard !isExpense else { return false }
            case .expense: guard isExpense else { return false }
            }
        }

        // 日期范围
        if let range = filter.dateRange {
            guard transaction.timestamp >= range.start &&
                  transaction.timestamp <= range.end else {
                return false
            }
        }

        return true
    }
}
```

**1.4 搜索栏 UI**
```swift
.searchable(
    text: $filter.searchText,
    placement: .navigationBarDrawer(displayMode: .always),
    prompt: "搜索交易..."
)
.onChange(of: filter.searchText) { _, _ in
    HapticManager.shared.lightImpact()
}
```

**1.5 筛选标签（横向滚动）**
```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 12) {
        // 分类标签
        ForEach(categories, id: \.self) { category in
            FilterChip(
                title: category,
                isSelected: filter.selectedCategories.contains(category)
            ) {
                toggleCategory(category)
            }
        }

        // 高级筛选按钮
        Button {
            showAdvancedFilter = true
        } label: {
            Label("更多", systemImage: "slider.horizontal.3")
        }
    }
    .padding(.horizontal)
}
```

**1.6 高级筛选 Sheet**
- 日期范围选择器（今天/本周/本月/自定义）
- 金额范围滑块
- 支付方式筛选
- 清除按钮

**1.7 性能优化**
- 搜索防抖（300ms）
- 使用 Combine 管理筛选状态
- 异步筛选避免阻塞 UI

---

### 2. 预算管理 UI (8 小时)

#### 功能需求
- ✅ 设置总预算
- ✅ 分类预算管理
- ✅ 实时预算追踪
- ✅ 超支警告
- ✅ 预算使用百分比
- ✅ 月度重置

#### 技术实现

**2.1 数据模型**
```swift
@Model
class Budget {
    var id: UUID = UUID()
    var categoryName: String?  // nil 表示总预算
    var amount: Double
    var period: BudgetPeriod
    var startDate: Date
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    enum BudgetPeriod: String, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
    }

    init(categoryName: String?, amount: Double, period: BudgetPeriod) {
        self.categoryName = categoryName
        self.amount = amount
        self.period = period
        self.startDate = Date()
    }
}
```

**2.2 BudgetManager 服务**
```swift
@MainActor
class BudgetManager: ObservableObject {
    static let shared = BudgetManager()

    @Published var totalBudget: Budget?
    @Published var categoryBudgets: [Budget] = []

    // 获取当前周期的支出
    func getCurrentSpending(
        category: String? = nil,
        period: Budget.BudgetPeriod
    ) async -> Double {
        let dateRange = getDateRange(for: period)
        let transactions = await fetchTransactions(
            category: category,
            startDate: dateRange.start,
            endDate: dateRange.end,
            type: "expense"
        )
        return transactions.reduce(0) { $0 + $1.amount }
    }

    // 计算预算使用百分比
    func getBudgetUsage(budget: Budget) async -> Double {
        let spending = await getCurrentSpending(
            category: budget.categoryName,
            period: budget.period
        )
        return min(spending / budget.amount, 1.0)
    }

    // 检查是否超支
    func isOverBudget(budget: Budget) async -> Bool {
        let usage = await getBudgetUsage(budget: budget)
        return usage > 1.0
    }

    // 获取超支金额
    func getOverage(budget: Budget) async -> Double {
        let spending = await getCurrentSpending(
            category: budget.categoryName,
            period: budget.period
        )
        return max(spending - budget.amount, 0)
    }
}
```

**2.3 核心文件**
- `AutoBookkeeping/Models/Budget.swift` - 预算模型
- `AutoBookkeeping/Services/BudgetManager.swift` - 预算管理器
- `AutoBookkeeping/Views/Budget/BudgetOverviewView.swift` - 预算概览
- `AutoBookkeeping/Views/Budget/BudgetDetailView.swift` - 预算详情
- `AutoBookkeeping/Views/Budget/SetBudgetView.swift` - 设置预算
- `AutoBookkeeping/Views/Budget/BudgetCardView.swift` - 预算卡片组件

**2.4 预算卡片 UI**
```swift
struct BudgetCardView: View {
    let budget: Budget
    @State private var usage: Double = 0.0
    @State private var spending: Double = 0.0

    var body: some View {
        VStack(spacing: 12) {
            // 标题和金额
            HStack {
                Text(budget.categoryName ?? "总预算")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("¥\(spending, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(progressColor)
                    Text("/ ¥\(budget.amount, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 进度条
            ProgressView(value: usage, total: 1.0)
                .progressViewStyle(.linear)
                .tint(progressColor)

            // 百分比和剩余
            HStack {
                Text("\(Int(usage * 100))% 已使用")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("剩余 ¥\(max(budget.amount - spending, 0), specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(usage > 1.0 ? .red : .green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    var progressColor: Color {
        switch usage {
        case 0..<0.7: return .green
        case 0.7..<0.9: return .orange
        default: return .red
        }
    }
}
```

**2.5 超支警告**
```swift
// 在 TransactionListView 或 BudgetOverviewView 中
.onAppear {
    Task {
        await checkBudgetWarnings()
    }
}

func checkBudgetWarnings() async {
    let budgets = await BudgetManager.shared.getAllBudgets()

    for budget in budgets {
        if await BudgetManager.shared.isOverBudget(budget: budget) {
            let overage = await BudgetManager.shared.getOverage(budget: budget)

            // 触觉警告
            HapticManager.shared.warning()

            // 通知
            NotificationManager.shared.sendBudgetWarning(
                category: budget.categoryName ?? "总预算",
                overage: overage
            )
        }
    }
}
```

**2.6 月度自动重置**
- 使用 Background Tasks 或 App Lifecycle 事件
- 检测新月份开始，重置统计（不删除预算设置）

---

## Phase 2: 功能增强（中优先级）

### 3. 图表可视化 (10 小时)

#### 功能需求
- ✅ 支出趋势折线图（7天/30天/365天）
- ✅ 分类占比饼图
- ✅ 收支对比柱状图
- ✅ 月度对比图
- ✅ 交互式图例
- ✅ 动画过渡

#### 技术实现

**3.1 使用 Swift Charts（iOS 16+）**
```swift
import Charts

struct ExpenseTrendChart: View {
    let data: [DailyExpense]

    var body: some View {
        Chart(data) { item in
            LineMark(
                x: .value("日期", item.date),
                y: .value("金额", item.amount)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("日期", item.date),
                y: .value("金额", item.amount)
            )
            .foregroundStyle(.blue)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 3))
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text("¥\(amount, specifier: "%.0f")")
                    }
                }
            }
        }
        .frame(height: 250)
    }
}

struct DailyExpense: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}
```

**3.2 分类饼图**
```swift
struct CategoryPieChart: View {
    let data: [CategoryExpense]

    var body: some View {
        Chart(data) { item in
            SectorMark(
                angle: .value("金额", item.amount),
                innerRadius: .ratio(0.5),  // 环形图
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("分类", item.category))
            .cornerRadius(5)
        }
        .chartLegend(position: .bottom, alignment: .center)
        .frame(height: 300)
    }
}

struct CategoryExpense: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}
```

**3.3 收支对比柱状图**
```swift
struct IncomeExpenseBarChart: View {
    let data: [MonthlyData]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("月份", item.month, unit: .month),
                y: .value("金额", item.income)
            )
            .foregroundStyle(.green)
            .position(by: .value("类型", "收入"))

            BarMark(
                x: .value("月份", item.month, unit: .month),
                y: .value("金额", item.expense)
            )
            .foregroundStyle(.red)
            .position(by: .value("类型", "支出"))
        }
        .chartForegroundStyleScale([
            "收入": .green,
            "支出": .red
        ])
        .frame(height: 250)
    }
}
```

**3.4 核心文件**
- `AutoBookkeeping/Views/Statistics/StatisticsView.swift` - 统计总览
- `AutoBookkeeping/Views/Statistics/Charts/ExpenseTrendChart.swift` - 趋势图
- `AutoBookkeeping/Views/Statistics/Charts/CategoryPieChart.swift` - 饼图
- `AutoBookkeeping/Views/Statistics/Charts/IncomeExpenseBarChart.swift` - 柱状图
- `AutoBookkeeping/Services/ChartDataProvider.swift` - 图表数据提供者

**3.5 数据聚合服务**
```swift
@MainActor
class ChartDataProvider {
    static let shared = ChartDataProvider()

    func getDailyExpenses(days: Int) async -> [DailyExpense] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!

        // 获取交易
        let transactions = await fetchTransactions(
            startDate: startDate,
            endDate: endDate,
            type: "expense"
        )

        // 按日期分组
        var dailyMap: [Date: Double] = [:]
        for transaction in transactions {
            let day = calendar.startOfDay(for: transaction.timestamp)
            dailyMap[day, default: 0] += transaction.amount
        }

        // 填充缺失日期
        var result: [DailyExpense] = []
        for dayOffset in 0..<days {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate)!
            let day = calendar.startOfDay(for: date)
            let amount = dailyMap[day] ?? 0
            result.append(DailyExpense(date: day, amount: amount))
        }

        return result.reversed()
    }

    func getCategoryExpenses(month: Date) async -> [CategoryExpense] {
        let dateRange = getMonthRange(for: month)
        let transactions = await fetchTransactions(
            startDate: dateRange.start,
            endDate: dateRange.end,
            type: "expense"
        )

        var categoryMap: [String: Double] = [:]
        for transaction in transactions {
            categoryMap[transaction.categoryName, default: 0] += transaction.amount
        }

        return categoryMap.map { CategoryExpense(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
}
```

**3.6 交互功能**
- 点击图表数据点显示详情
- 拖动选择日期范围
- 长按显示具体数值
- 图例点击切换显示/隐藏

---

### 4. 自定义分类管理 (6 小时)

#### 功能需求
- ✅ 添加自定义分类
- ✅ 编辑分类（名称、图标、颜色）
- ✅ 删除分类（迁移交易）
- ✅ 排序分类
- ✅ 设置常用分类
- ✅ 关键词管理

#### 技术实现

**4.1 Category 模型增强**
```swift
@Model
class Category {
    var id: UUID = UUID()
    var name: String
    var icon: String  // SF Symbol 名称
    var color: String  // 十六进制颜色
    var keywords: [String] = []
    var isCustom: Bool = false
    var order: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(name: String, icon: String, color: String, isCustom: Bool = true) {
        self.name = name
        self.icon = icon
        self.color = color
        self.isCustom = isCustom
    }

    var colorValue: Color {
        Color(hex: color) ?? .gray
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
```

**4.2 核心文件**
- `AutoBookkeeping/Models/Category.swift` - 增强的分类模型
- `AutoBookkeeping/Views/Category/CategoryManagementView.swift` - 分类管理
- `AutoBookkeeping/Views/Category/AddCategoryView.swift` - 添加分类
- `AutoBookkeeping/Views/Category/EditCategoryView.swift` - 编辑分类
- `AutoBookkeeping/Views/Category/IconPickerView.swift` - 图标选择器
- `AutoBookkeeping/Views/Category/ColorPickerView.swift` - 颜色选择器
- `AutoBookkeeping/Services/CategoryService.swift` - 分类服务

**4.3 图标选择器**
```swift
struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    let icons = [
        "餐饮": ["fork.knife", "cup.and.saucer", "birthday.cake", "wineglass"],
        "交通": ["car", "bus", "tram", "airplane", "bicycle"],
        "购物": ["cart", "bag", "gift", "creditcard"],
        "娱乐": ["gamecontroller", "tv", "music.note", "film"],
        "医疗": ["cross.case", "pills", "heart", "bandage"],
        "教育": ["book", "graduationcap", "pencil", "paperclane"],
        "生活": ["house", "lightbulb", "wifi", "phone"],
        "其他": ["ellipsis.circle", "star", "flag", "tag"]
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(icons.keys.sorted(), id: \.self) { category in
                    Section(category) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                            ForEach(icons[category]!, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                    HapticManager.shared.selectionChanged()
                                    dismiss()
                                } label: {
                                    VStack {
                                        Image(systemName: icon)
                                            .font(.system(size: 30))
                                            .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                            .frame(width: 60, height: 60)
                                            .background(
                                                selectedIcon == icon
                                                    ? Color.blue.opacity(0.1)
                                                    : Color.gray.opacity(0.1)
                                            )
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
```

**4.4 颜色选择器**
```swift
struct ColorPickerView: View {
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss

    let colors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A",
        "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E2",
        "#F8B739", "#52C234", "#FF6F91", "#5DADE2"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 颜色预览
                Circle()
                    .fill(Color(hex: selectedColor) ?? .gray)
                    .frame(width: 100, height: 100)
                    .shadow(radius: 5)

                // 颜色网格
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                    ForEach(colors, id: \.self) { colorHex in
                        Button {
                            selectedColor = colorHex
                            HapticManager.shared.selectionChanged()
                        } label: {
                            Circle()
                                .fill(Color(hex: colorHex) ?? .gray)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selectedColor == colorHex ? Color.white : Color.clear,
                                            lineWidth: 4
                                        )
                                )
                                .shadow(radius: selectedColor == colorHex ? 5 : 2)
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
```

**4.5 分类删除和迁移**
```swift
func deleteCategory(_ category: Category) async throws {
    // 检查是否有交易使用此分类
    let transactions = await fetchTransactions(category: category.name)

    if !transactions.isEmpty {
        // 显示迁移对话框
        showMigrationDialog(transactions: transactions, fromCategory: category)
    } else {
        // 直接删除
        try await CategoryService.shared.deleteCategory(category)
    }
}

func migrateTransactions(
    from oldCategory: Category,
    to newCategory: Category
) async throws {
    let transactions = await fetchTransactions(category: oldCategory.name)

    for transaction in transactions {
        transaction.categoryName = newCategory.name
    }

    try modelContext.save()
    try await CategoryService.shared.deleteCategory(oldCategory)
}
```

---

## Phase 3: 高级功能（高优先级）

### 5. Widget 小组件 (8 小时)

#### 功能需求
- ✅ 今日支出小组件
- ✅ 本月预算进度小组件
- ✅ 快速记账小组件
- ✅ 3 种尺寸（小、中、大）
- ✅ 深色模式适配
- ✅ 实时更新

#### 技术实现

**5.1 Widget Extension 架构**
```
AutoBookkeepingWidget/
├── AutoBookkeepingWidget.swift         # Widget 入口
├── Providers/
│   ├── TodayExpenseProvider.swift      # 今日支出数据提供者
│   ├── BudgetProgressProvider.swift    # 预算进度数据提供者
│   └── QuickAddProvider.swift          # 快速记账数据提供者
├── Views/
│   ├── TodayExpenseWidgetView.swift    # 今日支出视图
│   ├── BudgetProgressWidgetView.swift  # 预算进度视图
│   └── QuickAddWidgetView.swift        # 快速记账视图
└── Models/
    └── WidgetData.swift                # Widget 数据模型
```

**5.2 TimelineProvider**
```swift
struct TodayExpenseProvider: TimelineProvider {
    typealias Entry = TodayExpenseEntry

    func placeholder(in context: Context) -> TodayExpenseEntry {
        TodayExpenseEntry(date: Date(), amount: 0, transactionCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayExpenseEntry) -> Void) {
        Task {
            let entry = await fetchTodayExpense()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayExpenseEntry>) -> Void) {
        Task {
            let entry = await fetchTodayExpense()

            // 每小时更新一次
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    private func fetchTodayExpense() async -> TodayExpenseEntry {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // 使用 App Group 共享数据
        guard let sharedContainer = UserDefaults(suiteName: "group.com.yourapp.autobookkeeping") else {
            return TodayExpenseEntry(date: Date(), amount: 0, transactionCount: 0)
        }

        // 从共享容器读取数据
        let amount = sharedContainer.double(forKey: "todayExpense")
        let count = sharedContainer.integer(forKey: "todayTransactionCount")

        return TodayExpenseEntry(date: Date(), amount: amount, transactionCount: count)
    }
}

struct TodayExpenseEntry: TimelineEntry {
    let date: Date
    let amount: Double
    let transactionCount: Int
}
```

**5.3 Widget 视图（小尺寸）**
```swift
struct TodayExpenseWidgetSmallView: View {
    let entry: TodayExpenseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .foregroundColor(.red)
                Text("今日支出")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 金额
            Text("¥\(entry.amount, specifier: "%.2f")")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            // 笔数
            Text("\(entry.transactionCount) 笔交易")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
}
```

**5.4 Widget 视图（中尺寸）**
```swift
struct BudgetProgressWidgetMediumView: View {
    let entry: BudgetProgressEntry

    var body: some View {
        HStack(spacing: 16) {
            // 左侧：总预算
            VStack(alignment: .leading, spacing: 8) {
                Text("本月预算")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("¥\(entry.totalSpent, specifier: "%.0f")")
                    .font(.system(size: 28, weight: .bold))

                Text("/ ¥\(entry.totalBudget, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // 进度条
                ProgressView(value: entry.progress, total: 1.0)
                    .tint(progressColor(entry.progress))

                Text("\(Int(entry.progress * 100))% 已使用")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 右侧：分类预算
            VStack(alignment: .leading, spacing: 6) {
                Text("分类预算")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(entry.topCategories, id: \.name) { category in
                    HStack {
                        Circle()
                            .fill(Color(hex: category.color) ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(category.name)
                            .font(.caption2)
                        Spacer()
                        Text("\(Int(category.progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(progressColor(category.progress))
                    }
                }
            }
        }
        .padding()
    }

    func progressColor(_ progress: Double) -> Color {
        switch progress {
        case 0..<0.7: return .green
        case 0.7..<0.9: return .orange
        default: return .red
        }
    }
}
```

**5.5 Widget 视图（大尺寸）**
```swift
struct BudgetProgressWidgetLargeView: View {
    let entry: BudgetProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Text("本月预算追踪")
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 总预算卡片
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(entry.totalSpent, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("预算")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(entry.totalBudget, specifier: "%.2f")")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // 进度条
            VStack(spacing: 4) {
                ProgressView(value: entry.progress, total: 1.0)
                    .tint(progressColor(entry.progress))
                    .scaleEffect(x: 1, y: 2, anchor: .center)

                HStack {
                    Text("\(Int(entry.progress * 100))% 已使用")
                        .font(.caption2)
                    Spacer()
                    if entry.progress > 1.0 {
                        Text("超支 ¥\(entry.overage, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else {
                        Text("剩余 ¥\(entry.remaining, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }

            // 分类预算列表
            VStack(spacing: 8) {
                Text("分类预算")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(entry.allCategories, id: \.name) { category in
                    HStack {
                        Circle()
                            .fill(Color(hex: category.color) ?? .gray)
                            .frame(width: 10, height: 10)

                        Text(category.name)
                            .font(.caption)

                        Spacer()

                        ProgressView(value: category.progress, total: 1.0)
                            .tint(progressColor(category.progress))
                            .frame(width: 60)

                        Text("\(Int(category.progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(progressColor(category.progress))
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
    }
}
```

**5.6 App Group 配置**
1. 在 Xcode 中添加 App Groups capability
2. 创建 group: `group.com.yourapp.autobookkeeping`
3. 主 App 和 Widget Extension 都启用此 App Group

**5.7 数据同步**
```swift
// 在 DataManager 中，保存交易后更新 Widget 数据
func saveTransaction(_ transaction: Transaction) async throws {
    try modelContext.save()

    // 更新 Widget 数据
    await updateWidgetData()

    // 刷新 Widget
    WidgetCenter.shared.reloadAllTimelines()
}

private func updateWidgetData() async {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourapp.autobookkeeping") else {
        return
    }

    // 计算今日支出
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let todayTransactions = try? await fetchTransactions(startDate: today, type: "expense")

    let todayExpense = todayTransactions?.reduce(0) { $0 + $1.amount } ?? 0
    let todayCount = todayTransactions?.count ?? 0

    sharedDefaults.set(todayExpense, forKey: "todayExpense")
    sharedDefaults.set(todayCount, forKey: "todayTransactionCount")

    // 计算本月预算数据
    // ... (类似逻辑)
}
```

**5.8 Deep Link 支持**
```swift
@main
struct AutoBookkeepingWidget: Widget {
    let kind: String = "AutoBookkeepingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayExpenseProvider()) { entry in
            TodayExpenseWidgetView(entry: entry)
                .widgetURL(URL(string: "autobookkeeping://transactions")!)
        }
        .configurationDisplayName("今日支出")
        .description("查看今日支出总额和交易笔数")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

---

## 实施计划

### 优先级顺序
1. **搜索和筛选** (6h) - 立即开始
2. **预算管理** (8h)
3. **图表可视化** (10h)
4. **自定义分类** (6h)
5. **Widget 小组件** (8h)

### 每个功能的实施步骤
1. 创建数据模型
2. 实现核心服务
3. 构建 UI 组件
4. 集成触觉反馈
5. 添加动画效果
6. 测试和优化
7. 提交代码

### 性能优化
- 使用 SwiftData 的 `@Query` 进行高效查询
- 图表数据异步加载
- Widget 使用 App Group 共享数据
- 避免主线程阻塞

### 用户体验
- 所有操作都有触觉反馈
- 加载状态清晰提示
- 错误处理友好
- 动画流畅自然（遵循 Apple 时长规范）

---

## 技术要求

### 最低 iOS 版本
- iOS 16.0+ (Swift Charts)
- iOS 17.0+ (更好的 Widget 支持)

### 使用框架
- SwiftUI
- SwiftData
- Swift Charts
- WidgetKit
- Combine (可选，用于复杂状态管理)

### 遵循规范
- Apple Human Interface Guidelines
- SwiftUI 最佳实践
- 无障碍访问支持
- 深色模式适配

---

## 总结

本技术规划涵盖了所有剩余 UX 功能的完整实现方案。每个功能都有清晰的技术路径、代码示例和集成方案。接下来将按优先级顺序逐个实现这些功能。

**总时间**: 38 小时
**预期完成**: 高质量、符合 Apple 标准的用户体验增强
