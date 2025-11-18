//
//  SetBudgetView.swift
//  AutoBookkeeping
//
//  设置预算视图
//

import SwiftUI

struct SetBudgetView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let budget: Budget?  // nil 表示新建，否则为编辑
    let categories: [String]

    // MARK: - State

    @State private var selectedCategory: String
    @State private var amount: String
    @State private var period: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(budget: Budget? = nil, categories: [String]) {
        self.budget = budget
        self.categories = categories

        _selectedCategory = State(initialValue: budget?.categoryName ?? (categories.first ?? "餐饮"))
        _amount = State(initialValue: budget != nil ? String(format: "%.2f", budget!.amount) : "")
        _period = State(initialValue: budget?.period ?? "monthly")
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 分类选择
                Section("预算分类") {
                    Picker("选择分类", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedCategory) { _, _ in
                        HapticManager.shared.selectionChanged()
                    }
                }

                // 金额输入
                Section {
                    HStack {
                        Text("¥")
                            .font(.title2)
                            .foregroundColor(.secondary)

                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                } header: {
                    Text("预算金额")
                } footer: {
                    Text("设置该分类的预算上限")
                }

                // 周期选择
                Section("预算周期") {
                    Picker("选择周期", selection: $period) {
                        Text("每月").tag("monthly")
                        Text("每年").tag("yearly")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: period) { _, _ in
                        HapticManager.shared.selectionChanged()
                    }
                }

                // 预览
                if let amountValue = Double(amount), amountValue > 0 {
                    Section("预览") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedCategory)
                                    .font(.headline)
                                Text(period == "monthly" ? "每月预算" : "每年预算")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("¥\(amountValue, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(budget == nil ? "新建预算" : "编辑预算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(budget == nil ? "创建" : "保存") {
                        Task {
                            await saveBudget()
                        }
                    }
                    .disabled(!isValid || isSubmitting)
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
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !selectedCategory.isEmpty
    }

    // MARK: - Methods

    private func saveBudget() async {
        guard isValid else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        guard let amountValue = Double(amount) else {
            errorMessage = "金额格式不正确"
            HapticManager.shared.error()
            return
        }

        do {
            if let existingBudget = budget {
                // 编辑现有预算
                existingBudget.categoryName = selectedCategory
                existingBudget.amount = amountValue
                existingBudget.period = period
                existingBudget.updatedAt = Date()

                try await BudgetManager.shared.updateBudget(existingBudget)
            } else {
                // 创建新预算
                let newBudget = Budget(
                    categoryName: selectedCategory,
                    amount: amountValue,
                    period: period
                )

                try await BudgetManager.shared.saveBudget(newBudget)
            }

            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }
}

// MARK: - Preview

#Preview {
    SetBudgetView(categories: ["餐饮", "交通", "购物", "娱乐"])
}
