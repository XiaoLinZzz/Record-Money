# Widget 小组件实现指南

## 概述

本文档详细说明如何为 AutoBookkeeping App 添加 iOS Widget 小组件功能。

**Widget 类型**:
- 今日支出小组件（小/中/大）
- 本月预算进度小组件（中/大）
- 快速记账快捷方式（小）

---

## 前提条件

### 1. Xcode 项目配置

#### 创建 Widget Extension

1. 在 Xcode 中，选择 **File > New > Target**
2. 选择 **Widget Extension**
3. 命名为 `AutoBookkeepingWidget`
4. **不要**勾选 "Include Configuration Intent"（我们使用静态配置）
5. 点击 **Finish**

#### 配置 App Groups

Widget 需要通过 App Groups 与主 App 共享数据：

1. 选择主 App Target
2. 进入 **Signing & Capabilities**
3. 点击 **+ Capability**
4. 添加 **App Groups**
5. 创建 group: `group.com.yourcompany.autobookkeeping`

6. 选择 Widget Extension Target
7. 重复步骤 2-5，添加**相同的** App Group

---

## 数据共享实现

### 1. 扩展 DataManager

修改 `AutoBookkeeping/Services/DataManager.swift`，添加 Widget 数据更新方法：

```swift
import WidgetKit

// MARK: - Widget Data Sharing

extension DataManager {
    /// Widget App Group Identifier
    static let widgetAppGroupID = "group.com.yourcompany.autobookkeeping"

    /// 更新 Widget 数据
    func updateWidgetData() async {
        guard let sharedDefaults = UserDefaults(suiteName: Self.widgetAppGroupID) else {
            print("❌ 无法访问 App Group")
            return
        }

        // 今日支出
        let todayData = await getTodayExpenseData()
        sharedDefaults.set(todayData.amount, forKey: "todayExpense")
        sharedDefaults.set(todayData.count, forKey: "todayTransactionCount")

        // 本月预算
        if let budgetData = await getMonthlyBudgetData() {
            sharedDefaults.set(budgetData.spending, forKey: "monthlySpending")
            sharedDefaults.set(budgetData.budget, forKey: "monthlyBudget")
            sharedDefaults.set(budgetData.progress, forKey: "monthlyProgress")
        }

        // 刷新所有 Widget
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func getTodayExpenseData() async -> (amount: Double, count: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate {
                $0.type == "expense" &&
                $0.timestamp >= today &&
                $0.timestamp < tomorrow
            }
        )

        do {
            let transactions = try modelContext.fetch(descriptor)
            let total = transactions.reduce(0) { $0 + $1.amount }
            return (total, transactions.count)
        } catch {
            return (0, 0)
        }
    }

    private func getMonthlyBudgetData() async -> (spending: Double, budget: Double, progress: Double)? {
        // 获取总预算
        guard let totalBudget = await BudgetManager.shared.totalBudget else {
            return nil
        }

        // 获取本月支出
        let spending = await BudgetManager.shared.getCurrentSpending(
            category: nil,
            period: .monthly,
            startDate: totalBudget.startDate
        )

        let progress = spending / totalBudget.amount
        return (spending, totalBudget.amount, progress)
    }
}
```

### 2. 在交易保存时调用

修改 `saveTransaction()` 方法：

```swift
func saveTransaction(_ transaction: Transaction) async throws {
    modelContext.insert(transaction)
    try modelContext.save()

    // 更新 Widget 数据
    await updateWidgetData()

    NotificationCenter.default.post(
        name: .transactionDidChange,
        object: nil
    )
}
```

---

## Widget Extension 实现

### 文件结构

```
AutoBookkeepingWidget/
├── AutoBookkeepingWidget.swift       # Widget 入口
├── Providers/
│   ├── TodayExpenseProvider.swift    # 今日支出数据提供者
│   └── BudgetProgressProvider.swift  # 预算进度数据提供者
├── Views/
│   ├── TodayExpenseWidgetView.swift  # 今日支出视图
│   └── BudgetProgressWidgetView.swift # 预算进度视图
└── Models/
    └── WidgetData.swift              # Widget 数据模型
```

