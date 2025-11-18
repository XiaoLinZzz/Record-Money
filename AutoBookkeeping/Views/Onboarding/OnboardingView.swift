//
//  OnboardingView.swift
//  AutoBookkeeping
//
//  用户引导视图
//

import SwiftUI

struct OnboardingView: View {

    // MARK: - Properties

    let onComplete: () -> Void

    // MARK: - State

    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        TabView(selection: $currentPage) {
            // 第 1 页：欢迎
            WelcomePage()
                .tag(0)

            // 第 2 页：功能介绍
            FeaturesPage()
                .tag(1)

            // 第 3 页：快捷指令配置
            ShortcutSetupPage()
                .tag(2)

            // 第 4 页：完成
            CompletionPage(onComplete: {
                onComplete()
                dismiss()
            })
            .tag(3)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "sparkles")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 12) {
                Text("欢迎使用无感记账")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("让记账变得像呼吸一样自然")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Text("向左滑动继续")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
        .padding()
    }
}

// MARK: - Features Page

struct FeaturesPage: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("核心功能")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 30) {
                FeatureCard(
                    icon: "wand.and.stars",
                    title: "自动记账",
                    description: "支付完成后自动记录，无需手动操作",
                    color: .blue
                )

                FeatureCard(
                    icon: "brain",
                    title: "智能分类",
                    description: "AI 自动识别消费类型，越用越准确",
                    color: .purple
                )

                FeatureCard(
                    icon: "lock.shield",
                    title: "隐私安全",
                    description: "所有数据本地处理，不上传云端",
                    color: .green
                )

                FeatureCard(
                    icon: "chart.bar",
                    title: "数据统计",
                    description: "清晰了解消费习惯和趋势",
                    color: .orange
                )
            }

            Spacer()
        }
        .padding()
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Shortcut Setup Page

struct ShortcutSetupPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("配置快捷指令")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("完成一次性配置，即可实现自动记账")
                        .foregroundColor(.secondary)
                }

                // 步骤列表
                VStack(alignment: .leading, spacing: 20) {
                    SetupStep(
                        number: 1,
                        title: "打开快捷指令 App",
                        description: "在 iPhone 上找到并打开"快捷指令" App"
                    )

                    SetupStep(
                        number: 2,
                        title: "创建自动化",
                        description: "点击"自动化"标签 → 点击"+" → 选择"创建个人自动化""
                    )

                    SetupStep(
                        number: 3,
                        title: "设置触发条件",
                        description: """
                        • 选择 "App"
                        • 选择"微信"或"支付宝"
                        • 触发时机: "已打开"
                        """
                    )

                    SetupStep(
                        number: 4,
                        title: "添加操作",
                        description: """
                        1. 等待 1 秒
                        2. 对屏幕截图
                        3. 从图像获取文本
                        4. 搜索并添加"添加交易记录" Intent
                        5. 配置参数（金额、商家等）
                        """
                    )

                    SetupStep(
                        number: 5,
                        title: "完成设置",
                        description: "关闭"运行前询问"，保存自动化"
                    )
                }

                // 提示信息
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("首次使用时，iOS 会请求权限，请点击"允许"")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                    }

                    Label {
                        Text("详细配置教程请查看设置页面")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "book.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()
            }
            .padding()
        }
    }
}

struct SetupStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 数字图标
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Completion Page

struct CompletionPage: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("一切准备就绪！")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("现在开始享受无感记账吧")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("开始使用")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView {}
}
