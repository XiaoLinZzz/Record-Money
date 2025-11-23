# 无感记账 - React Native 版本

这是无感记账应用的 React Native (Expo) 版本，从原始的 Swift/SwiftUI 项目迁移而来。

## 📱 项目概述

**无感记账** 是一款智能记账应用，支持以下核心功能：

- 🤖 **智能分类** - 基于规则匹配的自动分类引擎
- 💾 **本地存储** - 使用 WatermelonDB 实现高性能本地数据库
- 📊 **统计分析** - 多维度的支出收入分析
- 🎯 **预算管理** - 支持分类预算和总预算设置
- 🔔 **通知提醒** - 记账提醒和预算预警
- 🍎 **iOS 原生风格** - 保持原生 Apple UI 设计风格

## 🏗️ 技术栈

### 核心框架
- **React Native**: 0.74.5
- **Expo**: ~51.0.0
- **TypeScript**: ^5.3.0

### 数据层
- **WatermelonDB**: ^0.27.1 - 高性能 React Native 数据库
- **AsyncStorage**: 用于用户偏好设置存储

### 导航与 UI
- **React Navigation**: ^6.1.9 - 底部标签导航
- **React Native Vector Icons**: ^10.0.3 - 图标库
- **date-fns**: ^3.0.6 - 日期处理

### 功能模块
- **expo-notifications**: ~0.28.1 - 本地通知
- **expo-haptics**: ~13.0.1 - 触觉反馈
- **expo-image-picker**: ~15.0.5 - 图片选择（OCR）
- **expo-camera**: ~15.0.5 - 相机（扫描小票）

## 📂 项目结构

```
Record-Money/
├── src/
│   ├── models/              # 数据模型 (WatermelonDB)
│   │   ├── Transaction.ts   # 交易记录模型
│   │   ├── Category.ts      # 分类模型
│   │   └── Budget.ts        # 预算模型
│   │
│   ├── database/            # 数据库配置
│   │   ├── schema.ts        # 数据库 Schema
│   │   ├── index.ts         # 数据库实例
│   │   └── migrations.ts    # 数据迁移
│   │
│   ├── services/            # 业务逻辑层
│   │   ├── DataManager.ts           # 数据管理服务
│   │   ├── CategoryEngine.ts        # 智能分类引擎
│   │   ├── DatabaseProvider.tsx     # 数据库提供者
│   │   ├── DatabaseInitializer.ts   # 数据库初始化
│   │   └── NotificationProvider.tsx # 通知提供者
│   │
│   ├── screens/             # 界面页面
│   │   ├── Transaction/     # 交易相关界面
│   │   │   └── TransactionListScreen.tsx
│   │   ├── Statistics/      # 统计界面
│   │   │   └── StatisticsScreen.tsx
│   │   └── Settings/        # 设置界面
│   │       └── SettingsScreen.tsx
│   │
│   ├── navigation/          # 导航配置
│   │   └── AppNavigator.tsx
│   │
│   ├── components/          # 可复用组件
│   ├── utils/               # 工具函数
│   └── types/               # TypeScript 类型定义
│
├── App.tsx                  # 应用入口
├── app.json                 # Expo 配置
├── package.json             # 依赖配置
├── tsconfig.json            # TypeScript 配置
└── babel.config.js          # Babel 配置
```

## 🚀 快速开始

### 环境要求

- Node.js >= 18.0.0
- npm 或 yarn
- iOS 模拟器或 Android 模拟器
- Expo Go App（用于真机测试）

### 安装依赖

```bash
# 使用 npm
npm install

# 或使用 yarn
yarn install
```

### 运行项目

```bash
# 启动开发服务器
npm start

# 在 iOS 模拟器中运行
npm run ios

# 在 Android 模拟器中运行
npm run android

# 在浏览器中运行
npm run web
```

### 构建生产版本

```bash
# 使用 Expo EAS Build
eas build --platform ios
eas build --platform android
```

