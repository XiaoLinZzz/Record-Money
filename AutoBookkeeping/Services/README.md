# 业务逻辑层

此目录包含核心业务逻辑和服务。

## 服务列表

### CategoryEngine.swift
**智能分类引擎**

负责根据商家名称和交易信息推断分类。

**功能**:
- 规则匹配
- 正则表达式匹配
- ML 模型推断（v2.0）
- 用户学习机制

**示例**:
```swift
let category = await CategoryEngine.shared.inferCategory(
    merchant: "星巴克",
    rawText: "微信支付 35.00"
)
// 返回: Category(name: "餐饮")
```

### DataManager.swift
**数据管理器**

统一的数据访问接口，管理所有数据操作。

**功能**:
- SwiftData CRUD 操作
- 事务管理
- 数据验证
- App Group 共享

**示例**:
```swift
// 保存交易
try await DataManager.shared.saveTransaction(transaction)

// 查询交易
let transactions = try await DataManager.shared.fetchTransactions(
    startDate: startDate,
    endDate: endDate
)

// 统计
let total = try await DataManager.shared.getMonthlyExpense(
    year: 2024,
    month: 11
)
```

### NotificationManager.swift
**通知管理器**

管理所有应用通知和用户提醒。

**功能**:
- 记账确认通知
- 预算预警
- 通知交互处理

**示例**:
```swift
// 发送记账确认
await NotificationManager.shared.sendConfirmation(transaction)

// 发送预算预警
await NotificationManager.shared.sendBudgetWarning(
    category: "餐饮",
    spent: 1500,
    budget: 2000,
    percentage: 75
)
```

### NaturalLanguageParser.swift
**自然语言解析器**

解析用户的自然语言输入。

**功能**:
- 金额提取
- 分类识别
- 商家提取

**示例**:
```swift
let parsed = NaturalLanguageParser.parse("买咖啡花了30元")
// 结果:
// amount: 30.0
// category: "餐饮"
// merchant: "咖啡"
```

## 设计原则

1. **单一职责**: 每个服务只负责一个领域
2. **单例模式**: 使用 `shared` 实例
3. **线程安全**: 使用 Actor 或 @MainActor
4. **依赖注入**: 便于测试
5. **错误处理**: 抛出明确的错误

## 架构图

```
Views
  ↓
ViewModels
  ↓
Services ← → DataManager ← → SwiftData
  ↓
Utilities
```

## 测试

每个服务都应该有对应的单元测试：

```swift
class CategoryEngineTests: XCTestCase {
    var sut: CategoryEngine!

    override func setUp() {
        sut = CategoryEngine.shared
    }

    func testInferCategory_ForStarbucks_ReturnsDining() async {
        let category = await sut.inferCategory(
            merchant: "星巴克",
            rawText: nil
        )
        XCTAssertEqual(category.name, "餐饮")
    }
}
```
