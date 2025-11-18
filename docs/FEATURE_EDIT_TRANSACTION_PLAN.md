# 交易编辑功能 - 技术实现规划

> 创建时间: 2024-11-18
> 预计工时: 4 小时
> 优先级: 🔴 最高

---

## 📋 功能需求

### 用户故事
**作为**一个用户
**我想要**能够编辑已创建的交易记录
**以便**修正错误的金额、商家、分类或日期

### 核心功能
1. ✅ 查看交易详情时，提供"编辑"按钮
2. ✅ 打开编辑页面，预填充当前交易数据
3. ✅ 允许修改所有字段（金额、商家、分类、类型、日期、备注）
4. ✅ 保存时更新数据库
5. ✅ 如果用户修改了分类，触发智能学习
6. ✅ 提供触觉反馈和成功提示

### 边界情况
- ❌ 不允许将金额改为 0 或负数
- ❌ 不允许商家名称为空
- ⚠️ 修改日期时，不能选择未来时间
- ⚠️ 如果修改失败，不关闭页面，显示错误提示

---

## 🏗 技术架构

### 涉及的文件

#### 新建文件
```
AutoBookkeeping/Views/Transaction/EditTransactionView.swift
```

#### 修改文件
```
1. AutoBookkeeping/Views/Transaction/TransactionDetailView.swift
   - 添加"编辑"按钮
   - 添加 sheet 展示 EditTransactionView

2. AutoBookkeeping/Services/DataManager.swift
   - 新增 updateTransaction() 方法

3. AutoBookkeeping/Services/CategoryEngine.swift
   - 已有 learnFromUserCorrection() 方法（无需修改）

4. AutoBookkeeping/Views/Transaction/TransactionListView.swift
   - 添加删除确认弹窗（顺便优化）
```

---

## 🎨 UI 设计

### EditTransactionView 布局

```
┌─────────────────────────────────────┐
│  < 取消          编辑交易      保存 >  │
├─────────────────────────────────────┤
│                                     │
│  金额                               │
│  ┌─────────────────────────────┐   │
│  │ ¥ 35.00                     │   │
│  └─────────────────────────────┘   │
│                                     │
│  商家                               │
│  ┌─────────────────────────────┐   │
│  │ 星巴克                       │   │
│  └─────────────────────────────┘   │
│                                     │
│  分类                               │
│  ┌─────────────────────────────┐   │
│  │ 餐饮                    ▼   │   │
│  └─────────────────────────────┘   │
│                                     │
│  类型                               │
│  ┌─────────────────────────────┐   │
│  │ [支出] [收入]               │   │
│  └─────────────────────────────┘   │
│                                     │
│  日期                               │
│  ┌─────────────────────────────┐   │
│  │ 2024-11-18  14:30           │   │
│  └─────────────────────────────┘   │
│                                     │
│  备注                               │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### TransactionDetailView 变更

添加编辑按钮到 toolbar：

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("编辑") {
            showEditView = true
        }
    }

    ToolbarItem(placement: .confirmationAction) {
        Button("完成") {
            dismiss()
        }
    }
}
```

---

## 💾 数据流设计

### 1. 打开编辑页面

```
TransactionDetailView
    ↓ (用户点击"编辑")
showEditView = true
    ↓
.sheet(isPresented: $showEditView)
    ↓
EditTransactionView(transaction: transaction)
    ↓
@State 初始化为 transaction 的值
```

### 2. 编辑并保存

```
EditTransactionView
    ↓ (用户修改字段)
@State 变量更新
    ↓ (用户点击"保存")
表单验证
    ↓ (验证通过)
创建新的 Transaction 对象
    ↓
dataManager.updateTransaction(originalTransaction, newTransaction)
    ↓
SwiftData 更新数据库
    ↓
NotificationCenter.post(.transactionDidChange)
    ↓
TransactionListView 自动刷新
    ↓
dismiss EditTransactionView
    ↓
dismiss TransactionDetailView (返回列表)
```

### 3. 分类学习逻辑

```
if originalTransaction.categoryName != newTransaction.categoryName {
    CategoryEngine.shared.learnFromUserCorrection(
        merchant: newTransaction.merchant,
        correctedCategory: newTransaction.categoryName
    )
}
```

---

## 🔧 实现细节

### 1. EditTransactionView.swift

