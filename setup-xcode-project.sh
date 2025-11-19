#!/bin/bash

# AutoBookkeeping Xcode 项目自动化设置脚本
# 用法：./setup-xcode-project.sh [--auto-install]
#   --auto-install: 自动安装 Homebrew 和 xcodegen（需要确认）

set -e

echo "🚀 AutoBookkeeping Xcode 项目自动化设置脚本"
echo "================================================"
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

# 检查 project.yml 是否存在
if [ ! -f "project.yml" ]; then
    echo "❌ 错误：找不到 project.yml 配置文件"
    echo "   此文件应该已经在仓库中提供"
    exit 1
fi

# 函数：安装 Homebrew
install_homebrew() {
    echo ""
    echo "📦 正在安装 Homebrew..."
    echo "   这可能需要几分钟，请耐心等待..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 添加 Homebrew 到 PATH（针对 Apple Silicon Mac）
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    echo "✅ Homebrew 安装完成！"
}

# 函数：安装 xcodegen
install_xcodegen() {
    echo ""
    echo "📦 正在安装 xcodegen..."
    brew install xcodegen
    echo "✅ xcodegen 安装完成！"
}

echo "📋 检查依赖工具..."
echo ""

# 检查 Homebrew
NEED_HOMEBREW=false
if ! command -v brew &> /dev/null; then
    echo "⚠️  未检测到 Homebrew（macOS 包管理器）"
    NEED_HOMEBREW=true
else
    echo "✅ 检测到 Homebrew: $(brew --version | head -n 1)"
fi

# 检查 xcodegen
NEED_XCODEGEN=false
if ! command -v xcodegen &> /dev/null; then
    echo "⚠️  未检测到 xcodegen（Xcode 项目生成工具）"
    NEED_XCODEGEN=true
else
    echo "✅ 检测到 xcodegen: $(xcodegen --version)"
fi

echo ""

# 如果需要安装工具
if [ "$NEED_HOMEBREW" = true ] || [ "$NEED_XCODEGEN" = true ]; then
    # 检查是否有 --auto-install 参数
    if [[ "$1" == "--auto-install" ]]; then
        AUTO_INSTALL=true
    else
        echo "════════════════════════════════════════════════════"
        echo "需要安装以下工具才能自动生成 Xcode 项目："
        echo "════════════════════════════════════════════════════"
        [ "$NEED_HOMEBREW" = true ] && echo "  • Homebrew (包管理器)"
        [ "$NEED_XCODEGEN" = true ] && echo "  • xcodegen (项目生成工具)"
        echo ""
        echo "这些工具完全免费且开源，安装后可以大大简化 Xcode 项目配置。"
        echo ""
        read -p "是否要自动安装这些工具？(y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            AUTO_INSTALL=true
        else
            AUTO_INSTALL=false
        fi
    fi

    if [ "$AUTO_INSTALL" = true ]; then
        # 安装 Homebrew
        if [ "$NEED_HOMEBREW" = true ]; then
            install_homebrew
        fi

        # 安装 xcodegen
        if [ "$NEED_XCODEGEN" = true ]; then
            install_xcodegen
        fi

        echo ""
        echo "✅ 所有依赖工具已安装完成！"
        echo ""
    else
        echo ""
        echo "⚠️  跳过自动安装。你可以手动安装："
        echo ""
        if [ "$NEED_HOMEBREW" = true ]; then
            echo "1. 安装 Homebrew："
            echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            echo ""
        fi
        if [ "$NEED_XCODEGEN" = true ]; then
            echo "2. 安装 xcodegen："
            echo "   brew install xcodegen"
            echo ""
        fi
        echo "安装完成后，重新运行此脚本："
        echo "   ./setup-xcode-project.sh"
        echo ""
        exit 0
    fi
fi

# 开始生成项目
echo "════════════════════════════════════════════════════"
echo "🔨 正在生成 Xcode 项目..."
echo "════════════════════════════════════════════════════"
echo ""

# 如果已存在项目文件，先备份
if [ -d "$PROJECT_NAME.xcodeproj" ]; then
    BACKUP_NAME="$PROJECT_NAME.xcodeproj.backup.$(date +%Y%m%d_%H%M%S)"
    echo "⚠️  检测到已存在的项目文件，将备份为："
    echo "   $BACKUP_NAME"
    mv "$PROJECT_NAME.xcodeproj" "$BACKUP_NAME"
    echo ""
fi

# 运行 xcodegen
if xcodegen generate; then
    echo ""
    echo "✅ Xcode 项目生成成功！"
    echo ""
else
    echo ""
    echo "❌ 项目生成失败"
    echo "   请检查 project.yml 文件是否正确"
    exit 1
fi

# 检查生成的项目文件
if [ ! -d "$PROJECT_NAME.xcodeproj" ]; then
    echo "❌ 错误：项目文件未生成"
    exit 1
fi

echo "════════════════════════════════════════════════════"
echo "🎉 设置完成！"
echo "════════════════════════════════════════════════════"
echo ""
echo "✅ Xcode 项目已自动配置完成，包括："
echo "   • 主应用 (AutoBookkeeping)"
echo "   • Widget 扩展 (BookkeepingWidget)"
echo "   • App Groups 共享数据"
echo "   • Siri & App Intents 支持"
echo "   • 相机和相册权限配置"
echo ""
echo "📖 下一步操作："
echo ""
echo "1️⃣  打开项目："
echo "   双击打开：$PROJECT_NAME.xcodeproj"
echo "   或运行命令：open $PROJECT_NAME.xcodeproj"
echo ""
echo "2️⃣  配置签名（⚠️ 必须手动配置）："
echo "   • 点击项目 → TARGETS → AutoBookkeeping"
echo "   • Signing & Capabilities 标签页"
echo "   • Team: 选择你的 Apple ID（或 None 用于模拟器）"
echo "   • 对 BookkeepingWidget target 重复以上步骤"
echo ""
echo "3️⃣  自定义 Bundle ID（可选）："
echo "   如果需要修改默认的 Bundle ID (com.yourcompany.autobookkeeping)："
echo "   • 编辑 project.yml 文件"
echo "   • 修改 bundleIdPrefix 字段"
echo "   • 重新运行此脚本"
echo ""
echo "4️⃣  选择模拟器并运行："
echo "   • 顶部工具栏选择设备（推荐：iPhone 15 Pro）"
echo "   • 点击 ▶️ 按钮或按 ⌘+R"
echo "   • 首次编译需要 5-10 分钟，请耐心等待"
echo ""
echo "════════════════════════════════════════════════════"
echo ""
echo "📚 详细文档："
echo "   • 快速开始：$CURRENT_DIR/README.md"
echo "   • 配置指南：$CURRENT_DIR/docs/XCODE_SETUP.md"
echo "   • 常见问题：$CURRENT_DIR/docs/FAQ.md"
echo ""
echo "💡 提示："
echo "   • 如需重新生成项目，再次运行此脚本即可"
echo "   • 旧项目会自动备份，文件名带时间戳"
echo "   • 修改 project.yml 后需要重新运行脚本"
echo ""
echo "🆘 遇到问题？"
echo "   • 检查 Xcode 版本是否 >= 15.0"
echo "   • 确保 macOS 版本 >= 14.0 (Sonoma)"
echo "   • 查看详细错误信息并搜索解决方案"
echo ""
echo "🎉 祝你开发愉快！"
echo ""
