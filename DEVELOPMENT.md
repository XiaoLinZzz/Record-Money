# Record Money - 开发文档

完整的 iOS 记账应用，从 Swift/SwiftUI 迁移至 React Native + Expo。

## 📋 目录

- [项目概述](#项目概述)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [开发环境设置](#开发环境设置)
- [运行项目](#运行项目)
- [开发指南](#开发指南)
- [代码规范](#代码规范)
- [调试指南](#调试指南)
- [常见问题](#常见问题)

## 项目概述

Record Money 是一个功能齐全的 iOS 记账应用，具备以下核心功能：

- ✅ 交易管理（收入/支出）
- ✅ 智能分类识别
- ✅ 自然语言解析
- ✅ 预算管理
- ✅ 统计分析
- ✅ 分类管理

### 迁移目标

本项目将原 Swift/SwiftUI 应用迁移至 React Native + Expo，同时保持：

- **100% 业务逻辑一致性** - 所有算法和数据处理逻辑与 Swift 版本完全相同
- **iOS 原生 UI 体验** - 使用 iOS 原生设计规范和交互模式
- **TypeScript 类型安全** - 完整的类型定义和 strict mode

## 技术栈

### 核心框架

| 技术 | 版本 | 用途 |
|------|------|------|
| **React Native** | 0.74.5 | 跨平台移动应用框架 |
| **Expo** | ~51.0.0 | React Native 开发工具链 |
| **TypeScript** | ~5.3.3 | 类型安全的 JavaScript |
| **WatermelonDB** | ^0.27.1 | 高性能 SQLite ORM |

### UI 组件

- `react-native-vector-icons` - 图标库（Ionicons）
- `@react-native-picker/picker` - 原生选择器
- `@react-native-community/datetimepicker` - 日期时间选择器
- `react-navigation` - 导航框架

### 工具库

- `expo-haptics` - iOS 触觉反馈
- `@react-native-async-storage/async-storage` - 本地存储
- `dayjs` - 日期处理

### 开发工具

- `eslint` - 代码检查
- `prettier` - 代码格式化
- `babel` - JavaScript 编译器

## 项目结构

```
src/
├── database/
│   ├── schema.ts              # WatermelonDB 数据库 schema
│   └── index.ts               # 数据库初始化
├── models/
│   ├── Transaction.ts         # 交易数据模型
│   ├── Category.ts            # 分类数据模型
│   └── Budget.ts              # 预算数据模型
├── services/
│   ├── DataManager.ts         # 数据管理服务（Singleton）
│   ├── CategoryEngine.ts      # 智能分类引擎
│   ├── NLPParser.ts           # 自然语言解析器
│   ├── BudgetManager.ts       # 预算管理器
│   ├── DatabaseProvider.tsx   # 数据库 Context Provider
│   └── NotificationProvider.tsx # 通知权限管理
├── screens/
│   ├── Transaction/
│   │   ├── TransactionListScreen.tsx    # 交易列表
│   │   ├── AddTransactionModal.tsx      # 添加交易
│   │   ├── EditTransactionModal.tsx     # 编辑交易
│   │   └── SmartInputModal.tsx          # 智能输入
│   ├── Statistics/
│   │   └── StatisticsScreen.tsx         # 统计分析
│   ├── Settings/
│   │   └── SettingsScreen.tsx           # 设置
│   ├── Budget/
│   │   ├── BudgetOverviewScreen.tsx     # 预算概览
│   │   └── SetBudgetModal.tsx           # 设置预算
│   └── Category/
│       ├── CategoryManagementScreen.tsx # 分类管理
│       └── AddCategoryModal.tsx         # 添加分类
├── navigation/
│   └── AppNavigator.tsx       # 应用导航配置
└── utils/
    └── helpers.ts             # 工具函数
```

## 开发环境设置

### 系统要求

- **macOS**: 用于 iOS 开发
- **Node.js**: >= 18.0.0
- **npm** 或 **yarn**: 包管理器
- **Xcode**: >= 15.0（iOS 模拟器）
- **iOS Simulator**: iOS 17.0+

### 安装步骤

1. **克隆仓库**

```bash
git clone <repository-url>
cd Record-Money
```

2. **安装依赖**

```bash
npm install
# 或
yarn install
```

3. **iOS 依赖（可选）**

如果需要在 iOS 设备上运行，确保已安装 CocoaPods：

```bash
cd ios
pod install
cd ..
```

## 运行项目

### 启动开发服务器

```bash
npm start
# 或
yarn start
```

### 在 iOS 模拟器中运行

```bash
npm run ios
# 或
yarn ios
```

### 清除缓存并重启

```bash
npm start -- --clear
# 或
yarn start --clear
```

### 构建预览版本

```bash
npx expo build:ios
```

## 开发指南

### 数据库操作

#### 创建记录

```typescript
import { useDatabase } from '../../services/DatabaseProvider';
import DataManager from '../../services/DataManager';

const database = useDatabase();
DataManager.initialize(database);

// 保存交易
const transaction = await DataManager.saveTransaction({
  amount: 50.00,
  merchant: '星巴克',
  categoryName: '餐饮',
  type: 'expense',
  timestamp: new Date(),
  note: '早餐',
});
```

#### 查询记录

```typescript
// 获取所有交易
const transactions = await DataManager.fetchTransactions();

// 按分类查询
const foodTransactions = await DataManager.fetchTransactions('餐饮');

// 获取统计数据
const stats = await DataManager.getStatisticsSummary('month');
```

#### 更新记录

```typescript
await transaction.updateTransaction({
  amount: 60.00,
  merchant: '星巴克（修改）',
});
```

#### 删除记录（软删除）

```typescript
await transaction.softDelete();
```

### 智能分类

CategoryEngine 提供智能分类识别功能：

```typescript
import CategoryEngine from '../../services/CategoryEngine';

const engine = CategoryEngine.getInstance();
await engine.initialize(database);

// 推断分类
const category = engine.inferCategory('星巴克');
// 返回: "餐饮"

// 学习用户修正
await engine.learnFromUserCorrection('星巴克', '餐饮');
```

### 自然语言解析

NLPParser 可以从自然语言文本中提取交易信息：

```typescript
import NLPParser from '../../services/NLPParser';

const parser = new NLPParser();
const result = parser.parse('今天在星巴克花了50块');

// result = {
//   amount: 50,
//   merchant: '星巴克',
//   category: '餐饮',
//   date: new Date(),
//   transactionType: 'expense',
//   confidence: 0.85
// }
```

### 预算管理

BudgetManager 提供预算CRUD和计算功能：

```typescript
import BudgetManager from '../../services/BudgetManager';

const manager = BudgetManager.getInstance();
manager.initialize(database);

// 创建预算
await manager.saveBudget({
  categoryName: '餐饮',
  amount: 1000,
  period: 'monthly',
  startDate: new Date(),
  alertThreshold: 0.9,
});

// 获取预算详情
const details = await manager.getAllBudgetDetails();
// 每个 detail 包含: spending, usage, remaining, overage, isOver
```

### 导航

使用 React Navigation 进行页面导航：

```typescript
// 跳转到设置页
navigation.navigate('Settings');

// 返回上一页
navigation.goBack();

// 设置导航栏按钮
navigation.setOptions({
  headerRight: () => (
    <TouchableOpacity onPress={handleAction}>
      <Icon name="add" size={24} color="#007AFF" />
    </TouchableOpacity>
  ),
});
```

### 触觉反馈

使用 Expo Haptics 提供 iOS 原生触觉反馈：

```typescript
import * as Haptics from 'expo-haptics';

// 轻触反馈
Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);

// 中等强度反馈
Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

// 选择变化反馈
Haptics.selectionAsync();

// 通知反馈
Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
```

## 代码规范

### TypeScript

- 使用 **strict mode**
- 为所有函数添加返回类型
- 避免使用 `any`，优先使用具体类型或泛型
- 使用接口定义复杂对象类型

```typescript
// ✅ 好的实践
interface TransactionData {
  amount: number;
  merchant: string;
  categoryName: string;
}

async function saveTransaction(data: TransactionData): Promise<Transaction> {
  // ...
}

// ❌ 避免
function saveTransaction(data: any) {
  // ...
}
```

### 组件

- 使用函数组件和 Hooks
- 使用 `React.FC` 类型
- Props 使用接口定义
- 使用 `memo` 优化性能（必要时）

```typescript
interface MyComponentProps {
  title: string;
  onPress: () => void;
}

const MyComponent: React.FC<MyComponentProps> = ({ title, onPress }) => {
  return (
    <TouchableOpacity onPress={onPress}>
      <Text>{title}</Text>
    </TouchableOpacity>
  );
};
```

### 样式

- 使用 StyleSheet.create
- 遵循 iOS 设计规范的颜色和间距
- 使用有意义的样式名称

```typescript
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7', // iOS 浅色背景
  },
  primaryButton: {
    backgroundColor: '#007AFF', // iOS 蓝色
    borderRadius: 8,
    paddingVertical: 12,
  },
});
```

### 命名规范

- **文件名**: PascalCase for components (`TransactionListScreen.tsx`)
- **变量**: camelCase (`const userName = '...'`)
- **常量**: UPPER_SNAKE_CASE (`const MAX_RETRIES = 3`)
- **接口**: PascalCase with 'I' prefix optional (`interface UserData`)
- **类型**: PascalCase (`type TransactionType = 'income' | 'expense'`)

## 调试指南

### React Native Debugger

1. 安装 React Native Debugger:
```bash
brew install --cask react-native-debugger
```

2. 在模拟器中启用调试:
- 按 `Cmd + D` 打开开发菜单
- 选择 "Debug"

### Console 日志

```typescript
console.log('普通日志');
console.warn('警告信息');
console.error('错误信息');
```

### 数据库调试

查看 WatermelonDB 数据：

```typescript
// 打印所有交易
const transactions = await database.get('transactions').query().fetch();
console.log('All transactions:', transactions);

// 查看 SQL 查询
// 在 schema.ts 中启用 logging
```

### 性能监控

```typescript
import { PerformanceObserver } from 'react-native';

// 监控渲染性能
const observer = new PerformanceObserver((list) => {
  const entries = list.getEntries();
  entries.forEach((entry) => {
    console.log(`${entry.name}: ${entry.duration}ms`);
  });
});

observer.observe({ type: 'measure' });
```

### Expo 开发工具

在终端中按键快捷方式：

- `r` - 重新加载应用
- `m` - 切换菜单
- `shift+m` - 切换性能监视器

## 常见问题

### 1. Metro Bundler 缓存问题

**问题**: 代码更改后应用没有更新

**解决方案**:
```bash
npm start -- --clear
```

### 2. iOS 模拟器无法启动

**问题**: `xcrun simctl` 报错

**解决方案**:
```bash
# 重启模拟器服务
sudo killall -9 com.apple.CoreSimulator.CoreSimulatorService
# 重新打开 Xcode
open -a Simulator
```

### 3. WatermelonDB 同步问题

**问题**: 数据更新后 UI 没有刷新

**解决方案**:
- 确保使用 `withObservables` 或 React hooks 监听数据变化
- 使用 EventEmitter 发送变更通知:
```typescript
DataManager.on('transactionDidChange', () => {
  // 刷新UI
});
```

### 4. TypeScript 类型错误

**问题**: `Property 'xxx' does not exist on type...`

**解决方案**:
- 检查 `tsconfig.json` 路径别名配置
- 确保所有依赖的类型定义已安装:
```bash
npm install --save-dev @types/react @types/react-native
```

### 5. Expo Go 不支持某些功能

**问题**: 某些原生模块在 Expo Go 中无法使用

**解决方案**:
- 使用 Development Build:
```bash
npx expo run:ios
```

### 6. 字体图标不显示

**问题**: Ionicons 图标显示为方块

**解决方案**:
- 确保已正确加载字体:
```typescript
import * as Font from 'expo-font';
import Ionicons from 'react-native-vector-icons/Fonts/Ionicons.ttf';

await Font.loadAsync({
  Ionicons: Ionicons,
});
```

## 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 支持

如有问题，请提交 Issue 或联系开发团队。

---

**快乐编码！** 🚀
