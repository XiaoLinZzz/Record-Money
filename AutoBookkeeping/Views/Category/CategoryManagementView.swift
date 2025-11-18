//
//  CategoryManagementView.swift
//  AutoBookkeeping
//
//  分类管理视图
//

import SwiftUI

struct CategoryManagementView: View {

    // MARK: - Environment

    @EnvironmentObject private var dataManager: DataManager

    // MARK: - State

    @State private var categories: [Category] = []
    @State private var showAddCategory = false
    @State private var categoryToEdit: Category?
    @State private var categoryToDelete: Category?
    @State private var showDeleteAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("加载中...")
                } else if categories.isEmpty {
                    emptyStateView
                } else {
                    categoryList
                }
            }
            .navigationTitle("分类管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCategory = true
                        HapticManager.shared.lightImpact()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView()
            }
            .sheet(item: $categoryToEdit) { category in
                AddCategoryView(category: category)
            }
            .task {
                await loadCategories()
            }
            .refreshable {
                await loadCategories()
                HapticManager.shared.mediumImpact()
            }
            .onReceive(NotificationCenter.default.publisher(for: .categoryDidChange)) { _ in
                Task {
                    await loadCategories()
                }
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) {
                    categoryToDelete = nil
                    HapticManager.shared.lightImpact()
                }
                Button("删除", role: .destructive) {
                    if let category = categoryToDelete {
                        Task {
                            await deleteCategory(category)
                        }
                    }
                }
            } message: {
                if let category = categoryToDelete {
                    Text("确定要删除分类 \"\(category.name)\" 吗？")
                }
            }
        }
    }

    // MARK: - Subviews

    private var categoryList: some View {
        List {
            // 系统分类
            if !systemCategories.isEmpty {
                Section("系统分类") {
                    ForEach(systemCategories) { category in
                        categoryRow(category)
                    }
                }
            }

            // 自定义分类
            if !customCategories.isEmpty {
                Section("自定义分类") {
                    ForEach(customCategories) { category in
                        categoryRow(category)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func categoryRow(_ category: Category) -> some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(category.colorValue.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(category.colorValue)
            }

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)

                if !category.keywords.isEmpty {
                    Text(category.keywords.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 自定义标签
            if category.isCustom {
                Text("自定义")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if category.isCustom {
                categoryToEdit = category
                HapticManager.shared.lightImpact()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if category.isCustom {
                Button(role: .destructive) {
                    categoryToDelete = category
                    showDeleteAlert = true
                } label: {
                    Label("删除", systemImage: "trash")
                }

                Button {
                    categoryToEdit = category
                    HapticManager.shared.lightImpact()
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无自定义分类")
                .font(.title2)
                .fontWeight(.semibold)

            Text("点击右上角 + 创建自定义分类\n为你的记账添加个性化标签")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("创建分类") {
                showAddCategory = true
                HapticManager.shared.lightImpact()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var systemCategories: [Category] {
        categories.filter { !$0.isCustom }
    }

    private var customCategories: [Category] {
        categories.filter { $0.isCustom }
    }

    // MARK: - Methods

    private func loadCategories() async {
        isLoading = true
        defer { isLoading = false }

        do {
            categories = try await dataManager.fetchCategories()
        } catch {
            errorMessage = "加载分类失败: \(error.localizedDescription)"
        }
    }

    private func deleteCategory(_ category: Category) async {
        do {
            // 检查是否有交易使用此分类
            let transactions = try await dataManager.fetchTransactions(category: category.name)

            if !transactions.isEmpty {
                errorMessage = "无法删除：该分类下还有 \(transactions.count) 条交易记录"
                HapticManager.shared.error()
                categoryToDelete = nil
                return
            }

            try await dataManager.deleteCategory(category)
            HapticManager.shared.success()
            categoryToDelete = nil
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let categoryDidChange = Notification.Name("categoryDidChange")
}

// MARK: - Preview

#Preview {
    CategoryManagementView()
        .environmentObject(DataManager.shared)
}
