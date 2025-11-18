# OCR 小票扫描功能配置指南

## 功能概述

OCR 小票扫描功能使用 Apple Vision Framework 进行文字识别，支持：
- 📷 拍摄小票照片
- 📱 从相册选择图片
- 🔍 自动识别交易金额、商家、日期
- ✅ 智能填充交易表单
- 🌏 支持中文、英文识别
- 🔒 完全离线，隐私安全

## 必需权限配置

在 Xcode 项目中添加以下隐私权限：

### 1. Info.plist 配置

打开项目的 `Info.plist` 文件（或在 Xcode Project Settings > Info 中添加），添加以下键值对：

```xml
<!-- 相机权限 -->
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄小票进行 OCR 识别</string>

<!-- 相册权限 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册选择小票图片进行 OCR 识别</string>
```

### 2. Xcode 项目设置

1. 打开 Xcode 项目
2. 选择项目 Target > Info 标签页
3. 添加 Custom iOS Target Properties：
   - **Privacy - Camera Usage Description**: "需要使用相机拍摄小票进行 OCR 识别"
   - **Privacy - Photo Library Usage Description**: "需要访问相册选择小票图片进行 OCR 识别"

## 功能实现文件

### 核心服务
- `AutoBookkeeping/Services/OCRManager.swift` - Vision Framework 封装
- `AutoBookkeeping/Services/ReceiptParser.swift` - 小票文本解析器

### UI 视图
- `AutoBookkeeping/Views/Receipt/ReceiptScannerView.swift` - 扫描主界面
- `AutoBookkeeping/Views/Receipt/ImagePicker.swift` - 图片选择器

### 集成点
- `AutoBookkeeping/Views/Transaction/TransactionListView.swift` - 工具栏扫描按钮

## 使用流程

1. 用户点击交易列表右上角的 **扫描按钮** (📄🔍)
2. 选择拍摄新照片或从相册选择
3. 点击 "开始识别" 进行 OCR 处理
4. 系统自动解析：
   - 金额（支持多种格式：¥、RMB、元等）
   - 商家名称（小票前几行）
   - 交易日期（多种日期格式）
   - 商品明细（带价格的行）
5. 确认并补充信息
6. 保存到交易记录

## 支持的小票格式

### 金额识别
- ✅ `合计：123.45`
- ✅ `总计¥123.45`
- ✅ `实付：RMB 123.45`
- ✅ `123.45元`

### 日期识别
- ✅ `2024-01-15 14:30:00`
- ✅ `2024/01/15 14:30`
- ✅ `2024年01月15日 14:30`

### 商家识别
- 自动从小票前 5 行提取
- 排除常见无效关键词（小票、发票、收据等）
- 过滤纯数字和日期行

## 技术特性

### 零成本
- ✅ 使用 Apple 原生 Vision Framework
- ✅ 无需任何云服务订阅
- ✅ 无 API 调用费用

### 隐私安全
- ✅ 完全离线处理
- ✅ 数据不上传到云端
- ✅ 符合中国隐私法规

### 高准确度
- 使用 `VNRecognizeTextRequest` 最高精度模式
- 支持简体中文、繁体中文、英文
- 启用语言纠错功能

## 常见问题

### Q: 识别失败怎么办？
A: 确保小票照片：
- 光线充足，避免反光
- 文字清晰可见
- 拍摄角度垂直
- 小票平整无褶皱

### Q: 识别结果不准确？
A: OCR 识别后会进入确认界面，可以手动修正：
- 金额
- 商家名称
- 交易分类
- 日期时间

### Q: 支持哪些语言？
A: 当前支持：
- 简体中文 (zh-Hans)
- 繁体中文 (zh-Hant)
- 英文 (en-US)

### Q: 是否需要网络连接？
A: 完全不需要！所有 OCR 处理都在设备本地完成。

## 性能优化

- OCR 处理异步执行，不阻塞 UI
- 识别过程中显示加载指示器
- 触觉反馈增强用户体验
- 错误处理完善，提示友好

## 未来优化方向

1. **批量扫描** - 一次识别多张小票
2. **历史记录** - 保存扫描过的小票图片
3. **模板学习** - 识别常去商家的小票格式
4. **置信度显示** - 显示识别准确度
5. **自动分类** - 结合 CoreML 智能分类

## 相关文档

- [AI 功能总体规划](./AI_FEATURES_PLAN_CN.md)
- [UX 优化计划](./UX_FIRST_IMPLEMENTATION_PLAN.md)
- [功能优化计划](./APP_OPTIMIZATION_PLAN.md)
