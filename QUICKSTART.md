# 快速开始指南

## 🚀 5 分钟启动 React Native 版本

### 第一步：安装依赖

```bash
# 确保你已安装 Node.js (>= 18.0.0)
node --version

# 安装项目依赖
npm install

# 或使用 yarn
yarn install
```

### 第二步：启动开发服务器

```bash
# 启动 Expo 开发服务器
npm start
```

这将打开 Expo 开发者工具，你会看到一个二维码。

### 第三步：在设备上运行

**选项 A：使用 iOS 模拟器**

```bash
# 确保已安装 Xcode
npm run ios
```

**选项 B：使用真机（推荐）**

1. 在手机上安装 **Expo Go** App
   - iOS: [App Store](https://apps.apple.com/app/expo-go/id982107779)
   - Android: [Google Play](https://play.google.com/store/apps/details?id=host.exp.exponent)

2. 扫描终端中的二维码

3. 应用将自动在手机上启动

**选项 C：使用 Android 模拟器**

```bash
# 确保已安装 Android Studio
npm run android
```

## 📱 首次使用

### 应用会自动初始化

1. **默认分类**：首次启动时会自动创建 8 个默认分类
   - 餐饮、交通、购物、娱乐、生活、医疗、教育、其他

2. **空数据**：初始没有任何交易记录

3. **导航结构**：
   - 📝 **记录** - 查看所有交易记录
   - 📊 **统计** - 查看支出收入统计
   - ⚙️ **设置** - 管理分类、预算和数据

### 测试智能分类

打开 **记录** 标签，尝试添加一笔交易（需要先实现添加界面）：

```javascript
// 智能分类引擎会自动识别：
商家: "星巴克" → 分类: "餐饮"
商家: "滴滴出行" → 分类: "交通"
商家: "淘宝" → 分类: "购物"
```

## 🔧 开发工具

### 查看数据库

React Native 使用 WatermelonDB，数据存储在本地 SQLite 数据库中。

```bash
# iOS 模拟器数据位置
~/Library/Developer/CoreSimulator/Devices/{DEVICE_ID}/data/Containers/Data/Application/{APP_ID}/Documents/

# Android 模拟器
adb shell
run-as com.yourdomain.recordmoney
cd databases/
```

### 调试工具

- **React DevTools**: 自动启动
- **Expo DevTools**: 在浏览器中打开
- **日志查看**:
  ```bash
  # iOS
  npx react-native log-ios

  # Android
  npx react-native log-android
  ```

### 热重载

Expo 支持快速刷新（Fast Refresh）：

- **保存文件** → 自动重载
- **摇晃设备** → 打开开发菜单
- **按 `r`** → 手动重载

## 📝 添加第一笔测试数据

当前版本可以通过代码添加测试数据：

```typescript
// 在 TransactionListScreen.tsx 中添加测试数据
import DataManager from '../../services/DataManager';

// 添加测试交易
await DataManager.saveTransaction({
  amount: 35.0,
  merchant: '星巴克',
  categoryName: '餐饮',
  type: 'expense',
  paymentMethod: '微信支付',
  timestamp: new Date(),
});
```

## 🎯 下一步

现在你可以：

1. ✅ 查看交易列表
2. ✅ 查看统计分析
3. ✅ 管理设置

待实现功能：

- [ ] 添加交易界面（点击 + 按钮）
- [ ] 编辑交易
- [ ] 预算管理
- [ ] OCR 扫描小票
- [ ] 自然语言输入

## ❓ 常见问题

### Q: 如何清除所有数据？

A: 进入 **设置** → **清除所有数据**

### Q: 智能分类不准确怎么办？

A: 分类引擎会从你的修正中学习。修正分类后，下次相同商家会自动使用正确分类。

### Q: 如何添加自定义分类？

A: 当前版本需要通过代码添加，UI 界面正在开发中。

### Q: 数据会同步到云端吗？

A: 当前版本所有数据都存储在本地设备，保证隐私安全。未来可能会添加 iCloud 同步功能。

### Q: 支持 Android 吗？

A: 代码已经支持跨平台，但主要针对 iOS 设计。Android 版本需要额外的 UI 调整。

## 🐛 遇到问题？

1. **清除缓存**
   ```bash
   expo start -c
   ```

2. **重新安装依赖**
   ```bash
   rm -rf node_modules
   npm install
   ```

3. **检查 Node 版本**
   ```bash
   node --version  # 应该 >= 18.0.0
   ```

4. **查看日志**
   ```bash
   npm start
   # 然后在终端查看错误信息
   ```

## 📚 更多资源

- [Expo 文档](https://docs.expo.dev/)
- [React Native 文档](https://reactnative.dev/)
- [WatermelonDB 文档](https://nozbe.github.io/WatermelonDB/)
- [项目详细文档](./README_RN.md)

---

**祝你使用愉快！** 🎉

如有问题，请查看 [README_RN.md](./README_RN.md) 获取更详细的信息。
