//
//  EditTransactionView.swift
//  AutoBookkeeping
//
//  编辑交易视图
//

import SwiftUI

struct EditTransactionView: View {

    // MARK: - Properties

    let originalTransaction: Transaction

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
                }

                // 日期
                Section("日期") {
                    DatePicker(
                        "交易时间",
                        selection: $date,
                        in: ...Date(), // 限制不能选择未来时间
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // 备注
                Section("备注") {
                    TextEditor(text: $note)
                        .frame(height: 80)
                }
            }
            .navigationTitle("编辑交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await updateTransaction()
                        }
                    }
                    .disabled(isSubmitting || !isValid)
                }
            }
            .task {
                await loadCategories()
                initializeFields()
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

    /// 初始化字段为原始交易的值
    private func initializeFields() {
        amount = String(originalTransaction.amount)
        merchant = originalTransaction.merchant
        selectedCategory = originalTransaction.categoryName
        transactionType = originalTransaction.type
        note = originalTransaction.note ?? ""
        date = originalTransaction.timestamp
    }

    /// 加载分类列表
    private func loadCategories() async {
        do {
            let fetchedCategories = try await dataManager.fetchCategories()
            categories = fetchedCategories.map { $0.name }
        } catch {
            errorMessage = "加载分类失败: \(error.localizedDescription)"
        }
    }

    /// 更新交易记录
    private func updateTransaction() async {
        guard isValid else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        guard let amountValue = Double(amount) else {
            errorMessage = "金额格式不正确"
            return
        }

        // 检查分类是否改变（用于触发学习）
        let categoryChanged = selectedCategory != originalTransaction.categoryName

        do {
            // 更新交易数据
            try await dataManager.updateTransaction(
                originalTransaction,
                amount: amountValue,
                merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
                categoryName: selectedCategory,
                type: transactionType,
                timestamp: date,
                note: note.isEmpty ? nil : note
            )

            // 触觉反馈
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // 如果分类改变，触发学习
            if categoryChanged {
                await CategoryEngine.shared.learnFromUserCorrection(
                    merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
                    correctedCategory: selectedCategory
                )
            }

            dismiss()
        } catch {
            errorMessage = "更新失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

#Preview {
    EditTransactionView(originalTransaction: Transaction.preview)
        .environmentObject(DataManager.shared)
}
