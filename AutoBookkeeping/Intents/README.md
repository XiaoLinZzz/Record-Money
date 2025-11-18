# App Intents

此目录包含所有 App Intents 实现，用于系统集成。

## Intents 列表

- `AddTransactionIntent.swift` - 添加交易记录 Intent
- `QuickExpenseIntent.swift` - 快速记账 Intent
- `ViewStatisticsIntent.swift` - 查看统计 Intent（计划中）
- `SetBudgetIntent.swift` - 设置预算 Intent（计划中）

## App Shortcuts

- `AppShortcuts.swift` - 注册 App 快捷指令

## 设计原则

1. **后台执行**: 设置 `openAppWhenRun = false`
2. **快速响应**: Intent 执行时间 < 10秒
3. **错误处理**: 提供清晰的错误信息
4. **对话反馈**: 返回有意义的对话文本

## 示例代码

```swift
import AppIntents
import Foundation

struct AddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "添加交易记录"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "金额")
    var amount: Double

    @Parameter(title: "商家")
    var merchant: String?

    @Parameter(title: "类型")
    var type: TransactionType

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 分类推断
        let category = await CategoryEngine.shared.inferCategory(
            merchant: merchant,
            rawText: nil
        )

        // 保存交易
        let transaction = Transaction(
            amount: amount,
            merchant: merchant ?? "未知",
            category: category
        )
        try await DataManager.shared.save(transaction)

        // 发送通知
        await NotificationManager.shared.sendConfirmation(transaction)

        return .result(
            dialog: "已记账: \\(merchant ?? "未知") ¥\\(amount) - \\(category)"
        )
    }
}
```

## 测试

```swift
func testAddTransactionIntent() async throws {
    let intent = AddTransactionIntent(
        amount: 35.0,
        merchant: "星巴克",
        type: .expense
    )
    let result = try await intent.perform()
    XCTAssertTrue(result.dialog.contains("已记账"))
}
```
