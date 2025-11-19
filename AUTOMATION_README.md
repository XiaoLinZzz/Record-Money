# 🤖 Xcode 项目自动化配置系统

## 📖 概述

本项目采用了先进的自动化配置系统，让 iOS 开发新手也能快速上手，无需手动配置繁琐的 Xcode 项目设置。

### ✨ 自动化特性

- ✅ **一键配置**: 运行一个脚本即可完成所有配置
- ✅ **智能检测**: 自动检测和安装必要的开发工具
- ✅ **零手动**: 除了签名外，其他配置全部自动化
- ✅ **团队协作**: 配置文件纳入版本控制，团队成员配置一致
- ✅ **易于维护**: 修改配置文件后重新运行即可更新

---

## 🚀 快速开始（3 步上手）

```bash
# 1. 克隆项目
git clone https://github.com/XiaoLinZzz/Record-Money.git
cd Record-Money

# 2. 运行自动配置脚本（会提示安装必要工具）
./setup-xcode-project.sh

# 3. 打开项目
open AutoBookkeeping.xcodeproj
```

**就这么简单！** 脚本会自动：
- 检查并安装 Homebrew
- 检查并安装 xcodegen
- 生成完整的 Xcode 项目
- 配置所有权限和功能

唯一需要你手动做的是：**在 Xcode 中选择开发团队（Team）进行签名**。

---

## 📦 自动化系统组成

### 1. `project.yml` - 项目配置文件

这是核心配置文件，定义了整个 Xcode 项目的结构：

```yaml
name: AutoBookkeeping
options:
  bundleIdPrefix: com.yourcompany  # 修改这里来改变 Bundle ID
  deploymentTarget:
    iOS: "17.0"  # iOS 最低版本要求

targets:
  AutoBookkeeping:  # 主应用
    type: application
    ...

  BookkeepingWidget:  # Widget 扩展
    type: app-extension
    ...
```

**优势**:
- 📝 人类可读的 YAML 格式
- 🔄 可以纳入版本控制
- 🛠 易于修改和维护
- 👥 团队成员配置一致

### 2. `setup-xcode-project.sh` - 自动化脚本

智能配置脚本，会帮你：

1. **环境检查**
   - 验证是否在 macOS 上运行
   - 检查 Xcode 是否已安装
   - 检测项目文件结构

2. **工具管理**
   - 检测 Homebrew（如未安装，提示安装）
   - 检测 xcodegen（如未安装，自动安装）

3. **项目生成**
   - 从 `project.yml` 生成 `.xcodeproj`
   - 自动备份旧项目文件（如果存在）
   - 配置所有 targets 和 capabilities

4. **友好提示**
   - 显示下一步操作指南
   - 提供常见问题解决方案

**使用方式**:

```bash
# 基本用法
./setup-xcode-project.sh

# 自动安装模式（跳过确认）
./setup-xcode-project.sh --auto-install
```

### 3. 配置文件

#### `AutoBookkeeping/Resources/Info.plist`
主应用的配置文件，包含：
- 应用信息（名称、版本等）
- 权限描述（相机、相册、Siri 等）
- App Intents 支持配置

#### `AutoBookkeeping/Resources/AutoBookkeeping.entitlements`
主应用的权限配置：
- App Groups（与 Widget 共享数据）
- Siri 支持
- Apple Sign In

#### `BookkeepingWidget/BookkeepingWidget.entitlements`
Widget 的权限配置：
- App Groups（与主应用共享数据）

---

## 🔧 自定义配置

### 修改 Bundle ID

编辑 `project.yml`:

```yaml
options:
  bundleIdPrefix: com.yourname  # 改成你自己的
```

重新运行脚本：

```bash
./setup-xcode-project.sh
```

### 修改 iOS 版本要求

编辑 `project.yml`:

```yaml
options:
  deploymentTarget:
    iOS: "16.0"  # 改为支持的最低版本
```

### 添加新的权限

编辑 `AutoBookkeeping/Resources/Info.plist`，添加权限描述。

编辑 `AutoBookkeeping/Resources/AutoBookkeeping.entitlements`，添加权限配置。

重新运行脚本生效。

---

## 🆚 对比：手动 vs 自动化

