//
//  MLTrainingDataManager.swift
//  AutoBookkeeping
//
//  CoreML 训练数据管理器
//  收集和管理用户修正数据，用于训练 CoreML 模型
//

import Foundation
import CoreML

@MainActor
class MLTrainingDataManager {

    static let shared = MLTrainingDataManager()

    private init() {}

    // MARK: - Properties

    /// 最小训练数据量（建议）
    static let minimumTrainingDataCount = 100

    /// 训练数据导出目录
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Public Methods

    /// 获取当前训练数据数量
    func getTrainingDataCount() -> Int {
        return CategoryEngine.shared.getTrainingDataCount()
    }

    /// 是否有足够的训练数据
    func hasEnoughData() -> Bool {
        return getTrainingDataCount() >= Self.minimumTrainingDataCount
    }

    /// 获取训练数据完成度（百分比）
    func getDataCompletionPercentage() -> Double {
        let count = Double(getTrainingDataCount())
        let minimum = Double(Self.minimumTrainingDataCount)
        return min(count / minimum, 1.0) * 100
    }

    /// 导出训练数据为 CSV 文件
    /// - Returns: CSV 文件的 URL
    func exportTrainingDataAsCSV() throws -> URL {
        let csvString = CategoryEngine.shared.exportTrainingDataForML()

        let fileName = "category_training_data_\(Date().timeIntervalSince1970).csv"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    /// 导出训练数据为 JSON 文件
    /// - Returns: JSON 文件的 URL
    func exportTrainingDataAsJSON() throws -> URL {
        let trainingData = CategoryEngine.shared.getTrainingData()

        let jsonArray = trainingData.map { ["text": $0.text, "label": $0.label] }
        let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted])

        let fileName = "category_training_data_\(Date().timeIntervalSince1970).json"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        try jsonData.write(to: fileURL)

        return fileURL
    }

    /// 获取训练数据统计信息
    func getTrainingDataStatistics() -> TrainingDataStatistics {
        let totalCount = getTrainingDataCount()
        let categoryCounts = CategoryEngine.shared.getCorrectionStatistics()

        let mostCommonCategory = categoryCounts.max(by: { $0.value < $1.value })
        let leastCommonCategory = categoryCounts.filter({ $0.value > 0 }).min(by: { $0.value < $1.value })

        return TrainingDataStatistics(
            totalCount: totalCount,
            categoryCounts: categoryCounts,
            mostCommonCategory: mostCommonCategory?.key,
            mostCommonCount: mostCommonCategory?.value ?? 0,
            leastCommonCategory: leastCommonCategory?.key,
            leastCommonCount: leastCommonCategory?.value ?? 0,
            hasEnoughData: hasEnoughData(),
            completionPercentage: getDataCompletionPercentage()
        )
    }

    /// 清除所有训练数据（谨慎使用）
    func clearTrainingData() {
        CategoryEngine.shared.clearUserData()
    }

    // MARK: - CoreML Model Management

    /// 检查是否存在已训练的 CoreML 模型
    func hasTrainedModel() -> Bool {
        let modelURL = getCoreMLModelURL()
        return FileManager.default.fileExists(atPath: modelURL.path)
    }

    /// 获取 CoreML 模型文件 URL
    func getCoreMLModelURL() -> URL {
        return documentsDirectory.appendingPathComponent("CategoryClassifier.mlmodel")
    }

    /// 获取编译后的 CoreML 模型 URL
    func getCompiledModelURL() -> URL {
        return documentsDirectory.appendingPathComponent("CategoryClassifier.mlmodelc")
    }

    /// 导入训练好的 CoreML 模型
    /// - Parameter sourceURL: 源文件 URL
    func importCoreMLModel(from sourceURL: URL) throws {
        let destinationURL = getCoreMLModelURL()

        // 如果目标文件存在，先删除
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        // 复制文件
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }
}

// MARK: - Training Data Statistics

struct TrainingDataStatistics {
    let totalCount: Int
    let categoryCounts: [String: Int]
    let mostCommonCategory: String?
    let mostCommonCount: Int
    let leastCommonCategory: String?
    let leastCommonCount: Int
    let hasEnoughData: Bool
    let completionPercentage: Double

    var formattedCompletionPercentage: String {
        return String(format: "%.1f%%", completionPercentage)
    }

    var categoryDistribution: [(category: String, count: Int)] {
        return categoryCounts.map { ($0.key, $0.value) }
            .sorted { $0.count > $1.count }
    }

    var isBalanced: Bool {
        guard let maxCount = categoryCounts.values.max(),
              let minCount = categoryCounts.values.min(),
              minCount > 0 else {
            return false
        }

        // 如果最大和最小的比例不超过 3:1，认为是平衡的
        return Double(maxCount) / Double(minCount) <= 3.0
    }
}
