# 快速开始 Quick Start Guide

本指南帮助你快速上手无感记账 App 的开发。

---

## 🚀 5 分钟快速启动

### 前置要求

确保你的开发环境满足：

- ✅ macOS Sonoma 14.0+
- ✅ Xcode 15.0+
- ✅ Apple Developer Account (用于真机测试)
- ✅ iOS 16.0+ 设备或模拟器

### Step 1: 克隆项目

```bash
git clone https://github.com/XiaoLinZzz/Record-Money.git
cd Record-Money
```

### Step 2: 打开项目

```bash
# 使用 Xcode 打开项目
open AutoBookkeeping.xcodeproj

# 或直接双击 AutoBookkeeping.xcodeproj
```

### Step 3: 配置签名

1. 在 Xcode 中选择项目
2. 选择 `AutoBookkeeping` Target
3. 进入 `Signing & Capabilities`
4. 选择你的开发团队
5. 修改 Bundle Identifier (如: `com.yourteam.autobookkeeping`)

### Step 4: 配置 App Group

1. 点击 `+ Capability`
2. 添加 `App Groups`
3. 创建新的 App Group: `group.com.yourteam.autobookkeeping`
4. 在代码中更新 App Group 标识符:

```swift
// DataManager.swift
private let sharedContainer = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.yourteam.autobookkeeping"
)!
```

### Step 5: 运行项目

1. 选择目标设备 (推荐 iPhone 15 Pro)
2. 按 `Cmd + R` 运行
3. 首次运行会看到引导页面

---

## 📱 功能测试

### 测试自动记账

由于模拟器限制，自动记账功能需要真机测试：

#### 在真机上测试

1. **安装 App 到真机**
   ```bash
   # 连接 iPhone
   # 在 Xcode 中选择你的设备
   # Cmd + R 运行
   ```

2. **完成 App 内引导**
   - 打开 App
   - 跟随引导完成设置
   - 安装快捷指令

3. **配置快捷指令**
   - 打开"快捷指令" App
   - 创建自动化（详见下文）

4. **测试记账**
   - 进行一次小额支付（如 0.01 元转账）
   - 查看是否自动创建了交易记录

#### 快捷指令配置示例

```
自动化名称: 微信支付自动记账

触发条件:
  - App: 微信
  - 事件: 已打开

操作:
  1. 等待 1 秒
  2. 对屏幕截图
  3. 从图像获取文本
  4. 运行快捷指令 "解析支付信息"
  5. 运行 App Intent "添加交易记录"
     - 金额: [从文本提取]
     - 商家: [从文本提取]
     - 类型: 支出
     - 支付方式: 微信支付
```

### 测试手动记账

1. 在 App 中点击 "+" 按钮
2. 输入交易信息
3. 保存
4. 查看交易列表

### 测试 Siri 集成

1. 对 Siri 说: "嘿 Siri，用无感记账记 30 元咖啡"
2. Siri 会调用 App 并显示结果
3. 检查 App 中是否有新记录

---

## 🛠 开发工作流

### 创建新功能

```bash
# 1. 创建功能分支
git checkout -b feature/new-awesome-feature

# 2. 进行开发
# 编写代码、测试、文档

# 3. 运行测试
xcodebuild test -scheme AutoBookkeeping

# 4. 提交代码
git add .
git commit -m "feat: add new awesome feature"

# 5. 推送并创建 PR
git push origin feature/new-awesome-feature
```

### 代码规范检查

```bash
# 安装 SwiftLint (可选)
brew install swiftlint

# 运行检查
swiftlint
```

### 运行测试

```bash
# 运行所有测试
xcodebuild test -scheme AutoBookkeeping -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# 或在 Xcode 中
# Cmd + U
```

---

## 🗂 项目结构导航

### 主要目录

```
AutoBookkeeping/
├── App/                    # App 入口和配置
│   └── AutoBookkeepingApp.swift
├── Models/                 # 数据模型
│   ├── Transaction.swift
│   ├── Category.swift
│   └── Budget.swift
├── Views/                  # UI 视图
│   ├── Onboarding/        # 引导页
│   ├── Transaction/       # 交易相关
│   ├── Statistics/        # 统计
│   └── Settings/          # 设置
├── Intents/               # App Intents
│   ├── AddTransactionIntent.swift
│   └── QuickExpenseIntent.swift
├── Services/              # 业务逻辑
│   ├── CategoryEngine.swift
│   ├── DataManager.swift
│   └── NotificationManager.swift
└── Resources/             # 资源文件
```

### 如何找到代码

| 功能 | 位置 |
|-----|------|
| 添加新的交易类型 | `Models/Transaction.swift` |
| 修改分类规则 | `Services/CategoryEngine.swift` |
| 调整 UI 样式 | `Views/` 目录 |
| 添加新的 Intent | `Intents/` 目录 |
| 数据库操作 | `Services/DataManager.swift` |

---

## 🐛 常见问题

### Q1: Xcode 报错 "No such module 'SwiftData'"

**解决方案**:
- 确保 Deployment Target 设置为 iOS 17.0+
- 或者使用 Core Data 替代 SwiftData

### Q2: App Group 配置失败

**解决方案**:
```bash
# 1. 确保 Bundle ID 唯一
# 2. 在 Developer Portal 中创建 App Group
# 3. 重新下载 Provisioning Profile
```

### Q3: Intent 无法调用

**解决方案**:
- 检查 `openAppWhenRun` 设置
- 确认 App Group 配置正确
- 重新安装 App

### Q4: 真机测试时签名失败

**解决方案**:
```
1. Settings → General → Device Management
2. 信任开发者证书
3. 重新运行 App
```

---

## 📚 学习资源

### 官方文档

- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [App Intents](https://developer.apple.com/documentation/appintents)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)

### 推荐阅读

- [技术方案详解](TECHNICAL_SPEC.md)
- [架构设计](ARCHITECTURE.md)
- [API 文档](API.md)
- [贡献指南](../CONTRIBUTING.md)

### 视频教程

- [WWDC 2023: Meet App Intents](https://developer.apple.com/videos/play/wwdc2023/10032/)
- [WWDC 2023: Meet SwiftData](https://developer.apple.com/videos/play/wwdc2023/10187/)

---

## 🎯 下一步

现在你已经成功运行了项目，可以：

1. **探索代码库** - 熟悉项目结构
2. **阅读技术文档** - 理解架构设计
3. **尝试修改** - 添加新功能或修复 Bug
4. **参与贡献** - 提交 PR 或报告问题

---

## 💬 获取帮助

如果遇到问题:

1. **查看文档**: 先检查 `docs/` 目录
2. **搜索 Issues**: 可能已有解决方案
3. **提问**: 创建新的 Issue
4. **联系**: your-email@example.com

---

**祝你开发愉快! 🚀**

*最后更新: 2024-11-18*