### 1. Widget 数据模型

`AutoBookkeepingWidget/Models/WidgetData.swift`:

```swift
import Foundation
import WidgetKit

struct TodayExpenseEntry: TimelineEntry {
    let date: Date
    let amount: Double
    let transactionCount: Int
}

struct BudgetProgressEntry: TimelineEntry {
    let date: Date
    let spending: Double
    let budget: Double
    let progress: Double
}
```

### 2. 今日支出 Provider

`AutoBookkeepingWidget/Providers/TodayExpenseProvider.swift`:

```swift
import WidgetKit

struct TodayExpenseProvider: TimelineProvider {
    typealias Entry = TodayExpenseEntry

    func placeholder(in context: Context) -> TodayExpenseEntry {
        TodayExpenseEntry(date: Date(), amount: 0, transactionCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayExpenseEntry) -> Void) {
        let entry = fetchTodayExpense()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayExpenseEntry>) -> Void) {
        let entry = fetchTodayExpense()

        // 每小时更新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func fetchTodayExpense() -> TodayExpenseEntry {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.autobookkeeping") else {
            return TodayExpenseEntry(date: Date(), amount: 0, transactionCount: 0)
        }

        let amount = sharedDefaults.double(forKey: "todayExpense")
        let count = sharedDefaults.integer(forKey: "todayTransactionCount")

        return TodayExpenseEntry(date: Date(), amount: amount, transactionCount: count)
    }
}
```

### 3. 今日支出视图

`AutoBookkeepingWidget/Views/TodayExpenseWidgetView.swift`:

```swift
import SwiftUI
import WidgetKit

struct TodayExpenseWidgetView: View {
    let entry: TodayExpenseEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallView(entry: entry)
        case .systemMedium:
            MediumView(entry: entry)
        case .systemLarge:
            LargeView(entry: entry)
        default:
            SmallView(entry: entry)
        }
    }

    // MARK: - Small Widget

    struct SmallView: View {
        let entry: TodayExpenseEntry

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                    Text("今日支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("¥\(entry.amount, specifier: "%.2f")")
                    .font(.system(size: 24, weight: .bold))
                    .minimumScaleFactor(0.5)

                Text("\(entry.transactionCount) 笔交易")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    // MARK: - Medium Widget

    struct MediumView: View {
        let entry: TodayExpenseEntry

        var body: some View {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.red)
                        Text("今日支出")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("¥\(entry.amount, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))

                    Text("\(entry.transactionCount) 笔交易")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 简单图表占位符
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.3))
                    Text("趋势")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }

    // MARK: - Large Widget

    struct LargeView: View {
        let entry: TodayExpenseEntry

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                    Text("今日支出")
                        .font(.headline)
                    Spacer()
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("¥\(entry.amount, specifier: "%.2f")")
                    .font(.system(size: 48, weight: .bold))

                HStack {
                    Text("\(entry.transactionCount) 笔交易")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                Spacer()

                // 提示信息
                Text("打开 App 查看详情")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}
```

### 4. Widget 入口

`AutoBookkeepingWidget/AutoBookkeepingWidget.swift`:

```swift
import WidgetKit
import SwiftUI

@main
struct AutoBookkeepingWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayExpenseWidget()
        BudgetProgressWidget()
    }
}

struct TodayExpenseWidget: Widget {
    let kind: String = "TodayExpenseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayExpenseProvider()) { entry in
            TodayExpenseWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("今日支出")
        .description("查看今天的支出总额和交易笔数")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

---

## Deep Link 集成

### 1. 添加 URL Scheme

在主 App 的 `Info.plist` 添加：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>autobookkeeping</string>
        </array>
    </dict>
</array>
```

