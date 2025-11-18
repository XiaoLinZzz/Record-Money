# API 文档 API Documentation

本文档描述无感记账 App 的 App Intents API 接口。

---

## 概述

无感记账通过 App Intents 框架提供系统级 API，支持：
- 快捷指令调用
- Siri 语音指令
- Widget 交互
- 其他 App 集成

---

## App Intents

### 1. AddTransactionIntent

**描述**: 添加一笔交易记录

**使用场景**:
- 快捷指令自动化
- 第三方 App 集成
- Siri 快捷指令

#### 参数

| 参数名 | 类型 | 必需 | 说明 |
|--------|-----|------|------|
| `amount` | Double | ✅ | 交易金额 |
| `merchant` | String | ❌ | 商家名称 |
| `type` | TransactionType | ✅ | 交易类型（支出/收入） |
| `rawText` | String | ❌ | OCR 原始文本 |
| `paymentMethod` | String | ❌ | 支付方式 |

#### TransactionType 枚举

```swift
enum TransactionType: String, AppEnum {
    case expense = "支出"
    case income = "收入"
}
```

#### 返回值

```swift
IntentResult & ProvidesDialog
```

**成功响应**:
```
"已记账: 星巴克 ¥35.00 - 餐饮"
```

**错误响应**:
```
"记账失败: [错误信息]"
```

#### 示例

**快捷指令调用**:

```
运行快捷指令 "添加交易记录"
    金额: 35.0
    商家: "星巴克"
    类型: "支出"
    支付方式: "微信支付"
```

**Siri 调用**:

```
"嘿 Siri，用无感记账记一笔 35 元的星巴克"
```

---

### 2. QuickExpenseIntent

**描述**: 通过自然语言快速记账

**使用场景**:
- Siri 语音记账
- 快捷方式快速输入

#### 参数

| 参数名 | 类型 | 必需 | 说明 |
|--------|-----|------|------|
| `content` | String | ✅ | 记账内容（自然语言） |

#### 自然语言格式

支持的格式：
- `"50元餐饮"`
- `"买咖啡花了30"`
- `"在星巴克消费35块"`
- `"收入500工资"`

#### 解析规则

```swift
// 金额提取
Pattern: (\d+\.?\d*)\s*元?

// 分类提取
Keywords: 餐饮, 交通, 购物, 娱乐, etc.

// 商家提取
Pattern: (在|买|从)?(.+?)(花|买|支付)
```

#### 返回值

```swift
IntentResult & ProvidesDialog
```

**成功响应**:
```
"已记账 ¥50.00 - 餐饮"
```

#### 示例

**Siri 调用**:

```
"嘿 Siri，快速记账 50 元餐饮"
```

**快捷指令**:

```
运行快捷指令 "快速记账"
    内容: "买咖啡花了30"
```

---

### 3. ViewStatisticsIntent (计划中)

**描述**: 查看统计数据

**参数**:

| 参数名 | 类型 | 必需 | 说明 |
|--------|-----|------|------|
| `period` | StatisticsPeriod | ✅ | 统计周期 |
| `category` | String | ❌ | 指定分类 |

#### StatisticsPeriod 枚举

```swift
enum StatisticsPeriod: String, AppEnum {
    case today = "今天"
    case thisWeek = "本周"
    case thisMonth = "本月"
    case thisYear = "本年"
}
```

#### 返回值

```swift
struct StatisticsResult {
    var totalExpense: Double
    var totalIncome: Double
    var transactionCount: Int
    var topCategory: String
}
```

---

### 4. SetBudgetIntent (计划中)

**描述**: 设置预算

**参数**:

| 参数名 | 类型 | 必需 | 说明 |
|--------|-----|------|------|
| `category` | String | ✅ | 分类名称 |
| `amount` | Double | ✅ | 预算金额 |
| `period` | BudgetPeriod | ✅ | 预算周期 |

---

## App Entities

### TransactionEntity

```swift
struct TransactionEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "交易记录")

    var id: UUID
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(merchant) ¥\(amount)",
            subtitle: category
        )
    }

    var merchant: String
    var amount: Double
    var category: String
    var date: Date
}
```

**用途**:
- Siri 识别交易实体
- Widget 显示
- 快捷指令参数

---

### CategoryEntity

```swift
struct CategoryEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "分类")

    var id: UUID
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: name,
            image: DisplayRepresentation.Image(systemName: icon)
        )
    }

    var name: String
    var icon: String
}
```

---

## App Shortcuts

### 注册应用快捷指令

```swift
struct AutoBookkeepingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTransactionIntent(),
            phrases: [
                "用\(.applicationName)记账",
                "自动记账",
                "记一笔账"
            ],
            shortTitle: "快速记账",
            systemImageName: "dollarsign.circle"
        )
    }
}
```