```swift
struct EditTransactionView: View {
    // MARK: - Properties
    let originalTransaction: Transaction

    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - State
    @State private var amount: String = ""
    @State private var merchant: String = ""
    @State private var selectedCategory: String = ""
    @State private var transactionType: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()

    @State private var categories: [String] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // 复用 AddTransactionView 的布局
                // ...
            }
            .navigationTitle("编辑交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task { await updateTransaction() }
                    }
                    .disabled(isSubmitting || !isValid)
                }
            }
            .task {
                await loadCategories()
                initializeFields()
            }
        }
    }

    // MARK: - Methods

    private func initializeFields() {
        amount = String(originalTransaction.amount)
        merchant = originalTransaction.merchant
        selectedCategory = originalTransaction.categoryName
        transactionType = originalTransaction.type
        note = originalTransaction.note ?? ""
        date = originalTransaction.timestamp
    }

    private func updateTransaction() async {
        guard isValid else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        guard let amountValue = Double(amount) else {
            errorMessage = "金额格式不正确"
            return
        }

        // 创建新的 Transaction 对象
        let updatedTransaction = Transaction(
            amount: amountValue,
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            categoryName: selectedCategory,
            type: transactionType,
            paymentMethod: originalTransaction.paymentMethod,
            rawText: originalTransaction.rawText,
            timestamp: date,
            note: note.isEmpty ? nil : note
        )

        do {
            // 调用 DataManager 更新
            try await dataManager.updateTransaction(
                originalTransaction,
                with: updatedTransaction
            )

            // 触觉反馈
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            dismiss()
        } catch {
            errorMessage = "更新失败: \(error.localizedDescription)"
        }
    }

    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
```

### 2. DataManager.updateTransaction()

```swift
// 在 DataManager.swift 添加

/// 更新交易记录
/// - Parameters:
///   - original: 原始交易对象
///   - updated: 更新后的交易数据
func updateTransaction(
    _ original: Transaction,
    with updated: Transaction
) async throws {
    // 更新字段
    original.amount = updated.amount
    original.merchant = updated.merchant
    original.categoryName = updated.categoryName
    original.type = updated.type
    original.timestamp = updated.timestamp
    original.note = updated.note

    // 保存到数据库
    try modelContext.save()

    // 如果分类改变，触发学习
    if original.categoryName != updated.categoryName {
        await CategoryEngine.shared.learnFromUserCorrection(
            merchant: updated.merchant,
            correctedCategory: updated.categoryName
        )
    }

    // 发送数据变更通知
    NotificationCenter.default.post(
        name: .transactionDidChange,
        object: nil
    )
}
```

### 3. TransactionDetailView 修改

```swift
struct TransactionDetailView: View {
    let transaction: Transaction

    @Environment(\.dismiss) private var dismiss
    @State private var showEditView = false  // 新增

    var body: some View {
        NavigationStack {
            List {
                // ... 现有内容
            }
            .navigationTitle("交易详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 新增编辑按钮
                ToolbarItem(placement: .primaryAction) {
                    Button("编辑") {
                        showEditView = true
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            // 新增 sheet
            .sheet(isPresented: $showEditView) {
                EditTransactionView(originalTransaction: transaction)
                    .environmentObject(DataManager.shared)
            }
        }
    }
}
```

### 4. 删除确认弹窗（顺便优化）

```swift
// TransactionListView.swift

@State private var transactionToDelete: Transaction?
@State private var showDeleteAlert = false

// 修改滑动操作
.swipeActions(edge: .trailing, allowsFullSwipe: false) {
    Button(role: .destructive) {
        transactionToDelete = transaction
        showDeleteAlert = true
    } label: {
        Label("删除", systemImage: "trash")
    }
}

// 添加 Alert
.alert("确认删除", isPresented: $showDeleteAlert) {
    Button("取消", role: .cancel) {
        transactionToDelete = nil
    }
    Button("删除", role: .destructive) {
        if let transaction = transactionToDelete {
            deleteTransaction(transaction)
            transactionToDelete = nil
        }
    }
} message: {
    Text("确定要删除这条交易记录吗？此操作无法撤销。")
}
```

---

## ✅ 验证和测试

### 手动测试清单

#### 1. 基本编辑功能
- [ ] 从交易详情页打开编辑页面
- [ ] 所有字段正确预填充
- [ ] 修改金额并保存，验证更新成功
- [ ] 修改商家并保存，验证更新成功
- [ ] 修改分类并保存，验证更新成功
- [ ] 修改类型（支出↔收入）并保存
- [ ] 修改日期并保存
- [ ] 修改备注并保存

