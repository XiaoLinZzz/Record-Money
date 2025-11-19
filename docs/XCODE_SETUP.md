# 📱 Xcode 项目自动化配置指南

本文档详细说明如何使用自动化脚本快速配置 AutoBookkeeping Xcode 项目。

## 📋 目录

- [快速开始](#快速开始)
- [详细说明](#详细说明)
- [自定义配置](#自定义配置)
- [常见问题](#常见问题)
- [高级用法](#高级用法)

---

## 🚀 快速开始

### 环境要求

- **macOS**: 14.0+ (Sonoma)
- **Xcode**: 15.0+
- **iOS 部署目标**: 17.0+

### 一键配置（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/XiaoLinZzz/Record-Money.git
cd Record-Money

# 2. 运行自动配置脚本
./setup-xcode-project.sh

# 3. 按照提示操作（会自动安装必要工具）
```

脚本会自动完成：
- ✅ 检查并安装 Homebrew（如果需要）
- ✅ 检查并安装 xcodegen（如果需要）
- ✅ 生成完整的 Xcode 项目文件
- ✅ 配置所有必要的权限和功能

---

## 📖 详细说明

### 步骤 1：运行配置脚本

```bash
./setup-xcode-project.sh
```

脚本执行流程：

1. **环境检查**
   - 检测是否在 macOS 上运行
   - 检查 Xcode 是否已安装
   - 验证项目文件结构

2. **工具检查**
   - 检测 Homebrew（macOS 包管理器）
   - 检测 xcodegen（项目生成工具）
   - 如未安装，会提示是否自动安装

3. **项目生成**
   - 读取 `project.yml` 配置文件
   - 使用 xcodegen 生成 `.xcodeproj` 文件
   - 自动备份旧项目（如果存在）

4. **完成提示**
   - 显示下一步操作说明
   - 提供常见问题解决方案

### 步骤 2：打开项目

```bash
# 方式 1：命令行打开
open AutoBookkeeping.xcodeproj

# 方式 2：双击文件
# 在 Finder 中找到 AutoBookkeeping.xcodeproj 双击打开
```

### 步骤 3：配置签名（⚠️ 必须手动完成）

这是**唯一需要手动配置**的步骤：

1. 在 Xcode 中选择项目 `AutoBookkeeping`
2. 选择 TARGETS → `AutoBookkeeping`
3. 进入 `Signing & Capabilities` 标签页
4. **Team**: 选择你的 Apple Developer 账号
   - 如果没有账号，选择 `None`（仅能在模拟器运行）
   - 如果要在真机上运行，需要添加 Apple ID
5. 对 `BookkeepingWidget` target 重复步骤 2-4

> 💡 **提示**: 如果看到 "Failed to register bundle identifier" 错误，这是正常的。你需要修改 Bundle ID（见下方自定义配置）。

### 步骤 4：运行项目

1. 在 Xcode 顶部工具栏选择目标设备：
   - **模拟器**（推荐）：iPhone 15 Pro
   - **真机**：需要先配置签名

2. 点击运行按钮 ▶️ 或按 `⌘+R`

3. 等待编译完成（首次需要 5-10 分钟）

---

## 🔧 自定义配置

### 修改 Bundle ID

如果默认的 Bundle ID (`com.yourcompany.autobookkeeping`) 已被占用：

1. 编辑 `project.yml` 文件：

```yaml
options:
  bundleIdPrefix: com.yourcompany  # 修改这里
```

改为你自己的标识符，例如：

```yaml
options:
  bundleIdPrefix: com.xiaolin  # 使用你自己的
```

2. 重新运行配置脚本：

```bash
./setup-xcode-project.sh
```

3. 项目会自动重新生成，新的 Bundle ID 会是：
   - 主应用：`com.xiaolin.autobookkeeping`
   - Widget：`com.xiaolin.autobookkeeping.widget`

### 修改部署目标

如果需要支持更低版本的 iOS：

编辑 `project.yml`：

```yaml
options:
  deploymentTarget:
    iOS: "16.0"  # 改为 16.0 或更高版本
```

然后重新运行脚本。

### 修改项目名称

编辑 `project.yml`：

```yaml
name: AutoBookkeeping  # 修改项目名称
```

### 添加新的源文件目录

如果添加了新的文件夹，需要在 `project.yml` 中声明：

```yaml
targets:
  AutoBookkeeping:
    sources:
      - path: AutoBookkeeping
      - path: YourNewFolder  # 添加新文件夹
```

---

## ❓ 常见问题

### Q1: 脚本提示 "permission denied"

```bash
# 解决方法：添加执行权限
chmod +x setup-xcode-project.sh
./setup-xcode-project.sh
```

### Q2: 编译时出现 "No such module 'SwiftData'" 错误

**原因**: iOS 部署目标版本过低

**解决方法**:
1. 确保 Xcode 版本 >= 15.0
2. 确保 iOS 部署目标 >= 17.0
3. 检查 `project.yml` 中的 `deploymentTarget` 设置

### Q3: "Failed to register bundle identifier" 错误

**原因**: Bundle ID 已被其他项目使用

**解决方法**: 修改 Bundle ID（参考上方"自定义配置"）

### Q4: Widget 扩展编译失败

**原因**: 可能未正确配置 App Group

**解决方法**:
1. 确保主应用和 Widget 都配置了相同的 App Group
2. 检查 `AutoBookkeeping.entitlements` 和 `BookkeepingWidget.entitlements` 文件
3. 确保 App Group ID 一致：`group.com.yourcompany.autobookkeeping`

### Q5: 模拟器可以运行但真机不行

**原因**: 需要有效的开发者证书

**解决方法**:
1. 在 Apple Developer 网站注册你的设备
2. 在 Xcode 中登录你的 Apple ID
3. 选择正确的 Team 和 Provisioning Profile

### Q6: xcodegen 安装失败

**原因**: 网络问题或 Homebrew 配置问题

**解决方法**:

```bash
# 更新 Homebrew
brew update

# 手动安装 xcodegen
brew install xcodegen

# 如果还是失败，尝试清理缓存
brew cleanup
brew install xcodegen
```

### Q7: 需要重新生成项目吗？

以下情况需要重新运行脚本：
- ✅ 修改了 `project.yml` 配置文件
- ✅ 添加或删除了文件夹
- ✅ 修改了 Bundle ID
- ❌ 只是添加或删除单个文件（不需要）
- ❌ 修改了代码内容（不需要）

---

## 🔬 高级用法

### 完全自动安装模式

如果想跳过所有确认提示，直接安装所有依赖：

```bash
./setup-xcode-project.sh --auto-install
```

### 仅生成项目（不安装工具）

如果已经安装了 xcodegen：

```bash
xcodegen generate
```

### 查看生成的项目结构

```bash
# 使用 xcodegen 的调试模式
xcodegen generate --use-cache --spec project.yml
```

### 自定义 xcodegen 配置

`project.yml` 文件支持大量自定义选项，完整文档：
https://github.com/yonaskolb/XcodeGen

常用配置示例：

```yaml
# 添加自定义 Build Settings
settings:
  base:
    SWIFT_VERSION: "5.9"
    ENABLE_BITCODE: NO

# 添加框架依赖
targets:
  AutoBookkeeping:
    dependencies:
      - framework: UIKit.framework
      - sdk: Foundation.framework
```

---

## 📚 相关文档

- [项目总览](../README.md)
- [快速开始指南](../README_QUICKSTART.md)
- [开发贡献指南](../CONTRIBUTING.md)
- [项目状态](../PROJECT_STATUS.md)

---

## 🆘 获取帮助

如果遇到本文档未涵盖的问题：

1. **查看错误日志**: Xcode → Product → Show Issue Navigator
2. **搜索错误信息**: 复制完整错误信息到 Google/Stack Overflow
3. **提交 Issue**: 在 GitHub 上创建新的 Issue，包含：
   - 完整的错误信息
   - Xcode 版本
   - macOS 版本
   - 重现步骤

---

## 🎉 总结

通过使用自动化配置脚本，你可以：

- ✅ **节省时间**: 从手动 30 分钟配置减少到 3 分钟自动化
- ✅ **减少错误**: 避免手动配置时的遗漏和错误
- ✅ **易于维护**: 配置统一在 `project.yml` 中管理
- ✅ **团队协作**: 新成员可以快速上手
- ✅ **版本控制**: 配置文件纳入 Git 版本管理

唯一需要手动配置的只有**签名设置**，这是 Apple 的安全要求。

**祝你开发愉快！** 🚀
