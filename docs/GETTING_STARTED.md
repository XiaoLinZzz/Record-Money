# AutoBookkeeping 项目启动指南（Swift 新手版）

## 🎯 项目说明

AutoBookkeeping 是一个功能完整的 iOS 自动记账应用，包含：
- ✅ AI 功能（OCR、NLP、CoreML）
- ✅ 预算管理
- ✅ 图表可视化
- ✅ Widget 小组件
- ✅ 完整的 UX 体验

## 📋 前置要求

### 必需
- **Mac 电脑**（MacBook、iMac、Mac Mini 等）
- **macOS 13.0 或更高版本**（建议 macOS 14+）
- **Xcode 15.0 或更高版本**（免费）

### 可选
- **Apple Developer 账号**（运行在真机需要，模拟器不需要）
- **iOS 17 设备**（用于真机测试）

---

## 📥 第一步：安装 Xcode

### 方法 1：从 App Store 安装（推荐）

1. 打开 **App Store**
2. 搜索 **"Xcode"**
3. 点击 **"获取"** → **"安装"**
4. 等待下载（约 10-15 GB，需要 30-60 分钟）

### 方法 2：从 Apple 官网下载

1. 访问：https://developer.apple.com/download/
2. 登录 Apple ID
3. 下载最新版 Xcode
4. 安装 .xip 文件

### 验证安装

```bash
# 打开终端（Terminal），输入：
xcodebuild -version

# 应该看到类似输出：
# Xcode 15.0
# Build version 15A240d
```

---

## 🚀 第二步：创建 Xcode 项目

由于这个项目是在代码编辑器中创建的源文件，我们需要在 Xcode 中创建项目配置。

### 选项 A：使用 Xcode 创建新项目并导入源文件（推荐新手）

#### 1. 创建新项目

1. 打开 **Xcode**
2. 点击 **"Create a new Xcode project"**
3. 选择模板：
   - 平台：**iOS**
   - 应用类型：**App**
   - 点击 **Next**

4. 项目配置：
   - **Product Name**: `AutoBookkeeping`
   - **Team**: 选择你的 Apple ID（或 None）
   - **Organization Identifier**: `com.yourcompany`（改成你的域名倒写）
   - **Bundle Identifier**: 自动生成（例如：`com.yourcompany.AutoBookkeeping`）
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: **SwiftData**
   - **取消勾选** "Include Tests"（可选）
   - 点击 **Next**

5. 选择保存位置：
   - 选择一个**新的空文件夹**（不要选择现有的 Record-Money 目录）
   - 勾选 **"Create Git repository"**
   - 点击 **Create**

#### 2. 导入源文件

现在你有了一个空的 Xcode 项目，我们需要把源代码复制进去：

##### 2.1 删除自动生成的文件

在 Xcode 左侧项目导航器中，删除这些文件（右键 → Delete → Move to Trash）：
- `ContentView.swift`（保留，稍后替换）
- `Item.swift`（删除）

##### 2.2 复制源代码文件

**方法 1：通过 Finder 拖拽**

1. 在 Finder 中打开 `Record-Money/AutoBookkeeping/` 目录
2. 将以下文件夹**拖拽**到 Xcode 项目中：
   - `Models/` 文件夹
   - `Views/` 文件夹
   - `Services/` 文件夹
   - `Utilities/` 文件夹
   - `Intents/` 文件夹（如果有）

3. 在弹出的对话框中：
   - ✅ 勾选 **"Copy items if needed"**
   - ✅ 勾选 **"Create groups"**
   - ✅ Target: 选择 **AutoBookkeeping**
   - 点击 **Finish**

**方法 2：通过终端复制**

```bash
# 在终端中执行（假设你的新项目在 ~/Desktop/AutoBookkeeping）
cd ~/Desktop/AutoBookkeeping/AutoBookkeeping

# 复制源代码目录
cp -r ~/Record-Money/AutoBookkeeping/Models ./
cp -r ~/Record-Money/AutoBookkeeping/Views ./
cp -r ~/Record-Money/AutoBookkeeping/Services ./
cp -r ~/Record-Money/AutoBookkeeping/Utilities ./
cp -r ~/Record-Money/AutoBookkeeping/Intents ./

# 复制 App 入口文件（替换自动生成的）
cp ~/Record-Money/AutoBookkeeping/App/AutoBookkeepingApp.swift ./
```

然后在 Xcode 中：
1. 右键点击项目名称
2. 选择 **"Add Files to AutoBookkeeping"**
3. 选择刚才复制的所有文件夹
4. 点击 **Add**

##### 2.3 复制 Resources

