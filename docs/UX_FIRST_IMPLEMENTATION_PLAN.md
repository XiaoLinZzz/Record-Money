# 以用户体验为核心的实施计划

> 创建时间: 2024-11-18
> 设计原则: **流畅、简洁、Apple 原生、触觉丰富**

---

## 🎯 核心设计理念

### Apple Human Interface Guidelines 遵循

1. **清晰** (Clarity)
   - 文字清晰可读
   - 图标准确表意
   - 功能一目了然

2. **遵从** (Deference)
   - 内容为王
   - 减少装饰性元素
   - 使用系统字体和颜色

3. **深度** (Depth)
   - 合理使用层级
   - 恰当的动画和过渡
   - 触觉反馈增强真实感

### 触觉反馈策略

```swift
// UINotificationFeedbackGenerator - 完成/错误/警告
.success    // 操作成功（保存、删除、更新）
.error      // 操作失败
.warning    // 需要注意（预算超支）

// UIImpactFeedbackGenerator - 交互反馈
.light      // 轻量操作（点击按钮、切换标签）
.medium     // 中等操作（滑动操作、下拉刷新）
.heavy      // 重要操作（删除确认、重置数据）

// UISelectionFeedbackGenerator - 选择反馈
.selectionChanged  // 滚动选择器、切换分段控制
```

### 动画时长标准

```swift
// Apple 推荐的动画时长
超快: 0.1s  // 按钮按下反馈
快速: 0.2s  // 小型 UI 变化
标准: 0.3s  // 大部分过渡动画
缓慢: 0.5s  // 页面切换、模态弹出
```

---

## 📊 功能优先级矩阵（UX 视角）

| 功能 | 用户价值 | UX 影响 | 实现复杂度 | 优先级 | 预计工时 |
|------|---------|---------|-----------|--------|---------|
| **搜索和筛选** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 中 | 🔴 最高 | 6h |
| **全局 UX 优化** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 低 | 🔴 最高 | 3h |
| **预算管理 UI** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 中 | 🔴 高 | 8h |
| **图表可视化** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 中 | 🟡 中 | 10h |
| **自定义分类** | ⭐⭐⭐ | ⭐⭐⭐ | 中 | 🟡 中 | 6h |
| **数据导出** | ⭐⭐⭐ | ⭐⭐ | 低 | 🟡 中 | 4h |
| **Widget 小组件** | ⭐⭐ | ⭐⭐⭐⭐ | 中 | 🟢 低 | 8h |

---

## 🚀 Phase 1: 核心体验完善（预计 17 小时）

### 1.1 全局 UX 优化（3 小时）⚡ 立即实施

> **为什么优先做这个**：一次性为所有现有功能添加触觉反馈和动画，提升整体体验。

#### 实施内容

**1. 触觉反馈管理器**
```swift
// AutoBookkeeping/Services/HapticManager.swift

@MainActor
class HapticManager {
    static let shared = HapticManager()

    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // 操作成功（保存、更新）
    func success() { notificationGenerator.notificationOccurred(.success) }

    // 操作失败
    func error() { notificationGenerator.notificationOccurred(.error) }

    // 警告（预算超支）
    func warning() { notificationGenerator.notificationOccurred(.warning) }

    // 轻量点击（按钮、标签）
    func lightImpact() { impactLight.impactOccurred() }

    // 中等操作（滑动、下拉）
    func mediumImpact() { impactMedium.impactOccurred() }

    // 重要操作（删除）
    func heavyImpact() { impactHeavy.impactOccurred() }

    // 选择改变（分段控制）
    func selectionChanged() { selectionGenerator.selectionChanged() }

    // 准备生成器（提前准备，减少延迟）
    func prepare() {
        notificationGenerator.prepare()
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionGenerator.prepare()
    }
}
```

**2. 为现有功能添加触觉反馈**

```swift
// TransactionListView.swift
- 下拉刷新：mediumImpact()
- 点击交易：lightImpact()
- 删除成功：success()
- 删除失败：error()

// AddTransactionView.swift
- 保存成功：success()
- 保存失败：error()
- 切换类型（支出/收入）：selectionChanged()

// EditTransactionView.swift
- 更新成功：success()
- 更新失败：error()

// StatisticsView.swift
- 切换时间范围：selectionChanged()
```

