//
//  BudgetOverviewView.swift
//  AutoBookkeeping
//
//  预算概览视图
//

import SwiftUI

struct BudgetOverviewView: View {

    // MARK: - Environment

    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var budgetManager = BudgetManager.shared

    // MARK: - State

    @State private var budgetDetails: [BudgetDetail] = []
    @State private var categories: [String] = []
    @State private var isLoading = false
    @State private var showAddBudget = false
    @State private var budgetToEdit: Budget?
    @State private var budgetToDelete: Budget?
    @State private var showDeleteAlert = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("加载中...")
                } else if budgetDetails.isEmpty {
                    emptyStateView
                } else {
                    budgetList
                }
            }
            .navigationTitle("预算管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddBudget = true
                        HapticManager.shared.lightImpact()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddBudget) {
                SetBudgetView(categories: categories)
            }
            .sheet(item: $budgetToEdit) { budget in
                SetBudgetView(budget: budget, categories: categories)
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
                HapticManager.shared.mediumImpact()
            }
            .onReceive(NotificationCenter.default.publisher(for: .budgetDidChange)) { _ in
                Task {
                    await loadData()
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
                    budgetToDelete = nil
                    HapticManager.shared.lightImpact()
                }
                Button("删除", role: .destructive) {
                    if let budget = budgetToDelete {
                        Task {
                            await deleteBudget(budget)
                        }
                    }
                }
            } message: {
                Text("确定要删除这个预算吗？")
            }
        }
    }

    // MARK: - Subviews

    private var budgetList: some View {
        List {
            // 超支警告
            if !overdueeBudgets.isEmpty {
                Section {
                    ForEach(overdueeBudgets) { detail in
                        budgetWarningRow(detail)
                    }
                } header: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("超支警告")
                    }
                    .foregroundColor(.red)
                }
            }

            // 接近预算警告
            if !approachingBudgets.isEmpty {
                Section {
                    ForEach(approachingBudgets) { detail in
                        budgetWarningRow(detail)
                    }
                } header: {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("接近预算")
                    }
                    .foregroundColor(.orange)
                }
            }

            // 正常预算
            if !normalBudgets.isEmpty {
                Section("正常预算") {
                    ForEach(normalBudgets) { detail in
                        budgetRow(detail)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func budgetRow(_ detail: BudgetDetail) -> some View {
        VStack(spacing: 12) {
            // 标题行
            HStack {
                Text(detail.budget.categoryName)
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("¥\(detail.spending, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(progressColor(detail))
                    Text("/ ¥\(detail.budget.amount, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 进度条
            ProgressView(value: min(detail.usage, 1.0), total: 1.0)
                .tint(progressColor(detail))

            // 信息行
            HStack {
                Text("\(Int(detail.usage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if detail.isOver {
                    Text("超支 ¥\(detail.overage, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                } else {
                    Text("剩余 ¥\(detail.remaining, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            budgetToEdit = detail.budget
            HapticManager.shared.lightImpact()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                budgetToDelete = detail.budget
                showDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }

            Button {
                budgetToEdit = detail.budget
                HapticManager.shared.lightImpact()
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    private func budgetWarningRow(_ detail: BudgetDetail) -> some View {
        HStack(spacing: 12) {
            // 警告图标
            Image(systemName: detail.isOver ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .font(.title2)
                .foregroundColor(detail.isOver ? .red : .orange)

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(detail.budget.categoryName)
                    .font(.headline)

                if detail.isOver {
                    Text("已超支 ¥\(detail.overage, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text("已使用 \(Int(detail.usage * 100))%")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // 金额
            Text("¥\(detail.spending, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(detail.isOver ? .red : .orange)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            budgetToEdit = detail.budget
            HapticManager.shared.lightImpact()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无预算")
                .font(.title2)
                .fontWeight(.semibold)

            Text("设置预算有助于控制支出\n点击右上角 + 创建第一个预算")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("创建预算") {
                showAddBudget = true
                HapticManager.shared.lightImpact()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var overdueeBudgets: [BudgetDetail] {
        budgetDetails.filter { $0.isOver }
    }

    private var approachingBudgets: [BudgetDetail] {
        budgetDetails.filter { !$0.isOver && $0.usage >= 0.9 }
    }

    private var normalBudgets: [BudgetDetail] {
        budgetDetails.filter { !$0.isOver && $0.usage < 0.9 }
    }

    private func progressColor(_ detail: BudgetDetail) -> Color {
        switch detail.usage {
        case 0..<0.7: return .green
        case 0.7..<0.9: return .orange
        default: return .red
        }
    }

    // MARK: - Methods

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 加载分类
            let fetchedCategories = try await dataManager.fetchCategories()
            categories = fetchedCategories.map { $0.name }

            // 加载预算
            await budgetManager.loadBudgets()

            // 加载预算详情
            budgetDetails = await budgetManager.getAllBudgetDetails()
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }

    private func deleteBudget(_ budget: Budget) async {
        do {
            try await budgetManager.deleteBudget(budget)
            HapticManager.shared.success()
            budgetToDelete = nil
        } catch {
            errorMessage = "删除失败: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }
}

// MARK: - BudgetDetail Identifiable

extension BudgetDetail: Identifiable {
    var id: UUID { budget.id }
}

// MARK: - Preview

#Preview {
    BudgetOverviewView()
        .environmentObject(DataManager.shared)
}