### 2. Widget 添加链接

```swift
TodayExpenseWidgetView(entry: entry)
    .widgetURL(URL(string: "autobookkeeping://transactions")!)
```

### 3. App 处理 URL

在 `ContentView` 或 App 入口添加：

```swift
.onOpenURL { url in
    if url.scheme == "autobookkeeping" {
        // 处理不同路径
        switch url.host {
        case "transactions":
            // 跳转到交易列表
            break
        case "budget":
            // 跳转到预算页面
            break
        default:
            break
        }
    }
}
```

---

## 测试 Widget

### 1. 运行 Widget Extension

1. 在 Xcode 中选择 **AutoBookkeepingWidget** scheme
2. 选择模拟器或真机
3. 运行

### 2. 添加 Widget 到主屏幕

1. 长按主屏幕
2. 点击左上角 **+**
3. 搜索 "AutoBookkeeping"
4. 选择 Widget 尺寸
5. 添加到主屏幕

### 3. 测试数据更新

1. 打开主 App
2. 添加一笔交易
3. 返回主屏幕
4. Widget 应自动更新（可能需要几秒）

---

## 优化建议

### 1. 性能优化

- 使用 App Groups 共享数据，避免重复查询
- Widget 刷新策略：
  - 今日支出：每小时更新
  - 预算进度：每3小时更新
- 只传递必要数据到 UserDefaults

### 2. 视觉优化

- 使用 `containerBackground` 适配不同系统主题
- 深色模式适配
- 字体自适应缩放 (`minimumScaleFactor`)
- 合理使用 Spacer 和对齐

### 3. 用户体验

- Placeholder 提供合理默认值
- Snapshot 快速返回当前状态
- 错误处理（无数据时显示友好提示）
- Deep Link 跳转到相关页面

---

## 故障排除

### Widget 不更新

1. 检查 App Group 配置是否正确
2. 确认主 App 调用了 `updateWidgetData()`
3. 手动调用 `WidgetCenter.shared.reloadAllTimelines()`
4. 检查 UserDefaults suite name 是否一致

### 数据不同步

1. 验证 App Group ID 完全一致
2. 检查数据写入时机（在事务提交后）
3. 使用 `synchronize()` 强制同步（不推荐，已废弃）

### Widget 无法添加

1. 检查 Widget Extension target 已正确添加
2. 确认 `supportedFamilies` 配置正确
3. 清理构建文件夹（Shift+Cmd+K）
4. 重新安装 App

---

## 未来扩展

1. **交互式 Widget** (iOS 17+)
   - 快速记账按钮
   - 分类选择

2. **Live Activities** (iOS 16+)
   - 实时支出追踪
   - 动态岛集成

3. **智能建议**
   - 基于时间的提醒
   - 超支警告

4. **多语言支持**
   - 本地化字符串
   - 日期格式化

---

## 完整代码示例

由于 Widget Extension 是独立 target，完整代码需要在 Xcode 中创建。上述代码片段展示了核心实现逻辑。

**关键文件清单**：
- ✅ DataManager 扩展（Widget 数据更新）
- ✅ TodayExpenseProvider（Timeline Provider）
- ✅ TodayExpenseWidgetView（3种尺寸视图）
- ✅ Widget 入口（Configuration）
- ✅ Deep Link 处理

---

## 总结

Widget 实现需要：
1. 创建 Widget Extension Target
2. 配置 App Groups
3. 实现数据共享机制
4. 创建 Timeline Provider
5. 设计 Widget 视图
6. 测试和优化

**估算时间**: 8 小时
- Target 创建和配置: 1h
- 数据共享实现: 2h
- Provider 实现: 2h
- 视图设计: 2h
- 测试和优化: 1h

相关文档：
- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [App Groups Guide](https://developer.apple.com/documentation/xcode/configuring-app-groups)
