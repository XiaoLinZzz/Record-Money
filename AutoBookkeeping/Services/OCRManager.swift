//
//  OCRManager.swift
//  AutoBookkeeping
//
//  OCR 文字识别管理器
//  使用 Vision Framework 进行小票文字识别（支持中文）
//

import Vision
import UIKit

@MainActor
class OCRManager {

    static let shared = OCRManager()

    private init() {}

    // MARK: - Types

    enum OCRError: LocalizedError {
        case invalidImage
        case noTextFound
        case recognitionFailed(Error)

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "图片格式无效"
            case .noTextFound:
                return "未识别到文字"
            case .recognitionFailed(let error):
                return "识别失败: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Public Methods

    /// 识别图片中的文本（支持中文）
    /// - Parameter image: 要识别的图片
    /// - Returns: 识别出的完整文本
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                if recognizedStrings.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            // 配置识别选项
            request.recognitionLevel = .accurate  // 准确度优先
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]  // 支持简体中文、繁体中文、英文
            request.usesLanguageCorrection = true  // 启用语言纠错

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }

    /// 识别图片中的文本（带置信度）
    /// - Parameter image: 要识别的图片
    /// - Returns: 识别结果数组（文本 + 置信度）
    func recognizeTextWithConfidence(from image: UIImage) async throws -> [(text: String, confidence: Float)] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let results = observations.compactMap { observation -> (String, Float)? in
                    guard let candidate = observation.topCandidates(1).first else {
                        return nil
                    }
                    return (candidate.string, candidate.confidence)
                }

                if results.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                continuation.resume(returning: results)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }
}