1. 在 Finder 中找到 `Record-Money/AutoBookkeeping/Resources/`
2. 将 `Assets.xcassets` 文件夹拖入 Xcode 项目
3. 勾选 **"Copy items if needed"**

---

### 选项 B：使用 Swift Package Manager（适合有经验的用户）

这个选项需要手动创建 Package.swift 和项目配置，**不推荐新手使用**。

---

## ⚙️ 第三步：配置项目

### 1. 设置最低部署目标

1. 在 Xcode 左侧选择**项目名称**（蓝色图标）
2. 选择 **TARGETS** → **AutoBookkeeping**
3. 在 **General** 标签下：
   - **Minimum Deployments**: 设置为 **iOS 17.0**

### 2. 配置 Info.plist 权限

需要添加隐私权限描述：

1. 在项目导航器中找到 **Info.plist**
2. 右键点击 → **Open As** → **Source Code**
3. 在 `<dict>` 标签内添加以下内容：

```xml
<!-- 相机权限 -->
<key>NSCameraUsageDescription</key>
<string>需要使用相机扫描小票进行智能记账</string>

<!-- 照片库权限 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册选择小票照片进行识别</string>

<!-- 通知权限 -->
<key>NSUserNotificationsUsageDescription</key>
<string>发送预算提醒和记账提醒通知</string>
```

或者通过 Xcode 界面添加：
1. 选择 **Info.plist**
2. 点击任意一行，然后点击 **+** 号
3. 添加以下 Key：
   - `Privacy - Camera Usage Description`
   - `Privacy - Photo Library Usage Description`
   - `Privacy - User Notifications Usage Description`
4. 在 Value 列填写上述描述

### 3. 配置 Capabilities（可选，用于 Widget）

如果要使用 Widget 功能：

1. 选择 **TARGETS** → **AutoBookkeeping**
2. 点击 **Signing & Capabilities** 标签
3. 点击 **+ Capability**
4. 添加：
   - **App Groups**
   - 点击 **+** 添加：`group.com.yourcompany.autobookkeeping`

---

## 🔧 第四步：解决编译错误

### 常见错误 1：找不到 DataManager

如果看到 `Cannot find 'DataManager' in scope` 错误：

**解决方案**：
1. 确保 `Services/DataManager.swift` 文件已添加到项目
2. 检查文件的 Target Membership（右侧面板）是否勾选了 AutoBookkeeping

### 常见错误 2：找不到 ContentView

**解决方案**：
在 `Views/` 目录下查找 `ContentView.swift`，如果没有，需要创建一个。

### 常见错误 3：SwiftData 模型错误

如果看到 `@Model` 相关错误：

**解决方案**：
确保每个模型文件顶部都导入了：
```swift
import SwiftUI
import SwiftData
```

---

## ▶️ 第五步：运行项目

### 在模拟器中运行

1. 在 Xcode 顶部工具栏，选择目标设备：
   - 点击设备下拉菜单
   - 选择 **iPhone 15 Pro** 或其他模拟器

2. 点击 **Run 按钮**（▶️）或按 **⌘ + R**

3. 等待构建（第一次会比较慢，5-10 分钟）

4. 模拟器会自动启动并运行 App

### 在真机上运行（需要 Apple Developer 账号）

1. 用数据线连接 iPhone 到 Mac
2. 在设备下拉菜单中选择你的 iPhone
3. 第一次需要：
   - 在 Xcode 中登录 Apple ID（Preferences → Accounts）
   - 选择 Team（你的 Apple ID）
   - 在 iPhone 上信任开发者（设置 → 通用 → VPN与设备管理）
4. 点击 Run

---

## 🐛 常见问题排查

### Q1: 编译时出现大量错误

**A**: 可能是文件引用问题
- 检查所有 `.swift` 文件是否都在 Xcode 项目中
- 确保 Target Membership 正确
- 尝试 **Product** → **Clean Build Folder** (⇧⌘K)
- 重新编译

### Q2: App 在模拟器中崩溃

**A**: 查看控制台日志
- 打开 **Debug Area**（底部面板）
- 查看错误信息
- 通常是数据模型或权限问题

### Q3: Widget 无法显示

**A**: Widget 需要单独的 Target
- 查看 `/docs/WIDGET_IMPLEMENTATION_GUIDE.md`
- Widget 需要创建单独的 Extension Target

### Q4: OCR/相机功能不工作

**A**: 检查权限配置
- 确保 Info.plist 中添加了相机和照片库权限
- 在模拟器中，相机功能可能不可用
- 需要在真机上测试

---

## 📚 学习资源（Swift 新手推荐）