**3. 动画优化**

```swift
// 列表项出现动画
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: transactions)

// 空状态图标动画
Image(systemName: "doc.text.magnifyingglass")
    .symbolEffect(.bounce, options: .repeating(3))  // iOS 17+

// 保存按钮禁用/启用过渡
.opacity(isValid ? 1.0 : 0.5)
.animation(.easeInOut(duration: 0.2), value: isValid)
```

**4. 加载状态优化**

```swift
// 骨架屏（Skeleton Screen）
struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 16)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 12)
                    }

                    Spacer()
                }
                .opacity(isAnimating ? 0.4 : 1.0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

// 使用
if isLoading {
    SkeletonView()
} else {
    transactionList
}
```

---

### 1.2 搜索和筛选功能（6 小时）

> **用户场景**：记录超过 50 条后，快速找到特定交易

#### UI 设计（Apple 原生风格）

```
┌─────────────────────────────────────┐
│  交易记录            [筛选] [+]      │  ← Toolbar
├─────────────────────────────────────┤
│  🔍 搜索商家、备注...               │  ← searchable()
├─────────────────────────────────────┤
│  [全部] [餐饮] [交通] [购物]...     │  ← ScrollView 筛选标签
├─────────────────────────────────────┤
│  今天                               │
│  ┌───────────────────────────────┐ │
│  │ 🍽️ 星巴克          -¥35.00   │ │
│  │ 餐饮 · 微信支付              │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ 🚗 滴滴出行        -¥12.50   │ │
│  │ 交通 · 支付宝                │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### 实现细节

**1. 搜索栏（使用 `.searchable()`）**

```swift
// TransactionListView.swift

@State private var searchText = ""
@State private var selectedCategory: String? = nil
@State private var selectedType: String? = nil

var body: some View {
    NavigationStack {
        transactionList
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索商家、备注..."
            )
            .onChange(of: searchText) { _, newValue in
                HapticManager.shared.lightImpact()  // 输入时轻微反馈
                Task {
                    await performSearch()
                }
            }
    }
}

// 搜索逻辑（防抖）
private var searchTask: Task<Void, Never>?

private func performSearch() async {
    searchTask?.cancel()

    searchTask = Task {
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms 防抖
        guard !Task.isCancelled else { return }

        await loadTransactions()
    }
}

// 过滤后的交易
private var filteredTransactions: [Transaction] {
    transactions.filter { transaction in
        // 搜索文本过滤
        if !searchText.isEmpty {
            let matchMerchant = transaction.merchant.localizedCaseInsensitiveContains(searchText)
            let matchNote = (transaction.note ?? "").localizedCaseInsensitiveContains(searchText)
            guard matchMerchant || matchNote else { return false }
        }

        // 分类过滤
        if let category = selectedCategory, category != "全部" {
            guard transaction.categoryName == category else { return false }
        }

        // 类型过滤
        if let type = selectedType {
            guard transaction.type == type else { return false }
        }

        return true
    }
}
```

**2. 筛选标签（横向滚动）**

```swift
// 筛选栏
private var filterBar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            // 全部
            FilterChip(
                title: "全部",
                isSelected: selectedCategory == nil,
                count: transactions.count
            ) {
                selectedCategory = nil
                HapticManager.shared.selectionChanged()
            }

            // 分类标签
            ForEach(uniqueCategories, id: \.self) { category in
                FilterChip(
                    title: category,
                    isSelected: selectedCategory == category,
                    count: transactions.filter { $0.categoryName == category }.count
                ) {
                    selectedCategory = category
                    HapticManager.shared.selectionChanged()
                }
            }
        }
        .padding(.horizontal)
    }
}

