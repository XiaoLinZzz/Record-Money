# 🚀 AutoBookkeeping 快速启动指南

> **Swift 新手？不用担心！** 这份指南将手把手教你如何启动这个项目。

---

## 📱 这是什么项目？

**AutoBookkeeping** 是一个功能完整的 iOS 智能记账应用，包含：

- ✅ **AI 智能识别**：扫描小票自动记账（OCR）
- ✅ **自然语言输入**：说人话记账（如"今天午饭花了35块"）
- ✅ **预算管理**：设置预算并自动提醒
- ✅ **图表分析**：漂亮的收支趋势图
- ✅ **自定义分类**：个性化的账目分类
- ✅ **桌面小组件**：一眼看到今日支出

**100% 离线运行，零额外成本，中国区完全可用！**

---

## ⚡ 最快启动方法（5 步走）

### 前提条件

- ✅ 你有一台 Mac 电脑
- ✅ macOS 13.0 或更高版本
- ⚠️ 需要安装 Xcode（免费，约 10-15 GB）

---

### 步骤 1️⃣：安装 Xcode（如果还没安装）

**方法 A - App Store（推荐）**：
1. 打开 **App Store**
2. 搜索 **"Xcode"**
3. 点击 **"获取"** → 等待下载（30-60 分钟）

**方法 B - 官网下载**：
- 访问：https://developer.apple.com/download/
- 下载最新版 Xcode

**验证安装**：
```bash
# 打开终端（Terminal），输入：
xcodebuild -version
# 应该看到：Xcode 15.x
```

---

### 步骤 2️⃣：下载项目代码

如果你还没有项目代码：

```bash
# 在终端中执行：
git clone https://github.com/yourusername/Record-Money.git
cd Record-Money
```

或者直接下载 ZIP 文件并解压。

---

### 步骤 3️⃣：运行快速设置脚本（可选）

```bash
# 在项目根目录执行：
./setup-xcode-project.sh
```

这个脚本会：
- ✅ 检查 Xcode 是否安装
- ✅ 显示详细的设置说明
- ✅ 自动生成项目（如果可能）

---

### 步骤 4️⃣：在 Xcode 中创建项目

#### 4.1 创建新项目

1. 打开 **Xcode**
2. 点击 **"Create a new Xcode project"**