### Siri 语音短语

支持的语音指令：
- "用无感记账记账"
- "自动记账 50 元"
- "记一笔 30 元的咖啡"
- "查看本月消费"

---

## 错误处理

### 错误类型

```swift
enum BookkeepingError: Error {
    case invalidAmount
    case invalidCategory
    case databaseError
    case unknown

    var localizedDescription: String {
        switch self {
        case .invalidAmount:
            return "金额无效"
        case .invalidCategory:
            return "分类不存在"
        case .databaseError:
            return "数据库错误"
        case .unknown:
            return "未知错误"
        }
    }
}
```

### 错误响应

Intent 执行失败时返回：

```swift
throw BookkeepingError.invalidAmount
// Siri 会说: "抱歉，金额无效"
```

---

## Widget 配置

### TimelineProvider

```swift
struct TransactionTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TransactionEntry {
        TransactionEntry(date: Date(), transaction: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TransactionEntry) -> Void) {
        // 返回最近一笔交易
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TransactionEntry>) -> Void) {
        // 生成时间线
    }
}
```

### Widget Intent

```swift
struct ConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "配置"

    @Parameter(title: "显示分类")
    var category: CategoryEntity?

    @Parameter(title: "显示数量")
    var count: Int
}
```

---

## 调试与测试

### 测试 Intent

**命令行测试**:

```bash
# 使用 xcrun
xcrun simctl launch booted com.yourapp.AutoBookkeeping \
    -AddTransactionIntent \
    -amount 50.0 \
    -merchant "星巴克" \
    -type expense
```

**Xcode 测试**:

```swift
func testAddTransactionIntent() async throws {
    let intent = AddTransactionIntent(
        amount: 50.0,
        merchant: "星巴克",
        type: .expense,
        rawText: nil,
        paymentMethod: "微信"
    )

    let result = try await intent.perform()

    XCTAssertTrue(result.dialog.contains("已记账"))
}
```

### 调试技巧

1. **打印日志**:
```swift
func perform() async throws -> some IntentResult {
    print("[Intent] AddTransactionIntent called with amount: \(amount)")
    // ...
}
```

2. **断点调试**:
在 Xcode 中设置断点，通过 Siri 或快捷指令触发

3. **Console.app**:
使用 macOS Console 查看设备日志

---

## 性能考虑

### 后台执行

Intent 在后台执行，应注意：

1. **执行时间**: 限制在 10 秒内
2. **内存使用**: 避免大量内存分配
3. **不打开 App**: 设置 `openAppWhenRun = false`

```swift
struct AddTransactionIntent: AppIntent {
    static var openAppWhenRun: Bool = false
    // ...
}
```

### 并发处理

使用 Swift Concurrency：

```swift
@MainActor
func perform() async throws -> some IntentResult {
    // 主线程操作
    try await dataManager.saveTransaction(transaction)
}
```

---

## 安全性

### 数据验证

```swift
func perform() async throws -> some IntentResult {
    // 验证金额
    guard amount > 0 else {
        throw BookkeepingError.invalidAmount
    }

    // 验证商家名称
    guard let merchant = merchant, !merchant.isEmpty else {
        throw BookkeepingError.invalidMerchant
    }

    // ...
}
```

### 权限检查

```swift
// 检查通知权限
let settings = await UNUserNotificationCenter.current().notificationSettings()
guard settings.authorizationStatus == .authorized else {
    // 处理未授权情况
}
```

---

## 最佳实践

### 1. 提供有意义的对话

```swift
// ✅ 好
return .result(dialog: "已记账: 星巴克 ¥35.00 - 餐饮")

// ❌ 差
return .result(dialog: "成功")
```

### 2. 处理边缘情况

```swift
// 处理缺失参数
let merchantName = merchant ?? "未知商家"

// 处理异常金额
let validAmount = max(0.01, min(amount, 999999.99))
```

### 3. 提供回退方案

```swift
// ML 分类失败时使用规则引擎
let category = await mlEngine.predict(merchant) ??
               await ruleEngine.classify(merchant)
```

---

## 版本兼容

### iOS 版本支持

| 功能 | 最低版本 | 说明 |
|-----|---------|------|
| App Intents | iOS 16.0 | 基础功能 |
| SwiftData | iOS 17.0 | 推荐使用 |
| Widget | iOS 16.0 | 支持 |
| Live Activities | iOS 16.1 | 计划支持 |

### 向后兼容

```swift
@available(iOS 16.0, *)
struct AddTransactionIntent: AppIntent {
    // iOS 16+ 实现
}

// iOS 15 及以下使用传统方式
```

---

## 参考资料

- [App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [Siri Integration Guide](https://developer.apple.com/documentation/sirikit)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)

---

*最后更新: 2024-11-18*
