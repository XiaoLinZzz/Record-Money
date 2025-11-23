# Record Money - 部署文档

本文档提供完整的 iOS 应用构建和部署指南，从开发环境配置到 App Store 发布。

## 📋 目录

- [环境准备](#环境准备)
- [配置应用](#配置应用)
- [本地构建](#本地构建)
- [使用 EAS Build 云构建](#使用-eas-build-云构建)
- [TestFlight 测试](#testflight-测试)
- [App Store 发布](#app-store-发布)
- [持续集成/部署](#持续集成部署)
- [故障排除](#故障排除)

## 环境准备

### 1. Apple 开发者账号

**必需**: Apple Developer Program 会员资格（$99/年）

- 访问 [https://developer.apple.com](https://developer.apple.com)
- 注册或登录 Apple Developer 账号
- 完成会员注册流程

### 2. 开发工具

确保安装以下工具：

```bash
# 检查 Node.js 版本 (需要 >= 18.0)
node --version

# 检查 npm 版本
npm --version

# 安装 Expo CLI (全局)
npm install -g expo-cli

# 安装 EAS CLI (用于云构建)
npm install -g eas-cli
```

### 3. Xcode 配置

1. **安装 Xcode** (从 Mac App Store)
   - 版本要求: >= 15.0

2. **安装命令行工具**:
```bash
xcode-select --install
```

3. **接受许可协议**:
```bash
sudo xcodebuild -license accept
```

### 4. 证书和配置文件

#### 自动管理（推荐）

使用 EAS Build 自动管理证书：

```bash
# 登录 Expo 账号
eas login

# 配置项目
eas build:configure
```

#### 手动管理

1. **访问 Apple Developer Portal**
   - 登录 [https://developer.apple.com/account](https://developer.apple.com/account)

2. **创建 App ID**
   - Certificates, Identifiers & Profiles → Identifiers → +
   - 选择 "App IDs" → Continue
   - 输入描述和 Bundle ID: `com.yourdomain.recordmoney`
   - 启用所需功能 (Push Notifications, App Groups等)

3. **创建证书**
   - Certificates → + → iOS Distribution
   - 生成 CSR (Certificate Signing Request)
   - 上传 CSR 并下载证书

4. **创建 Provisioning Profile**
   - Profiles → + → App Store
   - 选择 App ID 和证书
   - 下载并安装 profile

## 配置应用

### 1. 应用信息配置

编辑 `app.json`:

```json
{
  "expo": {
    "name": "Record Money",
    "slug": "record-money",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "ios": {
      "supportsTablet": false,
      "bundleIdentifier": "com.yourdomain.recordmoney",
      "buildNumber": "1",
      "infoPlist": {
        "NSCameraUsageDescription": "需要访问相机以扫描小票",
        "NSPhotoLibraryUsageDescription": "需要访问相册以选择小票图片",
        "NSUserTrackingUsageDescription": "用于提供个性化记账体验"
      },
      "entitlements": {
        "com.apple.developer.applesignin": ["Default"],
        "com.apple.security.application-groups": [
          "group.com.yourdomain.recordmoney"
        ]
      }
    },
    "extra": {
      "eas": {
        "projectId": "your-project-id"
      }
    }
  }
}
```

### 2. EAS 构建配置

创建 `eas.json`:

```json
{
  "cli": {
    "version": ">= 5.0.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": true
      }
    },
    "preview": {
      "distribution": "internal",
      "ios": {
        "simulator": false
      }
    },
    "production": {
      "autoIncrement": true,
      "env": {
        "NODE_ENV": "production"
      },
      "ios": {
        "simulator": false
      }
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "your-apple-id@email.com",
        "ascAppId": "1234567890",
        "appleTeamId": "ABCD123456"
      }
    }
  }
}
```

### 3. 环境变量

创建 `.env` 文件（不要提交到 git）:

```env
# API 配置（如果有后端服务）
API_URL=https://api.example.com
API_KEY=your_api_key

# Sentry（错误追踪）
SENTRY_DSN=your_sentry_dsn

# Analytics
ANALYTICS_KEY=your_analytics_key
```

## 本地构建

### 使用 Expo

1. **开发构建**

```bash
# 在模拟器中运行
npx expo run:ios

# 指定模拟器
npx expo run:ios --device "iPhone 15 Pro"
```

2. **预览构建**

```bash
# 创建预览版本
npx expo build:ios --type archive
```

### 使用 Xcode

1. **生成 iOS 项目**

```bash
npx expo prebuild --platform ios
```

2. **在 Xcode 中打开**

```bash
open ios/RecordMoney.xcworkspace
```

3. **配置签名**
   - 在 Xcode 中选择 Target → Signing & Capabilities
   - 选择 Team
   - 确认 Bundle Identifier

4. **构建**
   - Product → Archive
   - 等待构建完成

## 使用 EAS Build 云构建

### 1. 初始化 EAS

```bash
# 登录 Expo 账号
eas login

# 配置项目
eas build:configure
```

### 2. 开发构建

```bash
# 构建开发版本（支持本地调试）
eas build --profile development --platform ios

# 在模拟器中构建
eas build --profile development --platform ios --simulator
```

### 3. 预览构建

```bash
# 构建 AdHoc 版本（TestFlight 之前的内部测试）
eas build --profile preview --platform ios
```

### 4. 生产构建

```bash
# 构建 App Store 版本
eas build --profile production --platform ios
```

### 5. 检查构建状态

```bash
# 查看构建列表
eas build:list

# 查看特定构建的日志
eas build:view [build-id]
```

### 6. 下载构建

构建完成后，可以：

1. **从 Expo 网站下载**
   - 访问 [https://expo.dev](https://expo.dev)
   - 选择项目 → Builds
   - 下载 `.ipa` 文件

2. **使用命令行下载**
```bash
# 下载最新构建
eas build:download --platform ios
```

## TestFlight 测试

### 1. 上传到 App Store Connect

#### 使用 EAS Submit

```bash
# 自动提交到 App Store Connect
eas submit --platform ios --latest
```

#### 手动上传

1. **使用 Transporter 应用**
   - 从 Mac App Store 下载 Transporter
   - 打开应用并登录
   - 拖拽 `.ipa` 文件到窗口
   - 点击 "交付"

2. **使用命令行**
```bash
xcrun altool --upload-app --type ios --file path/to/app.ipa \
  --username "your-apple-id@email.com" \
  --password "@keychain:Application Loader"
```

### 2. 配置 TestFlight

1. **访问 App Store Connect**
   - 登录 [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - 选择你的应用

2. **TestFlight 标签**
   - 等待构建处理完成（通常 10-30 分钟）
   - 添加测试信息（What to Test）
   - 配置测试人员群组

3. **添加内部测试人员**
   - TestFlight → Internal Testing
   - 添加用户 → App Store Connect Users
   - 最多 100 个内部测试人员

4. **添加外部测试人员**
   - TestFlight → External Testing
   - 创建新组并添加测试人员
   - 需要 Beta App Review（1-2 天）

### 3. 测试人员安装

测试人员将收到邮件邀请：

1. 在 iOS 设备上安装 TestFlight 应用
2. 打开邮件中的邀请链接
3. 在 TestFlight 中接受邀请
4. 点击"安装"按钮

## App Store 发布

### 1. 准备发布资源

#### 应用截图

需要为不同设备尺寸准备截图：

- **6.7" Display** (iPhone 15 Pro Max): 1290 x 2796 px
- **6.5" Display** (iPhone 14 Plus): 1284 x 2778 px
- **5.5" Display** (iPhone 8 Plus): 1242 x 2208 px

工具推荐:
- [Figma](https://www.figma.com) - 设计截图
- [App Store Screenshot Generator](https://www.appscreenshot.com) - 自动生成

#### 应用图标

- **尺寸**: 1024 x 1024 px
- **格式**: PNG (无透明度)
- **颜色空间**: RGB

#### 预览视频（可选）

- **时长**: 15-30 秒
- **格式**: MP4 或 MOV
- **分辨率**: 与截图相同

### 2. App Store Connect 配置

1. **应用信息**
   - 名称: "Record Money" (最多 30 字符)
   - 副标题: "智能记账助手" (最多 30 字符)
   - 分类: 财务
   - 内容分级: 4+

2. **定价与销售范围**
   - 价格: 免费或设置价格
   - 销售国家/地区: 选择目标市场

3. **版本信息**
   - 版本号: 1.0.0
   - 更新说明: 首次发布
   - 关键词: 记账,预算,财务,支出,收入 (最多 100 字符)
   - 描述: 详细的应用功能介绍 (最多 4000 字符)
   - 推广文本: 简短介绍 (最多 170 字符)

4. **上传资源**
   - 应用截图（每种尺寸至少1张，最多10张）
   - 应用图标
   - 预览视频（可选）

5. **App 隐私**
   - 隐私政策 URL: https://yourwebsite.com/privacy
   - 数据收集说明:
     - 财务信息 (收集但不关联用户)
     - 使用数据 (用于分析)

### 3. 提交审核

1. **最终检查清单**
   - [ ] 所有截图已上传
   - [ ] 应用图标正确
   - [ ] 隐私政策 URL 有效
   - [ ] 版本信息完整
   - [ ] 构建已选择
   - [ ] 出口合规性已回答

2. **提交**
   - 点击 "提交以供审核"
   - 确认所有信息
   - 等待审核（通常 1-3 天）

### 4. 审核状态

- **Waiting For Review**: 等待审核
- **In Review**: 正在审核
- **Pending Developer Release**: 审核通过，等待发布
- **Ready for Sale**: 已发布到 App Store
- **Rejected**: 被拒绝（需要修改并重新提交）

### 5. 审核被拒处理

常见拒绝原因：

1. **崩溃或Bug**:
   - 修复问题
   - 重新构建并提交

2. **元数据问题**:
   - 修改描述、截图等
   - 无需重新构建

3. **隐私问题**:
   - 更新隐私政策
   - 添加用户同意流程

4. **性能问题**:
   - 优化应用启动时间
   - 减少网络请求

## 持续集成/部署

### GitHub Actions 示例

创建 `.github/workflows/eas-build.yml`:

```yaml
name: EAS Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    name: Build iOS App
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: 18.x
          cache: npm

      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          expo-version: latest
          eas-version: latest
          token: ${{ secrets.EXPO_TOKEN }}

      - name: Install dependencies
        run: npm ci

      - name: Build on EAS
        run: eas build --platform ios --profile production --non-interactive
```

### 自动化发布流程

```yaml
name: Deploy to App Store

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Expo
        uses: expo/expo-github-action@v8
        with:
          token: ${{ secrets.EXPO_TOKEN }}

      - name: Build
        run: eas build --platform ios --profile production --non-interactive

      - name: Submit to App Store
        run: eas submit --platform ios --latest --non-interactive
```

## 故障排除

### 构建失败

#### 1. 签名错误

**错误**: `Code signing error` 或 `Provisioning profile not found`

**解决方案**:
```bash
# 清除 EAS 凭证缓存
eas credentials

# 选择 iOS → Production → Remove all credentials
# 然后重新构建，EAS 会重新生成
```

#### 2. 依赖问题

**错误**: `Module not found` 或 `Cannot find module`

**解决方案**:
```bash
# 清除缓存
rm -rf node_modules package-lock.json
npm install

# 清除 Expo 缓存
npx expo start --clear
```

#### 3. 构建超时

**错误**: `Build timed out`

**解决方案**:
- 检查 `eas.json` 中的资源配置
- 减少依赖包大小
- 优化构建脚本

### 上传失败

#### 1. Apple ID 认证失败

**错误**: `Authentication failed`

**解决方案**:
```bash
# 使用应用专用密码
# 1. 访问 appleid.apple.com
# 2. 生成应用专用密码
# 3. 在 eas.json 中配置或使用环境变量
```

#### 2. 版本号冲突

**错误**: `A build with this version already exists`

**解决方案**:
- 在 `app.json` 中增加 `buildNumber`
- 或在 `eas.json` 中启用 `autoIncrement: true`

### 审核问题

#### 1. Guideline 2.1 - Performance

**原因**: 应用崩溃或性能问题

**解决方案**:
- 使用 Sentry 或 Crashlytics 追踪崩溃
- 优化启动时间（< 2秒）
- 测试所有功能

#### 2. Guideline 5.1.1 - Privacy

**原因**: 隐私政策不完整

**解决方案**:
- 提供详细的隐私政策 URL
- 在应用中添加数据使用说明
- 获取必要的用户同意

## 版本更新流程

### 1. 准备更新

```bash
# 更新版本号
# 编辑 app.json:
{
  "expo": {
    "version": "1.1.0",
    "ios": {
      "buildNumber": "2"
    }
  }
}
```

### 2. 构建新版本

```bash
# 构建
eas build --profile production --platform ios

# 提交
eas submit --platform ios --latest
```

### 3. App Store Connect 配置

1. 创建新版本
2. 添加更新说明
3. 选择新构建
4. 提交审核

### 4. 分阶段发布（可选）

- App Store Connect → 版本 → 分阶段发布
- 设置百分比: 1% → 5% → 10% → 50% → 100%
- 监控崩溃率和用户反馈

## 监控和分析

### 推荐工具

1. **Crashlytics**: 崩溃报告
```bash
npm install @react-native-firebase/crashlytics
```

2. **Sentry**: 错误追踪
```bash
npm install @sentry/react-native
```

3. **Firebase Analytics**: 用户分析
```bash
npm install @react-native-firebase/analytics
```

4. **App Store Connect Analytics**: 下载和收入数据
   - 访问 App Store Connect → Analytics

## 最佳实践

### 发布前检查清单

- [ ] 所有功能测试通过
- [ ] 在真实设备上测试
- [ ] 性能优化（启动时间、内存使用）
- [ ] 本地化完成（如需多语言）
- [ ] 隐私政策更新
- [ ] 截图和描述准确反映应用
- [ ] 版本号正确递增
- [ ] 备份源代码和构建文件

### 发布后监控

- 监控崩溃率（< 1%）
- 查看用户评分和评论
- 追踪关键指标（DAU, 留存率）
- 准备快速修复严重 bug

---

**祝发布顺利！** 🎉

如有问题，请参考 [Expo 官方文档](https://docs.expo.dev) 或联系开发团队。
