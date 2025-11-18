# BookkeepingWidget - Widget Extension

## 📱 Widget 小组件实现

本目录包含自动记账 App 的 Widget Extension 完整实现代码。

## 📁 文件结构

```
BookkeepingWidget/
├── BookkeepingWidget.swift              # Widget Bundle 主入口
├── Info.plist                           # Widget Extension 配置
├── README.md                            # 本文件
│
├── Providers/                           # Timeline Providers
│   ├── TodayExpenseProvider.swift       # 今日支出数据提供者
│   ├── BudgetProgressProvider.swift     # 预算进度数据提供者
│   └── QuickAddProvider.swift           # 快速记账数据提供者
│
└── Views/                               # Widget 视图
    ├── TodayExpenseWidgetView.swift     # 今日支出视图（小/中/大）
    ├── BudgetProgressWidgetView.swift   # 预算进度视图（中/大）
    └── QuickAddWidgetView.swift         # 快速记账视图（小）
```

## 🎯 Widget 类型

### 1. 今日支出 Widget (TodayExpenseWidget)
- **支持尺寸**: 小、中、大
- **功能**: 显示今日支出总额、交易笔数、最高支出分类
- **更新频率**: 每小时

### 2. 预算进度 Widget (BudgetProgressWidget)
- **支持尺寸**: 中、大
- **功能**: 显示本月预算进度，支持多分类预算监控
- **更新频率**: 每2小时

### 3. 快速记账 Widget (QuickAddWidget)
- **支持尺寸**: 小
- **功能**: 一键打开记账页面
- **更新频率**: 每天

## 🔧 在 Xcode 中配置

### 步骤 1: 创建 Widget Extension Target

1. 在 Xcode 中打开项目
2. File → New → Target
3. 选择 "Widget Extension"
4. 设置名称为 "BookkeepingWidget"
5. 取消勾选 "Include Configuration Intent"
6. 点击 "Finish"

### 步骤 2: 配置 App Groups

#### 主 App (AutoBookkeeping):
1. 选择主 App Target
2. 进入 "Signing & Capabilities"
3. 点击 "+ Capability"
4. 添加 "App Groups"
5. 点击 "+" 添加: `group.com.yourcompany.autobookkeeping`

#### Widget Extension (BookkeepingWidget):
1. 选择 Widget Extension Target
2. 重复上述步骤
3. 添加相同的 App Group

### 步骤 3: 导入源文件

1. 删除 Xcode 自动生成的 Widget 文件
2. 将本目录下的所有 `.swift` 文件添加到 Widget Extension Target
3. 将 `Info.plist` 设置为 Widget Extension 的 Info.plist

### 步骤 4: 在主 App 中集成数据共享

1. 将 `AutoBookkeeping/Services/WidgetDataManager.swift` 添加到主 App Target
2. 在 `DataManager.swift` 中合适的位置调用数据更新：

```swift
// 在交易创建/更新/删除后调用
func saveTransaction(_ transaction: Transaction) throws {
    // ... 保存逻辑
    notifyWidgetDataChanged()
}

// 在预算创建/更新/删除后调用
func saveBudget(_ budget: Budget) throws {
    // ... 保存逻辑
    notifyWidgetDataChanged()
}
```

### 步骤 5: 配置 URL Scheme (Deep Link)

1. 选择主 App Target
2. 进入 "Info" 标签
3. 展开 "URL Types"
4. 点击 "+" 添加新 URL Type
5. 设置:
   - **Identifier**: `com.yourcompany.autobookkeeping`
   - **URL Schemes**: `autobookkeeping`
   - **Role**: Editor

6. 在主 App 中处理 Deep Link (修改 `AutoBookkeepingApp.swift`):

```swift
@main
struct AutoBookkeepingApp: App {
    @StateObject private var dataManager = DataManager.shared
    @State private var showAddTransaction = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .sheet(isPresented: $showAddTransaction) {
                    AddTransactionView()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "autobookkeeping" else { return }

        switch url.host {
        case "add":
            showAddTransaction = true
        default:
            break
        }
    }
}
```

