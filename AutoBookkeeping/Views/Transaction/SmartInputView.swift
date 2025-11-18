//
//  SmartInputView.swift
//  AutoBookkeeping
//
//  智能输入视图
//  支持自然语言输入交易信息
//

import SwiftUI

struct SmartInputView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - State

    @State private var inputText: String = ""
    @State private var parsedTransaction: ParsedTransaction?
    @State private var showConfirmation = false

    @State private var categories: [String] = []
    @State private var errorMessage: String?

    @FocusState private var isInputFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 说明区域
                instructionSection
                    .padding()
                    .background(Color(.systemGroupedBackground))

                // 输入区域
                inputSection
                    .padding()

                // 解析结果预览
                if let parsed = parsedTransaction {
                    parseResultSection(parsed)
                }

                // 示例
                exampleSection
                    .padding()

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("智能记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }
            }
            .sheet(isPresented: $showConfirmation) {
                if let parsed = parsedTransaction {
                    ConfirmSmartInputView(parsedTransaction: parsed)
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
            .task {
                await loadCategories()
                isInputFocused = true
            }
        }
    }

    // MARK: - Subviews

    private var instructionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("用自然语言描述交易")
                    .font(.headline)

                Spacer()
            }

            Text("例如：\"今天中午星巴克花了35块\" 或 \"昨天打车20元\"")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            // 输入框
            VStack(alignment: .leading, spacing: 8) {
                Text("输入交易描述")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("例如：星巴克买咖啡35元", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        parseInput()
                    }
                    .onChange(of: inputText) { _, newValue in
                        // 实时解析（去抖）
                        if !newValue.isEmpty {
                            parseInputDebounced()
                        }
                    }
            }

            // 解析按钮
            HStack(spacing: 12) {
                Button {
                    inputText = ""
                    parsedTransaction = nil
                    HapticManager.shared.lightImpact()
                } label: {
                    Label("清空", systemImage: "xmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(10)
                }
                .disabled(inputText.isEmpty)

                Button {
                    parseInput()
                } label: {
                    Label("解析", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(inputText.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func parseResultSection(_ parsed: ParsedTransaction) -> some View {
        VStack(spacing: 16) {
            // 置信度指示器
            HStack {
                Text("识别结果")
                    .font(.headline)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: confidenceIcon(parsed.confidence))
                        .foregroundColor(confidenceColor(parsed.confidence))
                    Text(String(format: "%.0f%%", parsed.confidence * 100))
                        .font(.caption)
                        .foregroundColor(confidenceColor(parsed.confidence))
                }
            }

            // 解析结果
            VStack(spacing: 12) {
                if let amount = parsed.amount {
                    ResultRow(label: "金额", value: String(format: "¥%.2f", amount), icon: "yensign.circle.fill", color: .green)
                }

                if let merchant = parsed.merchant {
                    ResultRow(label: "商家", value: merchant, icon: "building.2.fill", color: .blue)
                }

                if let category = parsed.category {
                    ResultRow(label: "分类", value: category, icon: "tag.fill", color: .orange)
                }

                if let date = parsed.date {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm"
                    ResultRow(label: "时间", value: formatter.string(from: date), icon: "clock.fill", color: .purple)
                }

                ResultRow(label: "类型",
                         value: parsed.transactionType == "expense" ? "支出" : "收入",
                         icon: parsed.transactionType == "expense" ? "arrow.down.circle.fill" : "arrow.up.circle.fill",
                         color: parsed.transactionType == "expense" ? .red : .green)
            }

            // 确认按钮
            Button {
                if parsed.amount != nil {
                    showConfirmation = true
                    HapticManager.shared.lightImpact()
                } else {
                    errorMessage = "未能识别金额，请检查输入"
                    HapticManager.shared.error()
                }
            } label: {
                Label("确认并保存", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(parsed.amount != nil ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(parsed.amount == nil)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var exampleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("示例")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                ExampleRow(text: "今天中午星巴克花了35块", onTap: {
                    inputText = "今天中午星巴克花了35块"
                    parseInput()
                })

                ExampleRow(text: "昨天打车20元", onTap: {
                    inputText = "昨天打车20元"
                    parseInput()
                })

                ExampleRow(text: "淘宝买了件衣服199", onTap: {
                    inputText = "淘宝买了件衣服199"
                    parseInput()
                })

                ExampleRow(text: "下午肯德基花了45", onTap: {
                    inputText = "下午肯德基花了45"
                    parseInput()
                })
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
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

    private func parseInput() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            parsedTransaction = nil
            return
        }

        let parsed = NLPParser.shared.parse(inputText)
        parsedTransaction = parsed

        HapticManager.shared.lightImpact()
    }

    private func parseInputDebounced() {
        // 简单的实时解析（可以添加防抖）
        parseInput()
    }

    private func confidenceIcon(_ confidence: Float) -> String {
        switch confidence {
        case 0.8...1.0: return "checkmark.seal.fill"
        case 0.5..<0.8: return "checkmark.circle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }

    private func confidenceColor(_ confidence: Float) -> Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

// MARK: - Result Row

struct ResultRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Example Row

struct ExampleRow: View {
    let text: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.blue)
                    .font(.caption)

                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
    }
}

// MARK: - Confirm Smart Input View

struct ConfirmSmartInputView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - Properties

    let parsedTransaction: ParsedTransaction

    // MARK: - State

    @State private var amount: String
    @State private var merchant: String
    @State private var selectedCategory: String
    @State private var transactionType: String
    @State private var note: String
    @State private var date: Date

    @State private var categories: [String] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(parsedTransaction: ParsedTransaction) {
        self.parsedTransaction = parsedTransaction
        _amount = State(initialValue: parsedTransaction.amount.map { String(format: "%.2f", $0) } ?? "")
        _merchant = State(initialValue: parsedTransaction.merchant ?? "")
        _selectedCategory = State(initialValue: parsedTransaction.category ?? "餐饮")
        _transactionType = State(initialValue: parsedTransaction.transactionType)
        _note = State(initialValue: parsedTransaction.rawInput)
        _date = State(initialValue: parsedTransaction.date ?? Date())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // NLP 识别结果
                Section {
                    HStack {
                        Text("识别状态")
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(String(format: "%.0f%% 置信度", parsedTransaction.confidence * 100))
                            .foregroundColor(.green)
                    }
                } header: {
                    Text("智能解析结果")
                } footer: {
                    Text("请确认解析结果，并补充缺失信息")
                }

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
                        HapticManager.shared.selectionChanged()
                    }
                }

                // 日期
                Section("日期") {
                    DatePicker("交易时间", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                }

                // 备注
                Section("备注") {
                    TextEditor(text: $note)
                        .frame(height: 80)
                }
            }
            .navigationTitle("确认交易信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()
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

            // 智能推荐分类
            if let suggestedCategory = await CategoryEngine.shared.suggestCategory(
                for: merchant.trimmingCharacters(in: .whitespacesAndNewlines)
            ) {
                selectedCategory = suggestedCategory
            }
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
            paymentMethod: "智能输入",
            rawText: parsedTransaction.rawInput,
            timestamp: date,
            note: note.isEmpty ? nil : note
        )

        do {
            try await dataManager.saveTransaction(transaction)
            HapticManager.shared.success()

            // 关闭所有弹窗
            dismiss()
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.dismiss(animated: true)
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }
}

// MARK: - Preview

#Preview {
    SmartInputView()
        .environmentObject(DataManager.shared)
}