// 筛选标签组件（Apple 风格）
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
```

**3. 高级筛选 Sheet**

```swift
// 点击"筛选"按钮
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button {
            showFilterSheet = true
            HapticManager.shared.lightImpact()
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

// 筛选 Sheet
.sheet(isPresented: $showFilterSheet) {
    FilterSheet(
        selectedCategory: $selectedCategory,
        selectedType: $selectedType,
        dateRange: $dateRange
    )
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
}

// FilterSheet.swift
struct FilterSheet: View {
    @Binding var selectedCategory: String?
    @Binding var selectedType: String?
    @Binding var dateRange: DateRange?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("交易类型") {
                    Picker("类型", selection: $selectedType) {
                        Text("全部").tag(nil as String?)
                        Text("支出").tag("expense" as String?)
                        Text("收入").tag("income" as String?)
                    }
                    .pickerStyle(.segmented)
                }

                Section("日期范围") {
                    Button("今天") { setDateRange(.today) }
                    Button("本周") { setDateRange(.thisWeek) }
                    Button("本月") { setDateRange(.thisMonth) }
                    Button("自定义...") { showCustomDatePicker = true }
                }

                Section {
                    Button("重置筛选", role: .destructive) {
                        resetFilters()
                        HapticManager.shared.mediumImpact()
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }
            }
        }
    }
}
```

**触觉反馈策略**：
- 输入搜索：`lightImpact()`（每次输入）
- 切换筛选标签：`selectionChanged()`
- 清除搜索：`mediumImpact()`
- 应用筛选：`success()`

---

### 1.3 预算管理 UI（8 小时）

> **用户场景**：设置月度预算，实时查看消费进度，超支预警

#### UI 设计

```
┌─────────────────────────────────────┐
│  < 返回          预算管理      + │  │
├─────────────────────────────────────┤
│  📊 本月预算使用情况                │
│  ┌───────────────────────────────┐ │
│  │  已用 ¥2,450 / ¥3,000        │ │
│  │  ████████████░░░░  82%       │ │ ← 进度条（超80%变黄，超90%变红）
│  │  还剩 ¥550 (6天)             │ │
│  └───────────────────────────────┘ │
├─────────────────────────────────────┤
│  分类预算                           │
│  ┌───────────────────────────────┐ │
│  │ 🍽️ 餐饮                       │ │
│  │ ¥800 / ¥1,000        80%     │ │
│  │ ████████░░  ⚠️               │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ 🚗 交通                       │ │
│  │ ¥250 / ¥500         50%      │ │
│  │ █████░░░░░                   │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │ 🛍️ 购物                       │ │
│  │ ¥1,200 / ¥1,000     120%     │ │
│  │ ██████████  🔴 超支 ¥200     │ │ ← 超支警告
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### 实现细节

**1. BudgetManagementView.swift**

```swift
struct BudgetManagementView: View {
    @EnvironmentObject private var dataManager: DataManager

    @State private var budgets: [Budget] = []
    @State private var currentMonthStats: [String: Double] = [:]
    @State private var showAddBudget = false

    var body: some View {
        List {
            // 总预算卡片
            Section {
                TotalBudgetCard(
                    spent: totalSpent,
                    budget: totalBudget,
                    daysLeft: daysLeftInMonth
                )
            }

            // 分类预算列表
            Section("分类预算") {
                ForEach(budgets.filter { $0.isEnabled }) { budget in
                    BudgetRow(
                        budget: budget,
                        spent: currentMonthStats[budget.categoryName] ?? 0
                    )
                    .onTapGesture {
                        HapticManager.shared.lightImpact()
                        // 导航到编辑页面
                    }
                }
                .onDelete { indexSet in
                    HapticManager.shared.heavyImpact()
                    deleteBudgets(at: indexSet)
                }
            }

            // 添加预算按钮
            Section {
                Button {
                    showAddBudget = true
                    HapticManager.shared.lightImpact()
                } label: {
                    Label("添加分类预算", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("预算管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddBudget = true
                    HapticManager.shared.lightImpact()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddBudget) {
            AddBudgetView()
        }
        .task {
            await loadData()
        }
    }
}

// 总预算卡片（使用 Apple 风格渐变）
struct TotalBudgetCard: View {
    let spent: Double
    let budget: Double
    let daysLeft: Int

    private var percentage: Double {
        budget > 0 ? min(spent / budget, 1.0) : 0
    }

    private var statusColor: Color {
        if percentage >= 1.0 { return .red }
        if percentage >= 0.8 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本月已用")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: "¥%.0f", spent))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(statusColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("预算")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: "¥%.0f", budget))
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // 进度
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor.gradient)
                        .frame(
                            width: geometry.size.width * percentage,
                            height: 8
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: percentage)
                }
            }
            .frame(height: 8)

            // 底部信息
            HStack {
                if budget > spent {
                    Label {
                        Text(String(format: "还剩 ¥%.0f", budget - spent))
                            .font(.caption)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } else {
                    Label {
                        Text(String(format: "超支 ¥%.0f", spent - budget))
                            .font(.caption)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                Text("还剩 \(daysLeft) 天")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// 分类预算行
struct BudgetRow: View {
    let budget: Budget
    let spent: Double

    private var percentage: Double {
        budget.amount > 0 ? min(spent / budget.amount, 1.0) : 0
    }

    private var statusColor: Color {
        if percentage >= 1.0 { return .red }
        if percentage >= 0.8 { return .orange }
        return .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 分类图标
                CategoryIcon(categoryName: budget.categoryName)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.categoryName)
                        .font(.headline)

                    Text(String(format: "¥%.0f / ¥%.0f", spent, budget.amount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 百分比
                Text(String(format: "%.0f%%", percentage * 100))
                    .font(.headline)
                    .foregroundColor(statusColor)

                // 超支警告
                if percentage >= 1.0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .imageScale(.small)
                }
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(statusColor)
                        .frame(
                            width: geometry.size.width * min(percentage, 1.0),
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}
```