| 项目 | 手动配置 | 自动化配置 |
|------|----------|-----------|
| 创建项目 | 5 分钟 | 10 秒 |
| 添加文件 | 逐个拖拽 | 自动扫描 |
| 配置 Widget | 15 分钟 | 自动完成 |
| 配置权限 | 10 分钟 | 自动完成 |
| 配置 App Groups | 10 分钟 | 自动完成 |
| 配置 Intents | 5 分钟 | 自动完成 |
| **总耗时** | **45 分钟** | **3 分钟** |
| 错误风险 | 高 | 低 |
| 团队一致性 | 难 | 易 |

---

## 📚 详细文档

- **[完整配置指南](docs/XCODE_SETUP.md)** - 详细的配置说明和高级用法
- **[常见问题](docs/FAQ.md)** - 遇到问题？先看这里
- **[快速开始](README_QUICKSTART.md)** - 新手入门指南
- **[贡献指南](CONTRIBUTING.md)** - 如何参与项目开发

---

## 💡 工作原理

```
┌─────────────────┐
│  project.yml    │  配置文件（人类可读）
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   xcodegen      │  项目生成工具
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ .xcodeproj      │  Xcode 项目文件（机器生成）
└─────────────────┘
```

**为什么不直接提交 `.xcodeproj`？**

1. ✅ **可读性**: YAML 比 XML 更易读
2. ✅ **版本控制**: 合并冲突更容易解决
3. ✅ **灵活性**: 可以轻松自定义配置
4. ✅ **一致性**: 所有开发者使用相同的生成规则

---

## 🔄 工作流程

### 日常开发

```bash
# 1. 拉取最新代码
git pull

# 2. 如果 project.yml 有更新，重新生成项目
./setup-xcode-project.sh

# 3. 开始开发
open AutoBookkeeping.xcodeproj
```

### 修改配置

```bash
# 1. 编辑 project.yml
vim project.yml

# 2. 重新生成项目
./setup-xcode-project.sh

# 3. 提交更改（只提交 project.yml）
git add project.yml
git commit -m "Update project configuration"
git push
```

### 添加新文件

**在现有文件夹中添加文件**:
- ✅ 直接在 Xcode 中添加，无需重新生成

**添加新文件夹**:
1. 创建文件夹并添加文件
2. 更新 `project.yml`（如果需要）
3. 运行 `./setup-xcode-project.sh`

---

## 🛠 依赖工具

### Homebrew
**作用**: macOS 包管理器
**官网**: https://brew.sh
**安装**: 脚本会自动提示安装

### xcodegen
**作用**: 从 YAML 生成 Xcode 项目
**官网**: https://github.com/yonaskolb/XcodeGen
**安装**: 脚本会自动安装

---

## ❓ 常见问题

### Q: 为什么还需要手动配置签名？

**A**: Apple 的安全要求。签名涉及你的 Apple ID 和证书，无法通过脚本自动配置。但这只需要点几下鼠标。

### Q: 修改代码后需要重新运行脚本吗？

**A**: 不需要。只有以下情况需要：
- 修改了 `project.yml`
- 添加了新的文件夹
- 修改了权限配置

### Q: 如何回到手动配置？

**A**: 如果你不想使用自动化：
1. 在 Xcode 中创建新项目
2. 手动添加源文件
3. 参考 `project.yml` 进行配置

但我们强烈推荐使用自动化系统。

### Q: 团队成员是否都需要运行脚本？

**A**: 是的。每个人在克隆项目后都需要运行一次 `./setup-xcode-project.sh` 来生成本地的 `.xcodeproj` 文件。

---

## 🎯 最佳实践

1. **首次克隆项目**: 立即运行 `./setup-xcode-project.sh`
2. **拉取更新后**: 检查是否有 `project.yml` 更新，如有则重新运行脚本
3. **修改配置**: 只修改 `project.yml`，不要手动编辑 `.xcodeproj`
4. **提交代码**: 不要提交 `.xcodeproj`（已在 `.gitignore` 中）
5. **新成员入职**: 给他们看这个文档，3 分钟上手

---

## 🙏 致谢

本自动化系统基于以下开源工具：

- [xcodegen](https://github.com/yonaskolb/XcodeGen) - Xcode 项目生成工具
- [Homebrew](https://brew.sh) - macOS 包管理器

---

## 📞 获取帮助

- 📖 [详细文档](docs/XCODE_SETUP.md)
- ❓ [常见问题](docs/FAQ.md)
- 🐛 [报告问题](https://github.com/XiaoLinZzz/Record-Money/issues)

---

**享受自动化带来的便利，专注于代码开发！** 🚀