### 官方资源

1. **Swift 官方教程**
   - https://swift.org/getting-started/
   - 中文版：https://swiftgg.gitbook.io/swift/

2. **SwiftUI 官方教程**
   - https://developer.apple.com/tutorials/swiftui
   - Apple 官方，非常适合新手

3. **SwiftData 文档**
   - https://developer.apple.com/documentation/swiftdata

### 视频教程

1. **Stanford CS193p (SwiftUI)**
   - YouTube 免费课程
   - 讲师：Paul Hegarty
   - 链接：https://cs193p.sites.stanford.edu/

2. **Hacking with Swift**
   - 100 Days of SwiftUI
   - 链接：https://www.hackingwithswift.com/100/swiftui

### 中文资源

1. **SwiftUI 中文教程**
   - https://www.swiftui.cn/

2. **ObjC 中国**
   - https://objccn.io/

---

## 🎯 项目结构说明

理解项目结构有助于你维护和扩展代码：

```
AutoBookkeeping/
├── App/
│   └── AutoBookkeepingApp.swift          # 应用入口
│
├── Models/                                # 数据模型
│   ├── Transaction.swift                 # 交易记录
│   ├── Budget.swift                      # 预算
│   ├── Category.swift                    # 分类
│   └── TransactionFilter.swift           # 筛选器
│
├── Views/                                 # 界面视图
│   ├── Transaction/                      # 交易相关视图
│   ├── Budget/                           # 预算视图
│   ├── Statistics/                       # 统计图表
│   ├── Category/                         # 分类管理
│   └── Receipt/                          # 小票扫描
│
├── Services/                              # 业务逻辑
│   ├── DataManager.swift                 # 数据管理
│   ├── BudgetManager.swift               # 预算管理
│   ├── CategoryEngine.swift              # 分类引擎
│   ├── OCRManager.swift                  # OCR 识别
│   ├── NLPParser.swift                   # NLP 解析
│   ├── ChartDataProvider.swift           # 图表数据
│   └── WidgetDataManager.swift           # Widget 数据
│
├── Utilities/                             # 工具类
│   └── HapticManager.swift               # 触觉反馈
│
└── Resources/                             # 资源文件
    └── Assets.xcassets/                  # 图片资源
        └── AppIcon.appiconset/           # App 图标
```

---

## 🔍 核心概念解释（Swift 新手必读）

### SwiftUI
- 声明式 UI 框架
- 用代码描述界面长什么样
- 数据变化时自动更新界面

### SwiftData
- iOS 17 新的数据持久化框架
- 用 `@Model` 标记数据类
- 自动保存到数据库

### MVVM 模式
- Model：数据模型（Transaction, Budget）
- View：界面视图（所有 View 文件）
- ViewModel：业务逻辑（Manager 类）

### 重要修饰符
- `@State`：视图内部状态
- `@StateObject`：创建并拥有对象
- `@EnvironmentObject`：全局共享对象
- `@Model`：SwiftData 数据模型

---

## ✅ 检查清单

启动项目前，确保：

- [ ] 已安装 Xcode 15+
- [ ] 已创建 Xcode 项目
- [ ] 所有源文件已添加到项目
- [ ] Target Membership 配置正确
- [ ] Info.plist 权限已添加
- [ ] 最低部署目标设为 iOS 17.0
- [ ] 项目可以成功编译
- [ ] 可以在模拟器中运行

---

## 🆘 获取帮助

如果遇到问题：

1. **查看编译错误**：仔细阅读错误信息
2. **Clean Build**：Product → Clean Build Folder
3. **重启 Xcode**：有时候重启可以解决奇怪的问题
4. **查看文档**：参考 `/docs/` 目录下的文档
5. **Google 搜索**：复制错误信息搜索
6. **Stack Overflow**：https://stackoverflow.com/questions/tagged/swiftui

---

## 🎉 成功启动后

恭喜！如果你成功运行了 App，接下来可以：

1. **探索功能**：
   - 添加交易记录
   - 设置预算
   - 查看图表
   - 试试 OCR 扫描小票

2. **学习代码**：
   - 从简单的 View 文件开始看
   - 理解 SwiftUI 的声明式语法
   - 学习 SwiftData 的数据操作

3. **自定义修改**：
   - 修改颜色和样式
   - 添加新功能
   - 调整界面布局

4. **添加 Widget**：
   - 按照 `/docs/WIDGET_IMPLEMENTATION_GUIDE.md`
   - 创建 Widget Extension

---

**祝你学习愉快！如果有任何问题，随时查看项目文档或搜索相关教程。** 🚀
