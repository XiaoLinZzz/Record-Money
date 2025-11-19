# ❓ 常见问题解答 (FAQ)

## 📋 目录

- [安装与配置](#安装与配置)
- [编译与运行](#编译与运行)
- [功能使用](#功能使用)
- [错误排查](#错误排查)

---

## 🛠 安装与配置

### Q: 我是新手，应该如何开始？

**A**: 非常简单！只需要三步：

```bash
# 1. 克隆项目
git clone https://github.com/XiaoLinZzz/Record-Money.git
cd Record-Money

# 2. 运行自动配置脚本
./setup-xcode-project.sh

# 3. 打开项目并运行
open AutoBookkeeping.xcodeproj
```

脚本会自动帮你配置好一切，你只需要在 Xcode 中选择 Team 签名即可。

---

### Q: 脚本运行时显示 "permission denied"？

**A**: 需要给脚本添加执行权限：

```bash
chmod +x setup-xcode-project.sh
./setup-xcode-project.sh
```

---

### Q: 需要安装哪些工具？

**A**: 脚本会自动帮你安装所需工具：

- **Xcode** (15.0+): 从 App Store 安装
- **Homebrew**: 脚本会自动安装
- **xcodegen**: 脚本会自动安装

你只需要先安装 Xcode，其他工具脚本会自动处理。

---

### Q: Bundle ID 冲突怎么办？

**A**: 编辑 `project.yml` 文件，修改 Bundle ID 前缀：

```yaml
options:
  bundleIdPrefix: com.yourname  # 改成你自己的
```

然后重新运行脚本：

```bash
./setup-xcode-project.sh
```

---

### Q: 如何在真机上运行？

**A**: 需要配置签名：

1. 在 Xcode 中选择项目
2. 选择 TARGETS → AutoBookkeeping
3. 进入 Signing & Capabilities
4. Team: 选择你的 Apple ID
5. 对 BookkeepingWidget 重复以上步骤
6. 连接 iPhone 并在顶部选择设备
7. 点击运行 ▶️

如果是第一次在设备上运行，需要在 iPhone 上信任你的开发者证书：
`设置 → 通用 → VPN与设备管理 → 开发者App → 信任`

---

## 🏗 编译与运行

### Q: 编译时间太长怎么办？

**A**: 首次编译需要 5-10 分钟是正常的。后续编译会快很多（1-2 分钟）。

加速建议：
- 使用模拟器而非真机（编译更快）
- 关闭不必要的 Xcode 功能（自动完成等）
- 确保 Mac 有足够的可用空间（至少 10GB）

---

### Q: 编译报错 "No such module 'SwiftData'"？

**A**: 这通常是 iOS 版本太低导致的。

解决方法：
1. 确保 Xcode 版本 >= 15.0
2. 确保 iOS 部署目标 >= 17.0
3. 检查 `project.yml` 中的设置：

```yaml
options:
  deploymentTarget:
    iOS: "17.0"
```

---

### Q: 模拟器运行卡顿？

**A**: 可能的原因和解决方法：

1. **模拟器性能不足**: 选择性能更好的模拟器（如 iPhone 15 Pro）
2. **Mac 性能不足**: 关闭其他应用程序
3. **Xcode 调试模式**: 使用 Release 模式编译（Product → Scheme → Edit Scheme → Run → Build Configuration → Release）

---

## 🎯 功能使用

### Q: 如何触发自动记账？

**A**: 有多种方式：

**iPhone 15 Pro 用户**（推荐）：
1. 支付完成后停留在支付结果页面
2. 按下侧边操作按钮
3. 自动截图并记账

**其他机型**：
- **Siri**: "嘿 Siri，记一笔账"
- **小组件**: 添加桌面小组件，点击快速记账
- **轻点背面**: 设置 → 辅助功能 → 触控 → 轻点背面 → 选择快捷指令

---

### Q: 智能分类不准确怎么办？

**A**: 智能分类会随着使用越来越准确：

1. **手动修正**: 如果分类错误，点击交易编辑正确的分类
2. **学习过程**: 系统会记住你的修正，下次自动应用
3. **关键词配置**: 在设置中可以添加自定义关键词规则

---

### Q: 如何导出数据？

**A**: 当前版本（v1.0）支持基础功能，数据导出功能在 v1.5 规划中。

临时方案：数据存储在 SwiftData，可以通过：
1. iCloud 自动同步（如果启用）
2. 等待 v1.5 的 CSV/Excel 导出功能

---

## 🐛 错误排查

### Q: "Failed to register bundle identifier" 错误？

**A**: Bundle ID 冲突。解决方法：

1. 修改 `project.yml` 中的 `bundleIdPrefix`
2. 重新运行配置脚本
3. 或者在 Xcode 中手动修改 Bundle ID

---

### Q: Widget 扩展编译失败？

**A**: 检查以下几点：

1. **App Group 配置**: 确保主应用和 Widget 使用相同的 App Group ID
2. **签名配置**: 确保 Widget target 也配置了签名
3. **部署目标**: 确保 Widget 的 iOS 部署目标 >= 17.0

---

### Q: "Command PhaseScriptExecution failed" 错误？

**A**: 这通常是脚本权限问题：

1. 在 Xcode 中：Build Settings → User Script Sandboxing → 设为 NO
2. 或者在 `project.yml` 中已经配置：

```yaml
settings:
  base:
    ENABLE_USER_SCRIPT_SANDBOXING: YES
```

如果还是失败，检查项目中是否有自定义构建脚本。

---

### Q: App 在真机上启动就闪退？

**A**: 可能的原因：

1. **未信任证书**: 设置 → 通用 → VPN与设备管理 → 信任开发者
2. **权限问题**: 检查是否缺少必要的权限（相机、相册等）
3. **数据迁移**: 卸载旧版本后重新安装
4. **查看崩溃日志**: Xcode → Window → Devices and Simulators → View Device Logs

---

### Q: 快捷指令无法调用 App？

**A**: 检查以下配置：

1. **App Intents 权限**: 确保 App 有 Siri 权限
2. **Info.plist**: 确认包含了 `NSSupportsLiveActivities` 和用户活动类型
3. **重新安装**: 删除 App 后重新安装，确保 Intents 注册成功
4. **重启设备**: 有时需要重启 iPhone 让系统识别新的 Intents

---

### Q: xcodegen 生成项目失败？

**A**: 常见原因和解决方法：

```bash
# 1. 更新 xcodegen
brew upgrade xcodegen

# 2. 检查 project.yml 语法
xcodegen generate --spec project.yml

# 3. 清理缓存后重试
rm -rf .build
xcodegen generate --use-cache
```

如果还是失败，检查 `project.yml` 文件格式是否正确（YAML 语法）。

---

## 🔄 项目管理

### Q: 如何更新项目配置？

**A**:

1. 编辑 `project.yml` 文件
2. 重新运行配置脚本：`./setup-xcode-project.sh`
3. 脚本会自动备份旧项目并生成新的

---

### Q: 旧的项目文件哪去了？

**A**: 自动备份在同一目录下，文件名带时间戳：

```
AutoBookkeeping.xcodeproj.backup.20250119_143022
```

如需恢复：

```bash
rm -rf AutoBookkeeping.xcodeproj
mv AutoBookkeeping.xcodeproj.backup.20250119_143022 AutoBookkeeping.xcodeproj
```

---

### Q: 添加新文件后需要重新生成项目吗？

**A**:

- ✅ **需要**: 添加新的文件夹
- ❌ **不需要**: 在现有文件夹中添加文件（Xcode 会自动识别）
- ✅ **需要**: 修改了项目配置（Bundle ID、权限等）

---

### Q: 如何贡献代码？

**A**:

1. Fork 项目到你的账号
2. 创建功能分支：`git checkout -b feature/amazing-feature`
3. 提交更改：`git commit -m 'Add amazing feature'`
4. 推送分支：`git push origin feature/amazing-feature`
5. 创建 Pull Request

详细请查看 [CONTRIBUTING.md](../CONTRIBUTING.md)

---

## 📚 更多帮助

### 找不到答案？

1. **查看完整文档**: [docs/XCODE_SETUP.md](XCODE_SETUP.md)
2. **搜索 Issue**: 在 [GitHub Issues](https://github.com/XiaoLinZzz/Record-Money/issues) 搜索类似问题
3. **创建新 Issue**: 提供详细信息（错误日志、截图、系统版本等）
4. **查看官方文档**:
   - [Apple SwiftUI](https://developer.apple.com/documentation/swiftui)
   - [App Intents](https://developer.apple.com/documentation/appintents)
   - [xcodegen](https://github.com/yonaskolb/XcodeGen)

---

## 🎓 学习资源

- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [App Intents 指南](https://developer.apple.com/documentation/appintents)
- [快捷指令文档](https://support.apple.com/guide/shortcuts/welcome/ios)

---

**还有其他问题？欢迎在 GitHub 上提 Issue！** 🚀