#### 2. 表单验证
- [ ] 金额设为 0，保存按钮应禁用
- [ ] 金额设为负数，保存按钮应禁用
- [ ] 商家名称清空，保存按钮应禁用
- [ ] 金额输入非数字，应显示错误

#### 3. 分类学习
- [ ] 将"星巴克"从"其他"改为"餐饮"
- [ ] 手动添加新交易"星巴克"，验证自动分类为"餐饮"

#### 4. 数据同步
- [ ] 编辑后返回列表，验证列表自动刷新
- [ ] 编辑后返回详情页，验证详情数据更新

#### 5. 错误处理
- [ ] 网络断开时编辑（如果涉及）
- [ ] 数据库保存失败时的提示

#### 6. UI/UX
- [ ] 编辑成功后有触觉反馈
- [ ] 加载状态显示正确
- [ ] 取消编辑时数据未改变

---

## 🐛 已知风险和注意事项

### 1. SwiftData 更新问题
**风险**: SwiftData 的对象是引用类型，直接修改属性可能不触发更新

**解决方案**:
- 使用 `modelContext.save()` 显式保存
- 发送 NotificationCenter 通知刷新 UI

### 2. 日期选择未来时间
**风险**: 用户可能选择未来日期

**解决方案**:
```swift
DatePicker(
    "交易时间",
    selection: $date,
    in: ...Date(),  // 限制最大日期为当前
    displayedComponents: [.date, .hourAndMinute]
)
```

### 3. 并发编辑冲突
**风险**: 如果支持多设备同步，可能有冲突

**当前方案**: v1.0 不支持多设备，暂不处理
**未来方案**: 使用 CloudKit 冲突解决策略

### 4. 性能问题
**风险**: 每次编辑都重新加载分类列表

**优化**:
- 分类列表缓存到 CategoryEngine
- 只在首次加载时查询数据库

---

## 📊 工作量估算

| 任务 | 预计时间 | 备注 |
|------|---------|------|
| 创建 EditTransactionView | 1.5h | 复用 AddTransactionView 逻辑 |
| 实现 DataManager.updateTransaction() | 0.5h | 简单更新逻辑 |
| 修改 TransactionDetailView | 0.5h | 添加按钮和 sheet |
| 分类学习集成 | 0.5h | 调用现有方法 |
| 删除确认弹窗 | 0.5h | 简单优化 |
| 测试和调试 | 0.5h | 手动测试 |
| **总计** | **4h** | |

---

## 🚀 实施步骤

### Step 1: 准备工作（5 分钟）
1. 创建新文件 `EditTransactionView.swift`
2. 复制 `AddTransactionView.swift` 的框架代码

### Step 2: 实现核心逻辑（1.5 小时）
1. 修改 EditTransactionView，添加 `originalTransaction` 属性
2. 实现 `initializeFields()` 方法
3. 修改 `saveTransaction()` 为 `updateTransaction()`
4. 调整导航标题为"编辑交易"

### Step 3: 实现数据更新（30 分钟）
1. 在 DataManager 添加 `updateTransaction()` 方法
2. 实现字段更新逻辑
3. 集成分类学习

### Step 4: 集成到 UI（30 分钟）
1. 修改 TransactionDetailView，添加编辑按钮
2. 添加 sheet 展示编辑页面
3. 测试页面跳转和数据传递

### Step 5: 优化和完善（1 小时）
1. 添加删除确认弹窗
2. 添加触觉反馈
3. 完善错误处理
4. 添加日期限制

### Step 6: 测试（30 分钟）
1. 运行所有手动测试清单
2. 修复发现的问题
3. 验证数据一致性

---

## 📝 验收标准

编辑功能被认为"完成"，需满足：

✅ **功能性**
- 用户可以从详情页打开编辑页面
- 用户可以修改所有字段并保存
- 修改后数据正确更新到数据库
- 列表自动刷新显示最新数据

✅ **数据完整性**
- 表单验证正确（金额>0，商家非空）
- 分类学习正确触发
- 数据库无脏数据

✅ **用户体验**
- 编辑成功有触觉反馈
- 错误提示清晰
- 删除有确认弹窗
- 加载状态显示正确

✅ **代码质量**
- 代码结构清晰
- 注释完整
- 无编译警告
- 遵循现有代码风格

---

**准备开始实施 ✅**
