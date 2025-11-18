//
//  SettingsView.swift
//  AutoBookkeeping
//
//  设置视图
//

import SwiftUI

struct SettingsView: View {

    // MARK: - State

    @State private var showOnboarding = false
    @State private var showAbout = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // 快捷指令配置
                Section("快捷指令") {
                    // 一键添加快捷指令（推荐）
                    Link(destination: URL(string: "https://www.icloud.com/shortcuts/YOUR_SHORTCUT_ID")!) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("一键添加快捷指令")
                                    .foregroundColor(.primary)
                                Text("推荐：快速完成配置")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    Button {
                        showOnboarding = true
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.blue)
                            Text("手动配置引导")
                        }
                    }

                    Link(destination: URL(string: "shortcuts://")!) {
                        HStack {
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundColor(.orange)
                            Text("打开快捷指令 App")
                        }
                    }
                } header: {
                    Text("快捷指令")
                } footer: {
                    Text("建议使用"一键添加"，系统会自动下载并配置好所有参数。首次使用时，iOS 会请求截图和通知权限，请点击"允许"。")
                }

                // 通知设置
                Section("通知") {
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.red)
                            Text("通知设置")
                        }
                    }
                }

                // 数据管理
                Section("数据") {
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Label("分类管理", systemImage: "folder")
                    }

                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("数据管理", systemImage: "externaldrive")
                    }
                }

                // 关于
                Section("关于") {
                    Button {
                        showAbout = true
                    } label: {
                        HStack {
                            Label("关于", systemImage: "info.circle")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("v1.0.0")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showOnboarding) {
                OnboardingView {}
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }
}

// MARK: - Category Management View

struct CategoryManagementView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var categories: [Category] = []

    var body: some View {
        List {
            ForEach(categories) { category in
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(.blue)

                    Text(category.name)

                    Spacer()

                    if category.isSystem {
                        Text("系统")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("分类管理")
        .task {
            do {
                categories = try await dataManager.fetchCategories()
            } catch {
                print("加载分类失败: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Data Management View

struct DataManagementView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showClearAlert = false

    var body: some View {
        List {
            Section {
                Button(role: .destructive) {
                    showClearAlert = true
                } label: {
                    Label("清除所有数据", systemImage: "trash")
                }
            } footer: {
                Text("此操作将删除所有交易记录、自定义分类和预算设置，且无法恢复。")
            }
        }
        .navigationTitle("数据管理")
        .alert("确认清除", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                Task {
                    try? await dataManager.clearAllData()
                }
            }
        } message: {
            Text("确定要清除所有数据吗？此操作无法撤销。")
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // App 图标
                    Image(systemName: "dollarsign.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.blue.gradient)

                    // App 名称和版本
                    VStack(spacing: 8) {
                        Text("无感记账")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("v1.0.0")
                            .foregroundColor(.secondary)
                    }

                    // 描述
                    Text("一款基于 App Intents + 快捷指令的智能记账应用")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    // 功能列表
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(icon: "wand.and.stars", text: "自动记账")
                        FeatureRow(icon: "brain", text: "智能分类")
                        FeatureRow(icon: "lock.shield", text: "隐私安全")
                        FeatureRow(icon: "chart.bar", text: "数据统计")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
}
