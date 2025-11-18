# 贡献指南 Contributing Guide

感谢你考虑为无感记账项目做出贡献！

---

## 📋 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发流程](#开发流程)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [Pull Request 流程](#pull-request-流程)
- [测试要求](#测试要求)

---

## 🤝 行为准则

### 我们的承诺

为了营造一个开放和友好的环境，我们承诺：

- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

### 不可接受的行为

- 使用性化的语言或图像
- 人身攻击或侮辱性评论
- 公开或私下的骚扰
- 未经许可发布他人的私人信息

---

## 💡 如何贡献

### 报告 Bug

在报告 Bug 之前，请：

1. **检查现有 Issues** - 确保 Bug 未被报告过
2. **确定复现步骤** - 提供详细的复现步骤
3. **提供环境信息** - iOS 版本、设备型号等

**Bug 报告模板:**

```markdown
### 问题描述
简要描述遇到的问题

### 复现步骤
1. 进入 '...'
2. 点击 '...'
3. 滚动到 '...'
4. 看到错误

### 预期行为
描述你期望发生什么

### 实际行为
描述实际发生了什么

### 环境信息
- iOS 版本: [e.g. 17.2]
- 设备: [e.g. iPhone 15 Pro]
- App 版本: [e.g. 1.0.0]

### 截图
如果适用，添加截图帮助解释问题

### 额外信息
其他相关信息
```

### 提出新功能

**功能建议模板:**

```markdown
### 功能描述
简要描述建议的功能

### 使用场景
描述此功能解决的问题或使用场景

### 建议的实现方式
如果有想法，描述可能的实现方式

### 替代方案
描述考虑过的替代方案

### 额外信息
其他相关信息或参考资料
```

---

## 🔧 开发流程

### 1. Fork 和 Clone

```bash
# Fork 仓库到你的账号
# 然后克隆到本地
git clone https://github.com/YOUR_USERNAME/Record-Money.git
cd Record-Money

# 添加上游仓库
git remote add upstream https://github.com/XiaoLinZzz/Record-Money.git
```

### 2. 创建分支

```bash
# 确保从最新的 main 分支创建
git checkout main
git pull upstream main

# 创建功能分支
git checkout -b feature/your-feature-name

# 或修复分支
git checkout -b fix/bug-description
```

**分支命名规范:**

- `feature/xxx` - 新功能
- `fix/xxx` - Bug 修复
- `docs/xxx` - 文档更新
- `refactor/xxx` - 代码重构
- `test/xxx` - 测试相关
- `chore/xxx` - 构建/工具相关

### 3. 开发环境设置

```bash
# 打开项目
open AutoBookkeeping.xcodeproj

# 或使用 Xcode
```

**必要配置:**

1. **App Group**: 配置 `group.com.yourteam.autobookkeeping`
2. **Signing**: 设置开发者签名
3. **Target iOS**: 确保最低支持 iOS 16.0

### 4. 进行开发

- 遵循代码规范（见下文）
- 编写清晰的注释
- 添加必要的测试
- 保持提交原子化

### 5. 提交更改

```bash
# 添加更改
git add .

# 提交（遵循提交规范）
git commit -m "feat: add auto-classification feature"

# 推送到你的 fork
git push origin feature/your-feature-name
```

---

## 📝 代码规范

### Swift 代码风格

遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

#### 命名规范

```swift
// ✅ 好的命名
class TransactionManager { }
var transactionCount: Int
func fetchTransactions() -> [Transaction]

// ❌ 不好的命名
class TM { }
var cnt: Int
func getTrans() -> [Transaction]
```

#### 缩进和格式

- 使用 **4 个空格** 缩进（不使用 Tab）
- 每行最多 **120 个字符**
- 大括号开头在同一行

```swift
// ✅ 正确
func calculateTotal(transactions: [Transaction]) -> Double {
    return transactions.reduce(0) { $0 + $1.amount }
}

// ❌ 错误
func calculateTotal(transactions: [Transaction]) -> Double
{
    return transactions.reduce(0) { $0 + $1.amount }
}
```

#### 注释规范

```swift
/// 计算指定时间范围内的总支出
///
/// - Parameters:
///   - startDate: 开始日期
///   - endDate: 结束日期
/// - Returns: 总支出金额
/// - Throws: 如果数据库访问失败，抛出 DataError
func calculateExpense(from startDate: Date, to endDate: Date) throws -> Double {
    // 实现逻辑
}
```

#### MARK 使用

```swift
class TransactionListViewModel: ObservableObject {

    // MARK: - Properties

    @Published var transactions: [Transaction] = []

    // MARK: - Lifecycle

    init() {
        loadTransactions()
    }

    // MARK: - Public Methods

    func addTransaction(_ transaction: Transaction) {
        // ...
    }

    // MARK: - Private Methods

    private func loadTransactions() {
        // ...
    }
}
```

### SwiftUI 视图规范

```swift
struct TransactionRow: View {
    // MARK: - Properties

    let transaction: Transaction
    @State private var isExpanded = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            if isExpanded {
                detailView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Text(transaction.merchant)
                .font(.headline)
            Spacer()
            Text(transaction.formattedAmount)
                .font(.title3.bold())
        }
    }

    private var detailView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transaction.category.name)
            Text(transaction.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### 文件组织

```
每个文件应该：
1. 只包含一个主要类型（类/结构体/枚举）
2. 相关的扩展可以在同一文件
3. 文件名与类型名一致
```

**示例:**

```
Transaction.swift          // Transaction 模型定义
Transaction+Extensions.swift  // Transaction 的扩展
TransactionListView.swift  // 交易列表视图
```

---

## 📋 提交规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)

### 提交格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构（既不是新功能也不是修复）
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动
- `ci`: CI 配置文件和脚本的变动
- `revert`: 回滚之前的提交

### Scope 范围（可选）

- `models`: 数据模型
- `views`: 视图层
- `intents`: App Intents
- `services`: 业务逻辑
- `ui`: UI 组件
- `database`: 数据库
- `notification`: 通知

### 示例

```bash
# 新功能
git commit -m "feat(intents): add quick expense intent for Siri"

# Bug 修复
git commit -m "fix(database): resolve transaction duplicate issue"

# 文档
git commit -m "docs: update installation guide in README"

# 重构
git commit -m "refactor(services): simplify category matching logic"

# 性能优化
git commit -m "perf(views): optimize transaction list rendering"
```

**详细提交示例:**

```bash
git commit -m "feat(intents): add quick expense intent for Siri

- Implement QuickExpenseIntent with natural language parsing
- Add unit tests for NaturalLanguageParser
- Update documentation with Siri integration guide

Closes #42"
```

---

## 🔀 Pull Request 流程

### 1. 创建 PR 前的检查清单

- [ ] 代码遵循项目的代码规范
- [ ] 所有测试通过
- [ ] 添加了必要的新测试
- [ ] 更新了相关文档
- [ ] 提交信息遵循规范
- [ ] 代码已经自我 Review

### 2. PR 标题规范

遵循提交信息规范：

```
feat: add CoreML category classification
fix: resolve memory leak in DataManager
docs: update API documentation
```

### 3. PR 描述模板

```markdown
## 变更类型
- [ ] Bug 修复
- [ ] 新功能
- [ ] 重大变更
- [ ] 文档更新

## 变更描述
简要描述此 PR 的目的和内容

## 相关 Issue
Closes #issue_number

## 测试
描述你如何测试了这些变更
- [ ] 单元测试
- [ ] UI 测试
- [ ] 手动测试

## 截图（如适用）
添加相关截图

## 检查清单
- [ ] 我的代码遵循项目的代码规范
- [ ] 我已经进行了自我代码审查
- [ ] 我已经注释了代码，特别是在难以理解的地方
- [ ] 我已经更新了相关文档
- [ ] 我的更改没有产生新的警告
- [ ] 我已经添加了证明我的修复有效或功能正常的测试
- [ ] 所有新的和现有的单元测试都通过了
```

### 4. Code Review 流程

**作为 PR 作者:**

1. 创建 PR 后，确保 CI 通过
2. 回应所有 Review 评论
3. 根据反馈进行修改
4. 标记已解决的对话

**作为 Reviewer:**

1. 检查代码质量和规范
2. 运行代码并测试
3. 提供建设性的反馈
4. 批准或请求更改

### 5. 合并策略

- 使用 **Squash and Merge** 保持历史清晰
- 确保合并后的提交信息有意义
- 删除已合并的分支

---

## 🧪 测试要求

### 单元测试

所有核心业务逻辑必须有单元测试：

```swift
import XCTest
@testable import AutoBookkeeping

class CategoryEngineTests: XCTestCase {

    var sut: CategoryEngine!

    override func setUp() {
        super.setUp()
        sut = CategoryEngine.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInferCategory_ForStarbucks_ReturnsDining() async {
        // Given
        let merchant = "星巴克"

        // When
        let category = await sut.inferCategory(merchant: merchant, rawText: nil)

        // Then
        XCTAssertEqual(category.name, "餐饮")
    }
}
```

### UI 测试

关键用户流程需要 UI 测试：

```swift
import XCTest

class OnboardingUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }

    func testOnboardingFlow() {
        // Test the complete onboarding flow
        XCTAssertTrue(app.staticTexts["欢迎使用无感记账"].exists)

        app.buttons["下一步"].tap()
        // ... more steps
    }
}
```

### 测试覆盖率

- 核心业务逻辑: **80%+**
- UI 视图: **60%+**
- 整体覆盖率: **70%+**

### 运行测试

```bash
# 运行所有测试
xcodebuild test -scheme AutoBookkeeping -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# 或在 Xcode 中
Cmd + U
```

---

## 📚 开发资源

### 官方文档

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [App Intents Framework](https://developer.apple.com/documentation/appintents)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)

### 推荐阅读

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Clean Code in Swift](https://github.com/topics/clean-code-swift)

### 工具推荐

- [SwiftLint](https://github.com/realm/SwiftLint) - Swift 代码检查
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) - 代码格式化

---

## ❓ 常见问题

### Q: 如何同步上游更新？

```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

### Q: 如何解决合并冲突？

```bash
# 拉取最新代码
git pull upstream main

# 解决冲突后
git add .
git commit -m "chore: resolve merge conflicts"
git push origin your-branch
```

### Q: PR 被拒绝了怎么办？

- 仔细阅读 Review 意见
- 进行相应修改
- 推送更新到同一分支
- PR 会自动更新

---

## 💬 联系方式

如有任何问题，欢迎通过以下方式联系：

- **GitHub Issues**: 技术问题和 Bug 报告
- **Discussions**: 一般性讨论和问答
- **Email**: your-email@example.com

---

## 🎉 致谢

感谢所有为这个项目做出贡献的开发者！

你的每一次贡献都让这个项目变得更好！

---

**Happy Coding! 🚀**