**触觉反馈策略**：
- 添加预算：`success()`
- 更新预算：`success()`
- 删除预算：`heavyImpact()`
- 预算超支警告：`warning()`（在 AddTransactionIntent 中）

---

## 🎨 Phase 2: 功能增强（预计 20 小时）

### 2.1 图表可视化 - Swift Charts（10 小时）

> **关键**：使用 Apple 原生的 Swift Charts 框架，无需第三方库

#### 图表类型

**1. 月度支出趋势（折线图）**
```swift
import Charts

struct MonthlyTrendChart: View {
    let data: [DailyExpense]

    var body: some View {
        Chart(data) { item in
            LineMark(
                x: .value("日期", item.date),
                y: .value("金额", item.amount)
            )
            .foregroundStyle(.blue.gradient)
            .interpolationMethod(.catmullRom)  // 平滑曲线

            // 添加数据点
            PointMark(
                x: .value("日期", item.date),
                y: .value("金额", item.amount)
            )
            .foregroundStyle(.blue)
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 3))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}
```

**2. 分类占比（环形图）**
```swift
struct CategoryPieChart: View {
    let data: [CategoryExpense]

    var body: some View {
        Chart(data) { item in
            SectorMark(
                angle: .value("金额", item.amount),
                innerRadius: .ratio(0.618),  // 黄金比例
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("分类", item.category))
            .cornerRadius(5)
        }
        .frame(height: 250)
        .chartLegend(position: .bottom, alignment: .center, spacing: 8)
    }
}
```

**触觉反馈**：
- 图表出现：`mediumImpact()`
- 点击图表数据点：`lightImpact()`
- 切换图表类型：`selectionChanged()`

### 2.2 自定义分类管理（6 小时）

**UI 特色**：
- 拖拽排序（`.onMove()`）
- SF Symbols 图标选择器
- 颜色选择器（ColorPicker）
- 关键词标签（TagCloud）

**触觉反馈**：
- 拖拽排序：`selectionChanged()`（拖动时）
- 添加关键词：`lightImpact()`
- 删除分类：`heavyImpact()`

### 2.3 数据导出（4 小时）

```swift
// 使用 UIActivityViewController 分享
let csvData = generateCSV(transactions)
let activityVC = UIActivityViewController(
    activityItems: [csvData],
    applicationActivities: nil
)

// 触觉反馈
HapticManager.shared.success()  // 导出成功
```

---

## 🎯 Phase 3: 高级功能（预计 8 小时）

### 3.1 Widget 小组件（8 小时）

**设计风格**：遵循 iOS Widget 设计规范

**小号 Widget**：
- 今日支出
- 大字体显示金额
- 简洁图标

**中号 Widget**：
- 今日支出 + 本月预算进度
- 进度条
- 剩余天数

**大号 Widget**：
- 本周支出趋势小图表
- 分类占比
- 快捷操作（点击跳转）

---

## 📱 全局 UX 增强清单

### 必须实现的细节

#### 1. 触觉反馈（所有交互）
- [ ] 所有按钮点击：`lightImpact()`
- [ ] 所有成功操作：`success()`
- [ ] 所有失败操作：`error()`
- [ ] 所有删除操作：`heavyImpact()`
- [ ] 所有选择切换：`selectionChanged()`
- [ ] 下拉刷新完成：`mediumImpact()`

