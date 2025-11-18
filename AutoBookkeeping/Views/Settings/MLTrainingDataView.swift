//
//  MLTrainingDataView.swift
//  AutoBookkeeping
//
//  ML 训练数据管理视图
//  显示训练数据统计，导出数据用于模型训练
//

import SwiftUI

struct MLTrainingDataView: View {

    // MARK: - State

    @State private var statistics: TrainingDataStatistics?
    @State private var modelStatus: String = "检查中..."
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false

    // MARK: - Body

    var body: some View {
        List {
            // 模型状态
            Section {
                modelStatusRow
            } header: {
                Text("CoreML 模型状态")
            }

            // 训练数据统计
            if let stats = statistics {
                Section {
                    dataStatisticsRows(stats)
                } header: {
                    Text("训练数据统计")
                } footer: {
                    Text("最少需要 \(MLTrainingDataManager.minimumTrainingDataCount) 条数据才能训练模型")
                }

                // 分类分布
                if !stats.categoryDistribution.isEmpty {
                    Section("分类数据分布") {
                        ForEach(stats.categoryDistribution, id: \.category) { item in
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text("\(item.count) 条")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // 数据质量
                Section("数据质量") {
                    HStack {
                        Text("数据平衡性")
                        Spacer()
                        if stats.isBalanced {
                            Label("良好", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("需优化", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    if let mostCommon = stats.mostCommonCategory {
                        HStack {
                            Text("最多分类")
                            Spacer()
                            Text("\(mostCommon) (\(stats.mostCommonCount)条)")
                                .foregroundColor(.secondary)
                        }
                    }

                    if let leastCommon = stats.leastCommonCategory {
                        HStack {
                            Text("最少分类")
                            Spacer()
                            Text("\(leastCommon) (\(stats.leastCommonCount)条)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // 操作
            Section {
                // 导出 CSV
                Button {
                    exportTrainingData(format: .csv)
                } label: {
                    Label("导出训练数据 (CSV)", systemImage: "square.and.arrow.up")
                }
                .disabled(statistics?.totalCount ?? 0 == 0)

                // 导出 JSON
                Button {
                    exportTrainingData(format: .json)
                } label: {
                    Label("导出训练数据 (JSON)", systemImage: "doc.text")
                }
                .disabled(statistics?.totalCount ?? 0 == 0)

                // 清除数据（危险操作）
                Button(role: .destructive) {
                    clearTrainingData()
                } label: {
                    Label("清除所有训练数据", systemImage: "trash")
                }
                .disabled(statistics?.totalCount ?? 0 == 0)

            } header: {
                Text("操作")
            } footer: {
                Text("导出的数据可用于在 Mac 上使用 Create ML 训练模型")
            }

            // 使用说明
            Section("训练指南") {
                Link(destination: URL(string: "https://github.com/yourrepo/docs/COREML_TRAINING_GUIDE.md")!) {
                    HStack {
                        Label("查看完整训练指南", systemImage: "book")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("ML 训练数据")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStatistics()
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
        .alert("成功", isPresented: .constant(successMessage != nil)) {
            Button("确定") {
                successMessage = nil
            }
        } message: {
            if let message = successMessage {
                Text(message)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Subviews

    private var modelStatusRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if CategoryMLClassifier.shared.isAvailable() {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("模型已加载")
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.orange)
                    Text("模型未加载")
                }
                Spacer()
            }

            Text(modelStatus)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func dataStatisticsRows(_ stats: TrainingDataStatistics) -> some View {
        Group {
            HStack {
                Text("总数据量")
                Spacer()
                Text("\(stats.totalCount) 条")
                    .fontWeight(.semibold)
            }

            HStack {
                Text("完成度")
                Spacer()
                ProgressView(value: stats.completionPercentage, total: 100)
                    .frame(width: 100)
                Text(stats.formattedCompletionPercentage)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("状态")
                Spacer()
                if stats.hasEnoughData {
                    Label("可以训练", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    let needed = MLTrainingDataManager.minimumTrainingDataCount - stats.totalCount
                    Label("还需 \(needed) 条", systemImage: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
    }

    // MARK: - Methods

    private func loadStatistics() async {
        isLoading = true
        defer { isLoading = false }

        statistics = MLTrainingDataManager.shared.getTrainingDataStatistics()
        modelStatus = CategoryEngine.shared.getMLModelStatus()

        if let modelInfo = CategoryMLClassifier.shared.getModelInfo() {
            modelStatus += "\n版本: \(modelInfo.version)"
        }
    }

    private enum ExportFormat {
        case csv
        case json
    }

    private func exportTrainingData(format: ExportFormat) {
        isLoading = true
        defer { isLoading = false }

        do {
            let fileURL: URL
            switch format {
            case .csv:
                fileURL = try MLTrainingDataManager.shared.exportTrainingDataAsCSV()
            case .json:
                fileURL = try MLTrainingDataManager.shared.exportTrainingDataAsJSON()
            }

            exportedFileURL = fileURL
            showShareSheet = true
            HapticManager.shared.success()

        } catch {
            errorMessage = "导出失败: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }

    private func clearTrainingData() {
        // 二次确认
        let alert = UIAlertController(
            title: "确认清除",
            message: "此操作将删除所有训练数据，无法恢复。确定要继续吗？",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清除", style: .destructive) { _ in
            MLTrainingDataManager.shared.clearTrainingData()
            Task {
                await loadStatistics()
            }
            HapticManager.shared.success()
            successMessage = "训练数据已清除"
        })

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MLTrainingDataView()
    }
}
