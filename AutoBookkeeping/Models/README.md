# 数据模型

此目录包含应用的所有数据模型定义。

## SwiftData 模型

- `Transaction.swift` - 交易记录模型
- `Category.swift` - 分类模型
- `Budget.swift` - 预算模型
- `Account.swift` - 账本模型（v1.5+）

## 模型关系

```
Account (账本)
    ↓ 1:N
Transaction (交易)
    ↓ N:1
Category (分类)
    ↓ 1:1
Budget (预算)
```

## 示例代码

```swift
import SwiftData
import Foundation

@Model
class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var merchant: String
    var categoryName: String
    var type: String
    var timestamp: Date

    init(amount: Double, merchant: String, category: String) {
        self.id = UUID()
        self.amount = amount
        self.merchant = merchant
        self.categoryName = category
        self.type = "expense"
        self.timestamp = Date()
    }
}
```
