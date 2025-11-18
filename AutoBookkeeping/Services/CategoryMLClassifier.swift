//
//  CategoryMLClassifier.swift
//  AutoBookkeeping
//
//  CoreML 分类器
//  使用训练好的 CoreML 模型进行商家分类预测
//

import Foundation
import CoreML
import NaturalLanguage

@MainActor
class CategoryMLClassifier {

    static let shared = CategoryMLClassifier()

    private init() {
        loadModel()
    }

    // MARK: - Properties

    private var mlModel: MLModel?
    private var isModelAvailable: Bool {
        return mlModel != nil
    }

    // MARK: - Public Methods

    /// 预测分类
    /// - Parameter merchant: 商家名称
    /// - Returns: 预测的分类和置信度
    func predictCategory(for merchant: String) async -> (category: String, confidence: Double)? {
        guard isModelAvailable else {
            return nil
        }

        // 使用 CoreML 模型预测（实际实现需要模型）
        // 这里是占位符代码，实际需要根据训练的模型调整

        // TODO: 实现 CoreML 预测逻辑
        // 示例代码：
        // guard let prediction = try? model.prediction(text: merchant) else {
        //     return nil
        // }
        // return (category: prediction.label, confidence: prediction.labelProbabilities[prediction.label] ?? 0.0)

        return nil
    }

    /// 批量预测分类
    /// - Parameter merchants: 商家名称数组
    /// - Returns: 预测结果数组
    func predictCategories(for merchants: [String]) async -> [(merchant: String, category: String, confidence: Double)] {
        var results: [(String, String, Double)] = []

        for merchant in merchants {
            if let prediction = await predictCategory(for: merchant) {
                results.append((merchant, prediction.category, prediction.confidence))
            }
        }

        return results
    }

    /// 模型是否可用
    func isAvailable() -> Bool {
        return isModelAvailable
    }

    /// 获取模型信息
    func getModelInfo() -> ModelInfo? {
        guard let model = mlModel else {
            return nil
        }

        let description = model.modelDescription
        return ModelInfo(
            name: description.metadata[.description] as? String ?? "未知",
            author: description.metadata[.author] as? String ?? "未知",
            version: description.metadata[.versionString] as? String ?? "未知",
            license: description.metadata[.license] as? String ?? "未知"
        )
    }

    // MARK: - Private Methods

    /// 加载 CoreML 模型
    private func loadModel() {
        // 尝试从 App Bundle 加载模型
        if let bundleURL = Bundle.main.url(forResource: "CategoryClassifier", withExtension: "mlmodelc") {
            do {
                mlModel = try MLModel(contentsOf: bundleURL)
                print("✅ CoreML 模型加载成功")
                return
            } catch {
                print("⚠️ Bundle 中的模型加载失败: \(error.localizedDescription)")
            }
        }

        // 尝试从 Documents 目录加载模型
        let documentsURL = MLTrainingDataManager.shared.getCompiledModelURL()
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                mlModel = try MLModel(contentsOf: documentsURL)
                print("✅ CoreML 模型从 Documents 加载成功")
                return
            } catch {
                print("⚠️ Documents 中的模型加载失败: \(error.localizedDescription)")
            }
        }

        print("ℹ️ CoreML 模型未找到，将使用规则引擎")
    }

    /// 重新加载模型
    func reloadModel() {
        mlModel = nil
        loadModel()
    }
}

// MARK: - Model Info

struct ModelInfo {
    let name: String
    let author: String
    let version: String
    let license: String

    var formattedDescription: String {
        """
        名称: \(name)
        作者: \(author)
        版本: \(version)
        许可: \(license)
        """
    }
}

// MARK: - CategoryEngine Integration

extension CategoryEngine {

    /// 使用 ML 模型推断分类（如果可用）
    /// - Parameters:
    ///   - merchant: 商家名称
    ///   - rawText: 原始文本
    /// - Returns: 分类名称
    func inferCategoryWithML(merchant: String?, rawText: String?) async -> String {
        // 如果 ML 模型可用且商家名称不为空，尝试使用 ML 预测
        if let merchant = merchant,
           !merchant.isEmpty,
           let prediction = await CategoryMLClassifier.shared.predictCategory(for: merchant),
           prediction.confidence >= 0.7 {  // 只在高置信度时使用
            return prediction.category
        }

        // 否则使用规则引擎
        return inferCategory(merchant: merchant, rawText: rawText)
    }

    /// 获取 ML 模型状态
    func getMLModelStatus() -> String {
        if CategoryMLClassifier.shared.isAvailable() {
            return "已加载"
        } else if MLTrainingDataManager.shared.hasEnoughData() {
            return "数据充足，可训练"
        } else {
            let count = MLTrainingDataManager.shared.getTrainingDataCount()
            let needed = MLTrainingDataManager.minimumTrainingDataCount
            return "需要更多数据 (\(count)/\(needed))"
        }
    }
}