![Xcode 欢迎界面](https://developer.apple.com/assets/elements/icons/xcode-12/xcode-12-96x96_2x.png)

3. 选择模板：
   ```
   平台：iOS
   类型：App
   点击：Next
   ```

4. 填写项目信息：
   ```
   Product Name: AutoBookkeeping
   Team: None（或选择你的 Apple ID）
   Organization Identifier: com.yourcompany
   Interface: SwiftUI ✅
   Language: Swift ✅
   Storage: SwiftData ✅
   取消勾选: Include Tests
   ```

5. 选择保存位置（**新建一个文件夹，不要选择现有目录**）

#### 4.2 导入源代码

**方式 1 - 拖拽文件（最简单）**：

1. 在 **Finder** 中打开 `Record-Money/AutoBookkeeping/` 文件夹

2. 同时在 **Xcode** 左侧看到项目结构

3. **拖拽**以下文件夹到 Xcode 项目中（拖到项目名称下）：
   - `Models/` 文件夹
   - `Views/` 文件夹
   - `Services/` 文件夹
   - `Utilities/` 文件夹
   - `App/AutoBookkeepingApp.swift`（会提示替换，选择替换）

4. 在弹出的对话框中：
   - ✅ **勾选** "Copy items if needed"
   - ✅ **勾选** "Create groups"
   - ✅ **Target**: AutoBookkeeping
   - 点击 **Finish**

5. 导入资源文件：
   - 拖拽 `Resources/Assets.xcassets` 到项目
   - 同样勾选 "Copy items if needed"

**方式 2 - 复制粘贴**：

```bash
# 假设新项目在 ~/Desktop/AutoBookkeeping
cd ~/Desktop/AutoBookkeeping/AutoBookkeeping

# 复制源代码
cp -r ~/Record-Money/AutoBookkeeping/Models ./
cp -r ~/Record-Money/AutoBookkeeping/Views ./
cp -r ~/Record-Money/AutoBookkeeping/Services ./
cp -r ~/Record-Money/AutoBookkeeping/Utilities ./
cp ~/Record-Money/AutoBookkeeping/App/AutoBookkeepingApp.swift ./
cp -r ~/Record-Money/AutoBookkeeping/Resources/Assets.xcassets ../
```

然后在 Xcode 中右键 → Add Files to "AutoBookkeeping"

---

### 步骤 5️⃣：配置和运行

#### 5.1 设置最低部署目标

1. 在 Xcode 左侧点击**项目名称**（蓝色图标）
2. 选择 **TARGETS** → **AutoBookkeeping**
3. 在 **General** 标签：
   - **Minimum Deployments** → **iOS 17.0**

#### 5.2 添加权限

1. 找到 **Info.plist** 文件
2. 右键 → **Open As** → **Source Code**
3. 在 `<dict>` 内添加：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机扫描小票进行智能记账</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册选择小票照片进行识别</string>
```

或者通过界面添加：
- 点击 Info.plist
- 点击 **+** 号
- 添加 `Privacy - Camera Usage Description`
- 添加 `Privacy - Photo Library Usage Description`

#### 5.3 运行！

1. 选择模拟器：顶部工具栏 → **iPhone 15 Pro**
2. 点击 **▶️ 运行按钮** 或按 **⌘ + R**
3. 等待编译（第一次 5-10 分钟，很正常！）
4. 🎉 App 会自动在模拟器中启动！

---

## 🐛 遇到问题？

### ❌ 编译错误："Cannot find 'DataManager' in scope"

**原因**：文件没有正确添加到项目

**解决**：
1. 找到 `Services/DataManager.swift`
2. 右侧面板 → **Target Membership**
3. 确保 ✅ **AutoBookkeeping** 被勾选

### ❌ 编译错误："No such module 'SwiftData'"

**原因**：部署目标太低

**解决**：
1. 项目设置 → **General**
2. **Minimum Deployments** → **iOS 17.0**

### ❌ App 在模拟器中崩溃

**解决**：
1. 查看底部 **Debug Area** 的错误日志
2. 确保所有 `.swift` 文件都已添加
3. 尝试 **Product** → **Clean Build Folder** (⇧⌘K)
4. 重新运行

### ❌ "Missing required module 'SwiftUI'"

**原因**：文件顶部缺少导入语句

**解决**：
确保每个 `.swift` 文件顶部都有：
```swift
import SwiftUI
import SwiftData  // 数据模型文件需要
```

---

## 📚 下一步

成功运行后，你可以：

### 1. 探索功能
- ➕ 添加一笔交易
- 📊 查看统计图表
- 💰 设置预算
- 📸 试试扫描小票（需要真机）
- 🔤 试试智能输入："今天午饭花了35块"

### 2. 学习代码
- 从 `Views/Transaction/TransactionListView.swift` 开始
- 理解 SwiftUI 的声明式语法
- 查看数据模型 `Models/Transaction.swift`

### 3. 自定义修改
- 修改主题颜色
- 添加新的分类
- 调整界面布局

### 4. 添加 Widget
- 查看 `/docs/WIDGET_IMPLEMENTATION_GUIDE.md`
- 在主屏幕显示今日支出

---

## 📖 详细文档

- **完整启动指南**：`docs/GETTING_STARTED.md`
- **项目概览**：`docs/IMPLEMENTATION_SUMMARY.md`
- **Widget 教程**：`docs/WIDGET_IMPLEMENTATION_GUIDE.md`
- **App Icon 设计**：`docs/APP_ICON_DESIGN.md`

---

## 🆘 获取帮助

1. **查看文档**：先看 `/docs/` 目录
2. **Google 搜索**：复制错误信息搜索
3. **Stack Overflow**：https://stackoverflow.com/questions/tagged/swiftui
4. **Swift 官方论坛**：https://forums.swift.org/

---

## 🎓 学习资源（Swift 新手）

### 视频教程
- **Stanford CS193p**（免费）：https://cs193p.sites.stanford.edu/
- **100 Days of SwiftUI**：https://www.hackingwithswift.com/100/swiftui

### 在线教程
- **Swift 官方教程**：https://swift.org/getting-started/
- **SwiftUI 教程（中文）**：https://www.swiftui.cn/

### 书籍推荐
- 《SwiftUI 与 Combine 编程》
- 《iOS 开发指南》

---

## ✅ 检查清单

启动前确保：

- [ ] ✅ 已安装 Xcode 15+
- [ ] ✅ 创建了新的 Xcode 项目
- [ ] ✅ 导入了所有源代码文件
- [ ] ✅ 设置了 iOS 17.0 部署目标
- [ ] ✅ 添加了相机/照片库权限
- [ ] ✅ 项目可以成功编译
- [ ] ✅ 可以在模拟器中运行

---

## 🎉 成功了吗？

如果你成功启动了 App，恭喜你迈出了 iOS 开发的第一步！

这个项目包含了：
- 10000+ 行生产级代码
- 完整的 AI 功能实现
- 专业的 UX 设计
- Apple 最佳实践

好好学习，慢慢探索，你一定能掌握 iOS 开发！💪

---

**需要帮助？** 先看 `docs/GETTING_STARTED.md` 获取更详细的说明！
