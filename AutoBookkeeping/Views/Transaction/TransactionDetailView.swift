//
//  TransactionDetailView.swift
//  AutoBookkeeping
//
//  交易详情视图
//

import SwiftUI

struct TransactionDetailView: View {

    // MARK: - Properties

    let transaction: Transaction

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - State

    @State private var showEditView = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // 金额
                Section {
                    HStack {
                        Text("金额")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(transaction.formattedAmount)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(transaction.isExpense ? .red : .green)
                    }
                }

                // 基本信息
                Section("基本信息") {
                    DetailRow(label: "商家", value: transaction.merchant)
                    DetailRow(label: "分类", value: transaction.categoryName)
                    DetailRow(label: "类型", value: transaction.isExpense ? "支出" : "收入")

                    if let paymentMethod = transaction.paymentMethod {
                        DetailRow(label: "支付方式", value: paymentMethod)
                    }
                }

                // 时间信息
                Section("时间") {
                    DetailRow(label: "交易时间", value: transaction.formattedDate)
                }

                // 备注
                if let note = transaction.note, !note.isEmpty {
                    Section("备注") {
                        Text(note)
                            .foregroundColor(.primary)
                    }
                }

                // 原始数据
                if let rawText = transaction.rawText {
                    Section("OCR 原始文本") {
                        Text(rawText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("交易详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("编辑") {
                        showEditView = true
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditView) {
                EditTransactionView(originalTransaction: transaction)
                    .environmentObject(dataManager)
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

// MARK: - Preview

#Preview {
    TransactionDetailView(transaction: Transaction.preview)
        .environmentObject(DataManager.shared)
}