#### 2. 动画过渡
- [ ] 页面切换：`.transition(.slide)`
- [ ] 模态弹出：`.transition(.move(edge: .bottom))`
- [ ] 列表项删除：`.transition(.asymmetric(...))`
- [ ] 数据加载：骨架屏淡入淡出

#### 3. 空状态
- [ ] 所有列表的空状态设计
- [ ] 动画图标
- [ ] 引导文案
- [ ] 快捷操作按钮

#### 4. 错误处理
- [ ] 友好的错误提示
- [ ] 重试按钮
- [ ] 错误图标

#### 5. 加载状态
- [ ] 骨架屏替代 ProgressView
- [ ] 下拉刷新
- [ ] 按钮加载状态（禁用+加载指示器）

---

## 🛠 技术实现标准

### Apple 原生组件优先使用

```swift
// ✅ 推荐：Apple 原生
NavigationStack, NavigationLink
List, Form
TextField, TextEditor
Toggle, Picker, DatePicker
Button, Label
HStack, VStack, LazyVStack
ScrollView
Sheet, Alert, ConfirmationDialog
Charts (Swift Charts)
searchable()
refreshable()
swipeActions()

// ❌ 避免：自定义重复造轮子
自定义导航栏
自定义列表
自定义输入框
```

### 颜色使用规范

```swift
// ✅ 使用语义化颜色（自动适配深色模式）
Color.primary
Color.secondary
Color.accentColor
Color(.systemBackground)
Color(.secondarySystemGroupedBackground)

// ✅ 状态颜色
Color.red     // 错误、删除、超支
Color.orange  // 警告、接近限制
Color.green   // 成功、正常
Color.blue    // 主色调
Color.gray    // 禁用

// ❌ 避免硬编码颜色
Color(red: 0.5, green: 0.5, blue: 0.5)
```

### 字体使用规范

```swift
// ✅ 使用系统字体和语义化样式
.font(.largeTitle)
.font(.title)
.font(.title2)
.font(.title3)
.font(.headline)
.font(.subheadline)
.font(.body)
.font(.callout)
.font(.caption)
.font(.caption2)
.font(.footnote)

// ✅ 支持动态字体
Text("金额")
    .font(.body)
    .dynamicTypeSize(.large...​.xxxLarge)
```

---

## 📋 实施顺序

### 第一周（17 小时）
1. ✅ **Day 1-2**: 全局 UX 优化（3h）
   - HapticManager 创建
   - 为所有现有功能添加触觉反馈
   - 动画优化
   - 骨架屏

2. **Day 3-4**: 搜索和筛选（6h）
   - 搜索栏实现
   - 筛选标签
   - 高级筛选 Sheet

3. **Day 5-7**: 预算管理 UI（8h）
   - BudgetManagementView
   - AddBudgetView
   - 预算卡片和进度条
   - 超支预警集成

### 第二周（20 小时）
4. **Day 8-10**: 图表可视化（10h）
   - Swift Charts 集成
   - 折线图、柱状图、饼图
   - 图表交互

5. **Day 11-13**: 自定义分类（6h）
   - 图标选择器
   - 颜色选择器
   - 关键词管理

6. **Day 14**: 数据导出（4h）
   - CSV 生成
   - 分享功能

### 第三周（8 小时）
7. **Day 15-17**: Widget 小组件（8h）
   - Widget Extension 创建
   - 三种尺寸设计
   - 数据刷新

---

## ✅ 验收标准

每个功能完成后，必须满足：

### 功能性
- [ ] 功能正常工作
- [ ] 边界情况处理
- [ ] 错误处理完善

### 用户体验
- [ ] 所有操作有触觉反馈
- [ ] 过渡动画流畅（60fps）
- [ ] 加载状态清晰
- [ ] 空状态友好

### 设计规范
- [ ] 使用 Apple 原生组件
- [ ] 遵循 HIG 设计规范
- [ ] 支持深色模式
- [ ] 支持动态字体

### 性能
- [ ] 列表滚动流畅
- [ ] 无内存泄漏
- [ ] 数据查询快速

---

**准备开始实施 ✅**

下一步：立即实施 Phase 1.1 - 全局 UX 优化
