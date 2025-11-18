#!/bin/bash

# AutoBookkeeping Xcode 项目快速设置脚本
# 用法：./setup-xcode-project.sh

set -e

echo "🚀 AutoBookkeeping Xcode 项目设置脚本"
echo "======================================"
echo ""

# 检查是否在 macOS 上运行
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ 错误：此脚本只能在 macOS 上运行"
    echo "   请在 Mac 电脑上执行此脚本"
    exit 1
fi

# 检查 Xcode 是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误：未检测到 Xcode"
    echo "   请先安装 Xcode："
    echo "   1. 打开 App Store"
    echo "   2. 搜索 'Xcode'"
    echo "   3. 点击'获取'并安装"
    echo ""
    echo "   或访问：https://developer.apple.com/xcode/"
    exit 1
fi

echo "✅ 检测到 Xcode："
xcodebuild -version
echo ""

# 设置变量
PROJECT_NAME="AutoBookkeeping"
BUNDLE_ID="com.yourcompany.autobookkeeping"
DEPLOYMENT_TARGET="17.0"

# 获取当前目录
CURRENT_DIR=$(pwd)
SOURCE_DIR="$CURRENT_DIR/AutoBookkeeping"
WIDGET_DIR="$CURRENT_DIR/BookkeepingWidget"

echo "📁 项目信息："
echo "   项目名称：$PROJECT_NAME"
echo "   Bundle ID：$BUNDLE_ID"
echo "   最低部署：iOS $DEPLOYMENT_TARGET"
echo "   源代码目录：$SOURCE_DIR"
echo ""

# 检查源代码目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ 错误：找不到 AutoBookkeeping 源代码目录"
    echo "   请确保在 Record-Money 项目根目录下运行此脚本"
    exit 1
fi

echo "📋 接下来将执行以下步骤："
echo "   1. 使用 xcodegen 创建 Xcode 项目（如果已安装）"
echo "   2. 或者提供手动创建项目的详细说明"
echo ""

# 检查是否安装了 xcodegen
if command -v xcodegen &> /dev/null; then
    echo "✅ 检测到 xcodegen"
    echo "   将自动生成 Xcode 项目..."
    echo ""

    # 生成项目（如果有 project.yml）
    if [ -f "project.yml" ]; then
        xcodegen generate
        echo "✅ Xcode 项目已生成！"
        echo ""
        echo "🎉 设置完成！"
        echo ""
        echo "📖 下一步："
        echo "   1. 双击打开 $PROJECT_NAME.xcodeproj"
        echo "   2. 选择模拟器（如 iPhone 15 Pro）"
        echo "   3. 点击运行按钮 ▶️ 或按 ⌘+R"
        echo ""
        exit 0
    fi
fi

echo "⚠️  未检测到 xcodegen 或 project.yml"
echo ""
echo "📝 请按照以下步骤在 Xcode 中手动创建项目："
echo ""
echo "════════════════════════════════════════════════════"
echo "第一步：创建新的 Xcode 项目"
echo "════════════════════════════════════════════════════"
echo ""
echo "1. 打开 Xcode"
echo "2. 点击 'Create a new Xcode project'"
echo "3. 选择模板："
echo "   - 平台：iOS"
echo "   - 类型：App"
echo "   - 点击 Next"
echo ""
echo "4. 项目配置："
echo "   - Product Name: AutoBookkeeping"
echo "   - Team: 选择你的 Apple ID（或 None）"
echo "   - Organization Identifier: com.yourcompany"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Storage: SwiftData"
echo "   - 取消勾选 Include Tests"
echo "   - 点击 Next"
echo ""
echo "5. 保存位置："
echo "   - 创建一个新文件夹（例如：~/Desktop/AutoBookkeeping-Xcode）"
echo "   - 勾选 'Create Git repository'"
echo "   - 点击 Create"
echo ""
echo "════════════════════════════════════════════════════"
echo "第二步：导入源代码"
echo "════════════════════════════════════════════════════"
echo ""
echo "1. 在 Xcode 左侧项目导航器中，删除自动生成的文件："
echo "   - 右键点击 Item.swift → Delete → Move to Trash"
echo ""
echo "2. 在 Finder 中打开此目录："
echo "   $SOURCE_DIR"
echo ""
echo "3. 将以下文件夹拖拽到 Xcode 项目中："
echo "   ✓ Models/"
echo "   ✓ Views/"
echo "   ✓ Services/"
echo "   ✓ Utilities/"
echo "   ✓ Intents/"
echo "   ✓ App/AutoBookkeepingApp.swift（替换现有的）"
echo ""
echo "4. 在弹出对话框中："
echo "   ✓ 勾选 'Copy items if needed'"
echo "   ✓ 勾选 'Create groups'"
echo "   ✓ Target: AutoBookkeeping"
echo "   ✓ 点击 Finish"
echo ""
echo "5. 导入 Resources："
echo "   - 将 Resources/Assets.xcassets 拖入项目"
echo "   - 勾选 'Copy items if needed'"
echo ""
echo "════════════════════════════════════════════════════"
echo "第三步：配置项目"
echo "════════════════════════════════════════════════════"
echo ""
echo "1. 设置部署目标："
echo "   - 选择项目 → TARGETS → AutoBookkeeping"
echo "   - General → Minimum Deployments → iOS 17.0"
echo ""
echo "2. 添加权限（Info.plist）："
echo "   - 找到 Info.plist"
echo "   - 添加以下权限："
echo "     * Privacy - Camera Usage Description"
echo "       值：需要使用相机扫描小票进行智能记账"
echo "     * Privacy - Photo Library Usage Description"
echo "       值：需要访问相册选择小票照片进行识别"
echo ""
echo "════════════════════════════════════════════════════"
echo "第四步：运行项目"
echo "════════════════════════════════════════════════════"
echo ""
echo "1. 选择模拟器："
echo "   - 顶部工具栏 → 选择 'iPhone 15 Pro'"
echo ""
echo "2. 点击运行："
echo "   - 点击 ▶️ 按钮"
echo "   - 或按 ⌘+R"
echo ""
echo "3. 等待编译（第一次需要 5-10 分钟）"
echo ""
echo "════════════════════════════════════════════════════"
echo ""
echo "📚 详细文档请查看："
echo "   $CURRENT_DIR/docs/GETTING_STARTED.md"
echo ""
echo "🆘 遇到问题？"
echo "   - 查看常见问题：docs/GETTING_STARTED.md#常见问题排查"
echo "   - 或搜索错误信息"
echo ""
echo "🎉 祝你成功启动项目！"
echo ""
