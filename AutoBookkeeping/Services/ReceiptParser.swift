//
//  ReceiptParser.swift
//  AutoBookkeeping
//
//  小票解析器
//  从 OCR 文本中提取交易信息
//

import Foundation

struct ParsedReceipt {
    var amount: Double?
    var merchant: String?
    var date: Date?
    var items: [String] = []
    var rawText: String
}

@MainActor
class ReceiptParser {

    static let shared = ReceiptParser()

    private init() {}

    // MARK: - Public Methods

    /// 解析小票文本
    /// - Parameter text: OCR 识别的文本
    /// - Returns: 解析结果
    func parse(_ text: String) -> ParsedReceipt {
        var receipt = ParsedReceipt(rawText: text)

        receipt.amount = extractAmount(from: text)
        receipt.merchant = extractMerchant(from: text)
        receipt.date = extractDate(from: text)
        receipt.items = extractItems(from: text)

        return receipt
    }

    // MARK: - Private Methods

    /// 提取金额
    private func extractAmount(from text: String) -> Double? {
        // 匹配金额模式（支持多种格式）
        let patterns = [
            "(?:合计|总计|实付|应付|金额)[：:¥￥]?\\s*(\\d+(?:\\.\\d{1,2})?)",  // 合计：123.45
            "(?:RMB|CNY)[：:¥￥]?\\s*(\\d+(?:\\.\\d{1,2})?)",                  // RMB:123.45
            "¥\\s*(\\d+(?:\\.\\d{1,2})?)",                                   // ¥123.45
            "￥\\s*(\\d+(?:\\.\\d{1,2})?)",                                   // ￥123.45
            "(\\d+\\.\\d{2})元",                                             // 123.45元
        ]

        for pattern in patterns {
            if let amount = extractFirstMatch(pattern: pattern, from: text) {
                return amount
            }
        }

        return nil
    }

    /// 提取商家名称
    private func extractMerchant(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)

        // 通常商家名称在前几行
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // 过滤掉太短或包含特定关键词的行
            if trimmed.count >= 2 && trimmed.count <= 30 {
                // 排除常见的非商家名称
                let excludeKeywords = ["小票", "发票", "收据", "欢迎", "谢谢", "地址", "电话", "时间", "日期"]
                if !excludeKeywords.contains(where: { trimmed.contains($0) }) {
                    // 排除纯数字或日期格式
                    if !trimmed.allSatisfy({ $0.isNumber || $0 == "-" || $0 == "/" || $0 == ":" }) {
                        return trimmed
                    }
                }
            }
        }

        return nil
    }

    /// 提取日期
    private func extractDate(from text: String) -> Date? {
        let patterns = [
            "(\\d{4})[-/年](\\d{1,2})[-/月](\\d{1,2})[日号]?\\s*(\\d{1,2})[：:]?(\\d{2})[：:]?(\\d{2})?",  // 2024-01-15 14:30:00
            "(\\d{4})[-/](\\d{2})[-/](\\d{2})\\s+(\\d{2}):(\\d{2})",                                      // 2024/01/15 14:30
            "(\\d{2})[-/](\\d{2})[-/](\\d{2})\\s+(\\d{2}):(\\d{2})",                                      // 24/01/15 14:30
        ]

        for pattern in patterns {
            if let date = extractDateMatch(pattern: pattern, from: text) {
                return date
            }
        }

        return nil
    }

    /// 提取商品项
    private func extractItems(from text: String) -> [String] {
        var items: [String] = []
        let lines = text.components(separatedBy: .newlines)

        // 查找包含价格的行（可能是商品）
        let pricePattern = ".*\\d+\\.\\d{2}.*"

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.range(of: pricePattern, options: .regularExpression) != nil {
                // 排除总计行
                if !trimmed.contains("合计") && !trimmed.contains("总计") && !trimmed.contains("实付") {
                    items.append(trimmed)
                }
            }
        }

        return items
    }

    // MARK: - Helper Methods

    private func extractFirstMatch(pattern: String, from text: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        // 提取第一个捕获组
        if match.numberOfRanges >= 2 {
            let matchRange = match.range(at: 1)
            if let swiftRange = Range(matchRange, in: text) {
                let amountString = String(text[swiftRange])
                return Double(amountString)
            }
        }

        return nil
    }

    private func extractDateMatch(pattern: String, from text: String) -> Date? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        // 提取日期组件
        var components = DateComponents()
        let calendar = Calendar.current

        // 根据捕获组数量判断格式
        if match.numberOfRanges >= 6 {
            // 完整格式：年月日时分秒
            if let yearRange = Range(match.range(at: 1), in: text),
               let monthRange = Range(match.range(at: 2), in: text),
               let dayRange = Range(match.range(at: 3), in: text),
               let hourRange = Range(match.range(at: 4), in: text),
               let minuteRange = Range(match.range(at: 5), in: text) {

                components.year = Int(text[yearRange])
                components.month = Int(text[monthRange])
                components.day = Int(text[dayRange])
                components.hour = Int(text[hourRange])
                components.minute = Int(text[minuteRange])

                // 处理秒（可选）
                if match.numberOfRanges >= 7 {
                    if let secondRange = Range(match.range(at: 6), in: text) {
                        components.second = Int(text[secondRange])
                    }
                }

                return calendar.date(from: components)
            }
        }

        return nil
    }
}
