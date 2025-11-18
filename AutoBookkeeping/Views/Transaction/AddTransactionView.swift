//
//  AddTransactionView.swift
//  AutoBookkeeping
//
//  手动添加交易视图
//

import SwiftUI

struct AddTransactionView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - State

    @State private var amount: String = ""
    @State private var merchant: String = ""
    @State private var selectedCategory: String = "餐饮"
    @State private var transactionType: String = "expense"
    @State private var note: String = ""
    @State private var date: Date = Date()

    @State private var categories: [String] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 金额
                Section("金额") {
                    HStack {
                        Text("¥")
                            .font(.title2)
                            .foregroundColor(.secondary)

                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }

                // 商家
                Section("商家") {
                    TextField("商家名称", text: $merchant)
                }

                // 分类
                Section("分类") {
                    Picker("选择分类", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 类型
                Section("类型") {
                    Picker("交易类型", selection: $transactionType) {
                        Text("支出").tag("expense")
                        Text("收入").tag("income")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: transactionType) { _, _ in
                        HapticManager.shared.selectionChanged()  // 切换类型反馈
                    }
                }

                // 日期
                Section("日期") {
                    DatePicker("交易时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                // 备注
                Section("备注") {
                    TextEditor(text: $note)
                        .frame(height: 80)
                }
            }
            .navigationTitle("添加交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()  // 取消反馈
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await saveTransaction()
                        }
                    }
                    .disabled(isSubmitting || !isValid)
                }
            }
            .task {
                await loadCategories()
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

    // MARK: - Validation

    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Methods

    private func loadCategories() async {
        do {
            let fetchedCategories = try await dataManager.fetchCategories()
            categories = fetchedCategories.map { $0.name }
        } catch {
            errorMessage = "加载分类失败: \(error.localizedDescription)"
        }
    }

    private func saveTransaction() async {
        guard isValid else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        guard let amountValue = Double(amount) else {
            errorMessage = "金额格式不正确"
            return
        }

        let transaction = Transaction(
            amount: amountValue,
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            categoryName: selectedCategory,
            type: transactionType,
            paymentMethod: "手动添加",
            rawText: nil,
            timestamp: date,
            note: note.isEmpty ? nil : note
        )

        do {
            try await dataManager.saveTransaction(transaction)
            HapticManager.shared.success()  // 保存成功反馈
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            HapticManager.shared.error()  // 保存失败反馈
        }
    }
}

// MARK: - Preview

#Preview {
    AddTransactionView()
        .environmentObject(DataManager.shared)
}
