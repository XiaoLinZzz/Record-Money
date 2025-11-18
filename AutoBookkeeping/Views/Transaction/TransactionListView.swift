//
//  TransactionListView.swift
//  AutoBookkeeping
//
//  交易列表视图
//

import SwiftUI
import SwiftData

struct TransactionListView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - State

    @State private var transactions: [Transaction] = []
    @State private var showAddTransaction = false
    @State private var showReceiptScanner = false
    @State private var showSmartInput = false
    @State private var selectedTransaction: Transaction?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var transactionToDelete: Transaction?
    @State private var showDeleteAlert = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("加载中...")
                } else if transactions.isEmpty {
                    emptyStateView
                } else {
                    transactionList
                }
            }
            .navigationTitle("交易记录")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 16) {
                        // 智能输入按钮
                        Button {
                            showSmartInput = true
                            HapticManager.shared.lightImpact()  // 按钮点击反馈
                        } label: {
                            Image(systemName: "sparkles")
                                .font(.title2)
                        }

                        // OCR 扫描按钮
                        Button {
                            showReceiptScanner = true
                            HapticManager.shared.lightImpact()  // 按钮点击反馈
                        } label: {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.title2)
                        }

                        // 手动添加按钮
                        Button {
                            showAddTransaction = true
                            HapticManager.shared.lightImpact()  // 按钮点击反馈
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $showSmartInput) {
                SmartInputView()
            }
            .sheet(isPresented: $showReceiptScanner) {
                ReceiptScannerView()
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction)
            }
            .task {
                await loadTransactions()
            }
            .refreshable {
                await loadTransactions()
                HapticManager.shared.mediumImpact()  // 刷新完成反馈
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
            .onReceive(NotificationCenter.default.publisher(for: .transactionDidChange)) { _ in
                Task {
                    await loadTransactions()
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) {
                    transactionToDelete = nil
                    HapticManager.shared.lightImpact()  // 取消反馈
                }
                Button("删除", role: .destructive) {
                    if let transaction = transactionToDelete {
                        HapticManager.shared.heavyImpact()  // 删除操作重要反馈
                        deleteTransaction(transaction)
                        transactionToDelete = nil
                    }
                }
            } message: {
                Text("确定要删除这条交易记录吗？此操作无法撤销。")
            }
        }
    }

    // MARK: - Subviews

    private var transactionList: some View {
        List {
            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(formatSectionHeader(date))) {
                    ForEach(groupedTransactions[date] ?? []) { transaction in
                        TransactionRow(transaction: transaction)
                            .onTapGesture {
                                selectedTransaction = transaction
                                HapticManager.shared.lightImpact()  // 点击反馈
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    transactionToDelete = transaction
                                    showDeleteAlert = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("暂无交易记录")
                .font(.title2)
                .fontWeight(.semibold)

            Text("点击右上角按钮添加交易：\n✨ 智能输入 | 📄 扫描小票 | ➕ 手动添加")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("添加交易") {
                showAddTransaction = true
                HapticManager.shared.lightImpact()  // 按钮点击反馈
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Methods

    private func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            transactions = try await dataManager.fetchTransactions()
        } catch {
            errorMessage = "加载交易记录失败: \(error.localizedDescription)"
        }
    }

    private func deleteTransaction(_ transaction: Transaction) {
        Task {
            do {
                try await dataManager.deleteTransaction(transaction)
                await loadTransactions()
                HapticManager.shared.success()  // 删除成功反馈
            } catch {
                errorMessage = "删除失败: \(error.localizedDescription)"
                HapticManager.shared.error()  // 删除失败反馈
            }
        }
    }

    private var groupedTransactions: [Date: [Transaction]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.timestamp)
        }
        return grouped
    }

    private func formatSectionHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // 分类图标
            CategoryIcon(categoryName: transaction.categoryName)

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(transaction.categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let paymentMethod = transaction.paymentMethod {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(paymentMethod)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // 金额
            Text(transaction.formattedAmount)
                .font(.headline)
                .foregroundColor(transaction.isExpense ? .red : .green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Icon

struct CategoryIcon: View {
    let categoryName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(categoryColor.opacity(0.2))
                .frame(width: 40, height: 40)

            Image(systemName: categoryIcon)
                .foregroundColor(categoryColor)
        }
    }

    private var categoryColor: Color {
        switch categoryName {
        case "餐饮": return .orange
        case "交通": return .blue
        case "购物": return .pink
        case "娱乐": return .purple
        case "医疗": return .red
        case "教育": return .indigo
        case "生活": return .cyan
        default: return .gray
        }
    }

    private var categoryIcon: String {
        switch categoryName {
        case "餐饮": return "fork.knife"
        case "交通": return "car.fill"
        case "购物": return "cart.fill"
        case "娱乐": return "gamecontroller.fill"
        case "医疗": return "cross.case.fill"
        case "教育": return "book.fill"
        case "生活": return "house.fill"
        default: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TransactionListView()
            .environmentObject(DataManager.shared)
            .environmentObject(NotificationManager.shared)
    }
    .modelContainer(DataManager.shared.getModelContainer())
}
