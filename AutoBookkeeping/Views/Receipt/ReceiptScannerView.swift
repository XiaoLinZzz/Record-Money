//
//  ReceiptScannerView.swift
//  AutoBookkeeping
//
//  小票扫描视图
//  OCR 识别小票并自动填充交易信息
//

import SwiftUI
import PhotosUI

struct ReceiptScannerView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - State

    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    @State private var parsedReceipt: ParsedReceipt?
    @State private var showConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 说明
                instructionSection

                // 预览图片
                if let image = selectedImage {
                    imagePreview(image)
                } else {
                    emptyImageSection
                }

                // 操作按钮
                actionButtons

                Spacer()
            }
            .padding()
            .navigationTitle("扫描小票")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        HapticManager.shared.lightImpact()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: .photoLibrary) { image in
                    handleImageSelection(image)
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    handleImageSelection(image)
                }
            }
            .sheet(isPresented: $showConfirmation) {
                if let receipt = parsedReceipt {
                    ConfirmReceiptView(receipt: receipt)
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
            .overlay {
                if isProcessing {
                    ProgressView("识别中...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Subviews

    private var instructionSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("小票 OCR 识别")
                .font(.title2)
                .fontWeight(.semibold)

            Text("拍摄或选择小票照片，自动识别交易信息")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var emptyImageSection: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 200)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("未选择图片")
                        .foregroundColor(.secondary)
                }
            }
    }

    private func imagePreview(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 300)
            .cornerRadius(12)
            .shadow(radius: 5)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // 拍照按钮
            Button {
                showCamera = true
                HapticManager.shared.lightImpact()
            } label: {
                Label("拍摄小票", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            // 相册按钮
            Button {
                showImagePicker = true
                HapticManager.shared.lightImpact()
            } label: {
                Label("从相册选择", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }

            // 识别按钮
            if selectedImage != nil {
                Button {
                    Task {
                        await recognizeReceipt()
                    }
                } label: {
                    Label("开始识别", systemImage: "text.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isProcessing)
            }
        }
    }

    // MARK: - Methods

    private func handleImageSelection(_ image: UIImage) {
        selectedImage = image
        HapticManager.shared.lightImpact()
    }

    private func recognizeReceipt() async {
        guard let image = selectedImage else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            // OCR 识别
            let text = try await OCRManager.shared.recognizeText(from: image)

            // 解析小票
            let receipt = ReceiptParser.shared.parse(text)
            parsedReceipt = receipt

            // 触觉反馈
            HapticManager.shared.success()

            // 显示确认界面
            showConfirmation = true

        } catch {
            errorMessage = "识别失败: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }
}

// MARK: - Confirm Receipt View

struct ConfirmReceiptView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - Properties

    let receipt: ParsedReceipt

    // MARK: - State

    @State private var amount: String
    @State private var merchant: String
    @State private var selectedCategory: String = "餐饮"
    @State private var transactionType: String = "expense"
    @State private var note: String = ""
    @State private var date: Date

    @State private var categories: [String] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(receipt: ParsedReceipt) {
        self.receipt = receipt
        _amount = State(initialValue: receipt.amount.map { String(format: "%.2f", $0) } ?? "")
        _merchant = State(initialValue: receipt.merchant ?? "")
        _date = State(initialValue: receipt.date ?? Date())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // OCR 识别结果
                Section {
                    HStack {
                        Text("识别状态")
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("识别成功")
                            .foregroundColor(.green)
                    }
                } header: {
                    Text("OCR 结果")
                } footer: {
                    Text("请确认识别结果，并补充缺失信息")
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
                    DatePicker("交易时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                // 备注
                Section("备注") {
                    TextEditor(text: $note)
                        .frame(height: 80)
                }

                // 原始文本
                if !receipt.rawText.isEmpty {
                    Section("OCR 原始文本") {
                        Text(receipt.rawText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
            paymentMethod: "OCR识别",
            rawText: receipt.rawText,
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
    ReceiptScannerView()
        .environmentObject(DataManager.shared)
}