## 📊 核心功能实现状态

### ✅ 已完成

- [x] **数据模型层**
  - Transaction（交易记录）
  - Category（分类）
  - Budget（预算）

- [x] **数据持久化层**
  - WatermelonDB 集成
  - Schema 定义
  - 数据库初始化

- [x] **核心服务层**
  - DataManager（数据管理）
  - CategoryEngine（智能分类引擎）
  - 用户规则学习机制

- [x] **基础 UI**
  - 交易列表界面
  - 统计分析界面
  - 设置界面
  - 底部标签导航

- [x] **通知系统**
  - 通知权限管理
  - 通知提供者

### 🔄 进行中

- [ ] **OCR 功能**（需要创建原生模块）
  - 小票扫描
  - 文字识别
  - 金额提取

- [ ] **自然语言解析**
  - 智能输入
  - 文本解析

### 📝 待实现

- [ ] **App Intents 集成**（iOS Shortcuts）
  - 快捷指令配置
  - 后台记账

- [ ] **完整 UI 界面**
  - 添加交易界面
  - 编辑交易界面
  - 预算管理界面
  - 分类管理界面
  - 小票扫描界面

- [ ] **高级功能**
  - 图表可视化
  - 数据导出
  - 数据备份与恢复

## 🔄 迁移说明

### 从 Swift 到 TypeScript 的主要变更

1. **数据持久化**
   - Swift: SwiftData
   - React Native: WatermelonDB

2. **状态管理**
   - Swift: @Observable, @EnvironmentObject
   - React Native: React Hooks, Context API

3. **UI 框架**
   - Swift: SwiftUI
   - React Native: React Native + iOS 原生风格组件

4. **导航**
   - Swift: NavigationStack, TabView
   - React Native: React Navigation

### 保持不变的逻辑

- ✅ 智能分类算法（完全一致）
- ✅ 数据模型结构（字段和关系一致）
- ✅ 业务逻辑（CRUD 操作、统计计算）
- ✅ 用户规则学习机制

## 🎨 UI 设计原则

保持原生 iOS 风格：

- 使用 iOS 标准颜色（#007AFF 蓝色、#FF3B30 红色、#34C759 绿色）
- SF Symbols 图标风格
- iOS 标准字体和字号
- 原生触觉反馈
- iOS 标准动画

## 🧪 测试

```bash
# 运行测试（待添加）
npm test

# 类型检查
npx tsc --noEmit

# 代码检查
npm run lint
```

## 📱 iOS 原生模块

以下功能需要创建 iOS 原生模块：

1. **OCR 模块**（基于 Vision Framework）
   - 位置：`ios/Modules/OCRModule/`
   - 功能：小票扫描、文字识别

2. **App Intents 模块**
   - 位置：`ios/Intents/`
   - 功能：快捷指令集成

3. **Widget 扩展**
   - 位置：`ios/Widgets/`
   - 功能：桌面小组件

## 🔧 配置说明

### App Group（iOS）

需要在 Xcode 中配置 App Group，用于主 App 和 Widget 之间共享数据：

```
group.com.yourdomain.recordmoney
```

### 权限配置

已在 `app.json` 中配置：

- 相机权限（扫描小票）
- 相册权限（选择图片）
- 通知权限（记账提醒）

## 📝 开发注意事项

1. **数据库操作**
   - 所有写操作必须在 `database.write()` 中执行
   - 使用 WatermelonDB 的响应式查询

2. **性能优化**
   - 使用 `React.memo` 避免不必要的重渲染
   - 列表使用 `FlatList` 的优化特性
   - 图片使用 `expo-image` 进行优化

3. **类型安全**
   - 所有代码使用 TypeScript
   - 严格的类型检查

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 🙏 致谢

- 原始 Swift 版本作者
- React Native 社区
- Expo 团队

---

**注意**：这是一个从 Swift/SwiftUI 迁移到 React Native 的项目，核心逻辑和功能保持一致。
