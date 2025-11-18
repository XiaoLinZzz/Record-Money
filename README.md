# 💰 无感记账 - AutoBookkeeping

> 一款基于 App Intents + 快捷指令的智能记账应用

[![Platform](https://img.shields.io/badge/platform-iOS%2016.0%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 📱 项目简介

**无感记账** 是一款真正实现"无感"体验的记账应用。通过深度集成 iOS 系统特性（App Intents + 快捷指令），用户完成支付后无需任何操作，系统自动完成记账。

### ✨ 核心特性

- 🚀 **无感记账**: 支付完成 → 自动记录，零操作
- 🤖 **智能分类**: AI 自动推断消费类型
- 🔒 **隐私安全**: 所有处理在本地完成，不上传任何数据
- 📊 **数据洞察**: 清晰了解消费习惯
- 🔄 **iCloud 同步**: 多设备数据同步（可选）

### 🎯 工作流程

```
用户支付(微信/支付宝)
    ↓
iOS 系统通知触发
    ↓
快捷指令自动运行
    ↓
OCR 提取屏幕信息
    ↓
调用 App Intent
    ↓
智能分类 + 存储
    ↓
推送确认通知
```

---

## 🚀 Quick Start

### 环境要求

- **Xcode**: 15.0+
- **iOS**: 16.0+ (推荐 17.0+)
- **Swift**: 5.9+
- **macOS**: Sonoma 14.0+

### 快速开始

1. **克隆项目**

```bash
git clone https://github.com/XiaoLinZzz/Record-Money.git
cd Record-Money
```

2. **打开项目**

```bash
open AutoBookkeeping.xcodeproj
```

或使用 Xcode 直接打开 `AutoBookkeeping.xcodeproj`

3. **配置 App Group**

在 Xcode 中：
- 选择 Target → Signing & Capabilities
- 添加 App Groups capability
- 创建或选择 App Group: `group.com.yourteam.autobookkeeping`

4. **运行项目**

- 选择模拟器或真机
- 按 `Cmd + R` 运行

### 首次使用

1. 启动 App 并完成引导流程
2. 安装自动化快捷指令（仅需一次）
3. 进行一次小额支付测试
4. 查看自动记账结果

---

## 📂 项目结构

```
Record-Money/
├── AutoBookkeeping/              # 主应用
│   ├── App/                      # App 入口
│   ├── Models/                   # 数据模型
│   │   ├── Transaction.swift     # 交易记录
│   │   ├── Category.swift        # 分类
│   │   └── Budget.swift          # 预算
│   ├── Views/                    # 界面
│   │   ├── Onboarding/          # 引导页
│   │   ├── Transaction/         # 交易列表
│   │   ├── Statistics/          # 统计分析
│   │   └── Settings/            # 设置
│   ├── Intents/                 # App Intents
│   │   ├── AddTransactionIntent.swift
│   │   └── QuickExpenseIntent.swift
│   ├── Services/                # 业务逻辑
│   │   ├── CategoryEngine.swift  # 智能分类引擎
│   │   ├── DataManager.swift     # 数据管理
│   │   └── NotificationManager.swift
│   └── Resources/               # 资源文件
├── Widgets/                     # Widget 扩展
├── Tests/                       # 测试
│   ├── UnitTests/
│   └── UITests/
├── docs/                        # 文档
│   ├── TECHNICAL_SPEC.md        # 技术方案
│   ├── API.md                   # API 文档
│   └── ARCHITECTURE.md          # 架构设计
├── README.md
├── CONTRIBUTING.md
└── CHANGELOG.md
```

---

## 🛠 技术栈

| 模块 | 技术方案 | 说明 |
|------|---------|------|
| UI 框架 | SwiftUI | 现代化声明式 UI |
| 数据持久化 | SwiftData | iOS 17+ 原生方案 |
| 自动化触发 | App Intents | 系统级集成 |
| 智能分类 | 规则引擎 → CoreML | 渐进式升级 |
| 数据同步 | iCloud CloudKit | 多设备同步 |
| 通知 | UserNotifications | 系统原生通知 |
| 机器学习 | Create ML + CoreML | AI 分类 |

---

## 📋 功能清单

### MVP 功能 (v1.0)

- [x] 自动记账（基于 App Intents + 快捷指令）
- [x] 智能分类（规则引擎）
- [x] 交易列表与详情
- [x] 基础数据统计
- [x] 用户引导流程
- [x] 本地数据存储
- [x] 通知反馈

### 进阶功能 (v1.5)

- [ ] 多账本管理
- [ ] 预算管理
- [ ] 数据可视化（图表）
- [ ] 导出功能（CSV/Excel）
- [ ] Widget 小组件
- [ ] iCloud 同步

### 高级功能 (v2.0)

- [ ] CoreML 智能分类
- [ ] AI 对话式记账
- [ ] OCR 小票扫描
- [ ] 消费趋势预警
- [ ] Siri 语音记账
- [ ] Control Center 控件

---

## 🧪 测试

### 运行单元测试

```bash
# 命令行
xcodebuild test -scheme AutoBookkeeping -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# 或在 Xcode 中
Cmd + U
```

### 运行 UI 测试

```bash
xcodebuild test -scheme AutoBookkeeping -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AutoBookkeepingUITests
```

---

## 📖 文档

- [技术方案详解](docs/TECHNICAL_SPEC.md) - 完整技术实现方案
- [架构设计](docs/ARCHITECTURE.md) - 系统架构与设计模式
- [API 文档](docs/API.md) - App Intents 接口文档
- [开发规范](CONTRIBUTING.md) - 代码规范与贡献指南

---

## 🤝 贡献指南

欢迎贡献代码、报告 Bug 或提出新功能建议！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

详细信息请查看 [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 👨‍💻 作者

**Lujie**

- GitHub: [@XiaoLinZzz](https://github.com/XiaoLinZzz)
- Email: your-email@example.com

---

## 🙏 致谢

- [Apple SwiftUI Framework](https://developer.apple.com/xcode/swiftui/)
- [App Intents Documentation](https://developer.apple.com/documentation/appintents)
- 所有贡献者和用户

---

## ⭐ Star History

如果这个项目对你有帮助，请给个 Star ⭐️

[![Star History Chart](https://api.star-history.com/svg?repos=XiaoLinZzz/Record-Money&type=Date)](https://star-history.com/#XiaoLinZzz/Record-Money&Date)

---

**Made with ❤️ by Lujie**