## 📊 数据共享机制

### UserDefaults Keys

主 App 通过 `WidgetDataManager` 更新以下数据：

**今日支出数据**:
- `todayTotalExpense`: Double - 今日总支出
- `todayTransactionCount`: Int - 交易笔数
- `todayTopCategory`: String? - 最高支出分类
- `todayTopCategoryAmount`: Double - 最高分类金额
- `todayExpenseLastUpdate`: TimeInterval - 最后更新时间

**预算进度数据**:
- `monthlyBudgets`: [[String: Any]] - 预算数组
  - `categoryName`: String
  - `budgetAmount`: Double
  - `spentAmount`: Double
- `budgetProgressLastUpdate`: TimeInterval - 最后更新时间

## 🧪 测试

### 1. 在模拟器中测试

```bash
# 运行主 App
⌘ + R

# 运行 Widget Extension（查看 Widget 预览）
选择 BookkeepingWidget scheme → ⌘ + R
```

### 2. 添加 Widget 到主屏幕

1. 长按主屏幕空白处
2. 点击左上角 "+"
3. 搜索 "记账"
4. 选择 Widget 并添加

### 3. 测试数据同步

1. 在主 App 中添加交易
2. 回到主屏幕查看 Widget 是否更新
3. 如果没有立即更新，等待刷新周期或重启 App

### 4. 测试 Deep Link

1. 添加"快速记账" Widget 到主屏幕
2. 点击 Widget
3. 应该打开主 App 并显示记账页面

## ⚠️ 注意事项

### App Group ID

请将代码中的 App Group ID 替换为你自己的：
- `group.com.yourcompany.autobookkeeping` → `group.YOUR_BUNDLE_ID`

需要修改的文件：
- `WidgetDataManager.swift:17`
- `TodayExpenseProvider.swift:47`
- `BudgetProgressProvider.swift:73`

### Bundle Identifier

Widget Extension 的 Bundle ID 应该是主 App 的子 ID：
- 主 App: `com.yourcompany.autobookkeeping`
- Widget: `com.yourcompany.autobookkeeping.BookkeepingWidget`

### SwiftData 共享

目前的实现使用 UserDefaults 共享数据。如果需要直接共享 SwiftData 数据库，需要：

1. 将 SwiftData 容器移到 App Group 目录
2. 在主 App 和 Widget 中都访问该容器
3. 注意并发访问的线程安全问题

## 🚀 性能优化

1. **Timeline 更新策略**:
   - 今日支出: 每小时更新（可根据需要调整）
   - 预算进度: 每2小时更新
   - 快速记账: 静态，每天更新一次

2. **数据缓存**:
   - Widget 读取缓存在 UserDefaults 中的数据
   - 主 App 负责更新缓存
   - 避免在 Widget 中进行复杂计算

3. **内存管理**:
   - Widget 有严格的内存限制（~30MB）
   - 只加载必要的数据
   - 避免加载大图片或复杂视图

## 📝 已知问题

1. **初次安装**: Widget 第一次添加时可能显示"暂无数据"，打开主 App 后会自动更新
2. **更新延迟**: Widget 更新有系统级别的限制，不是实时的
3. **后台限制**: iOS 系统会限制 Widget 的更新频率以节省电量

## 🔗 相关文档

- [WIDGET_IMPLEMENTATION_GUIDE.md](../docs/WIDGET_IMPLEMENTATION_GUIDE.md) - 详细实现指南
- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [App Groups Documentation](https://developer.apple.com/documentation/xcode/configuring-app-groups)

## ✅ 完成清单

- [x] Widget Bundle 主入口
- [x] 3个 Timeline Providers
- [x] 3套 Widget 视图（小/中/大）
- [x] 数据共享管理器
- [x] Info.plist 配置
- [x] Deep Link 支持
- [x] 完整文档

---

**所有代码已完成，可直接在 Xcode 中使用！** 🎉
