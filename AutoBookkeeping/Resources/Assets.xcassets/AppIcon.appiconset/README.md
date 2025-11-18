# App Icon Assets

## 📁 目录说明

此目录包含 AutoBookkeeping App 的应用图标资源。

## 🎨 图标设计方案

请参考：`/docs/APP_ICON_DESIGN.md`

推荐方案：**智能账本图标**
- 绿色渐变背景 (#34C759 → #30D158)
- 白色账本 + ¥ 符号
- 金色星星点缀（体现 AI 功能）

## 📐 所需尺寸

根据 `Contents.json` 配置，需要以下尺寸的 PNG 图片：

| 文件名 | 尺寸 | 用途 |
|--------|------|------|
| AppIcon-1024.png | 1024×1024 | App Store |
| AppIcon-60@3x.png | 180×180 | iPhone 主屏幕 @3x |
| AppIcon-60@2x.png | 120×120 | iPhone 主屏幕 @2x |
| AppIcon-76@2x.png | 152×152 | iPad 主屏幕 @2x |
| AppIcon-76.png | 76×76 | iPad 主屏幕 @1x |
| AppIcon-83.5@2x.png | 167×167 | iPad Pro 主屏幕 |
| AppIcon-40@3x.png | 120×120 | iPhone Spotlight @3x |
| AppIcon-40@2x.png | 80×80 | iPhone/iPad Spotlight @2x |
| AppIcon-29@3x.png | 87×87 | iPhone 设置 @3x |
| AppIcon-29@2x.png | 58×58 | iPhone/iPad 设置 @2x |
| AppIcon-20@3x.png | 60×60 | iPhone 通知 @3x |
| AppIcon-20@2x.png | 40×40 | iPhone/iPad 通知 @2x |

## 🚀 使用方法

### 方法 1: 使用在线生成工具（推荐）

1. 设计一个 1024×1024 的主图标
2. 访问 https://appicon.co 或 https://icon.kitchen
3. 上传主图标
4. 下载生成的所有尺寸
5. 将所有图片放入此目录

### 方法 2: 使用 Xcode Single Size（iOS 13+）

1. 只准备 1024×1024 的图标
2. 在 Xcode 中：
   - 选择 Assets.xcassets → AppIcon
   - 勾选 "Single Size"
   - 只拖入 1024×1024 图标
3. Xcode 会自动生成其他尺寸

### 方法 3: 使用 SwiftUI 预览生成

可以使用 `/docs/APP_ICON_DESIGN.md` 中的 SwiftUI 代码：
1. 创建预览视图
2. 截图保存为 1024×1024
3. 使用方法 1 或 2 生成其他尺寸

## ⚠️ 注意事项

- 图标必须是 **PNG 格式**
- 必须是 **RGB 色彩空间**（不要用 CMYK）
- **不能有透明通道**（背景必须不透明）
- **不要自己加圆角**（iOS 系统会自动添加）
- **边缘留白** 10% 以避免被圆角裁切
- **无文字**（不要在图标中包含 App 名称）

## 📊 当前状态

**状态**: ⚠️ 待添加图标文件

请按照上述方法生成图标并添加到此目录。

---

**快速生成建议**:
使用 AI 工具（如 Midjourney、DALL-E）快速生成，提示词见 `/docs/APP_ICON_DESIGN.md`
