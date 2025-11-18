//
//  NLPParser.swift
//  AutoBookkeeping
//
//  自然语言解析器
//  解析用户输入的自然语言，提取交易信息
//

import Foundation
import NaturalLanguage

struct ParsedTransaction {
    var amount: Double?
    var merchant: String?
    var category: String?
    var date: Date?
    var transactionType: String = "expense"  // 默认支出
    var rawInput: String
    var confidence: Float = 0.0
}

@MainActor
class NLPParser {

    static let shared = NLPParser()

    private init() {}

    // MARK: - Category Keywords

    private let categoryKeywords: [String: [String]] = [
        "餐饮": ["吃", "餐", "饭", "星巴克", "麦当劳", "肯德基", "咖啡", "奶茶", "火锅", "烧烤", "外卖", "美团", "饿了么"],
        "交通": ["打车", "滴滴", "出租", "地铁", "公交", "加油", "停车", "高速", "uber"],
        "购物": ["买", "购", "淘宝", "京东", "拼多多", "衣服", "鞋", "包", "化妆品"],
        "娱乐": ["电影", "KTV", "游戏", "唱歌", "娱乐", "演唱会", "游乐园"],
        "医疗": ["医院", "药", "看病", "体检", "挂号", "药店"],
        "教育": ["书", "课程", "培训", "学费", "教育", "学习"],
        "生活": ["房租", "水费", "电费", "网费", "话费", "物业"]
    ]

    // MARK: - Time Keywords

    private let timeKeywords: [String: TimeInterval] = [
        "今天": 0,
        "今日": 0,
        "刚才": 0,
        "刚刚": 0,
        "昨天": -86400,
        "昨日": -86400,
        "前天": -172800,
        "大前天": -259200
    ]

    // MARK: - Public Methods

    /// 解析自然语言输入
    /// - Parameter input: 用户输入的自然语言
    /// - Returns: 解析结果
    func parse(_ input: String) -> ParsedTransaction {
        var transaction = ParsedTransaction(rawInput: input)

        // 1. 提取金额
        transaction.amount = extractAmount(from: input)

        // 2. 提取商家
        transaction.merchant = extractMerchant(from: input)

        // 3. 提取分类
        transaction.category = extractCategory(from: input)

        // 4. 提取时间
        transaction.date = extractDate(from: input)

        // 5. 判断收入/支出
        transaction.transactionType = extractTransactionType(from: input)

        // 6. 计算置信度
        transaction.confidence = calculateConfidence(transaction)

        return transaction
    }

    // MARK: - Private Methods

    /// 提取金额
    private func extractAmount(from input: String) -> Double? {
        // 匹配金额模式
        let patterns = [
            "(\\d+\\.\\d{1,2})(?:元|块|rmb|RMB)?",  // 35.50元
            "(\\d+)(?:元|块|rmb|RMB)",              // 35元
            "(?:¥|￥)(\\d+(?:\\.\\d{1,2})?)",      // ¥35.50
        ]

        for pattern in patterns {
            if let amount = extractFirstNumberMatch(pattern: pattern, from: input) {
                return amount
            }
        }

        return nil
    }

    /// 提取商家名称
    private func extractMerchant(from input: String) -> String? {
        // 使用 NaturalLanguage 框架进行命名实体识别
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = input

        var merchants: [(String, Range<String.Index>)] = []

        tagger.enumerateTags(in: input.startIndex..<input.endIndex,
                            unit: .word,
                            scheme: .nameType,
                            options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            // 提取可能的商家名称
            let token = String(input[tokenRange])

            // 过滤掉时间、金额等关键词
            if !isTimeKeyword(token) && !isAmountKeyword(token) && token.count >= 2 {
                merchants.append((token, tokenRange))
            }

            return true
        }

        // 使用词性标注辅助识别
        let linguisticTagger = NSLinguisticTagger(tagSchemes: [.nameType, .lexicalClass], options: 0)
        linguisticTagger.string = input

        let range = NSRange(input.startIndex..., in: input)
        var properNouns: [String] = []

        linguisticTagger.enumerateTags(in: range,
                                       unit: .word,
                                       scheme: .lexicalClass,
                                       options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange, _ in
            if let tag = tag, tag == .noun || tag == .otherWord {
                if let range = Range(tokenRange, in: input) {
                    let word = String(input[range])
                    if word.count >= 2 && !isCommonWord(word) {
                        properNouns.append(word)
                    }
                }
            }
            return true
        }

        // 优先返回专有名词
        if let firstProperNoun = properNouns.first {
            return firstProperNoun
        }

        // 其次返回第一个识别的商家
        if let firstMerchant = merchants.first {
            return firstMerchant.0
        }

        return nil
    }

    /// 提取分类
    private func extractCategory(from input: String) -> String? {
        // 遍历分类关键词，查找匹配
        for (category, keywords) in categoryKeywords {
            for keyword in keywords {
                if input.contains(keyword) {
                    return category
                }
            }
        }

        return nil
    }

    /// 提取日期
    private func extractDate(from input: String) -> Date? {
        let now = Date()

        // 检查时间关键词
        for (keyword, offset) in timeKeywords {
            if input.contains(keyword) {
                return now.addingTimeInterval(offset)
            }
        }

        // 检查具体时间（上午、下午、晚上、中午）
        var date = now
        let calendar = Calendar.current

        if input.contains("上午") || input.contains("早上") {
            date = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        } else if input.contains("中午") {
            date = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        } else if input.contains("下午") {
            date = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date) ?? date
        } else if input.contains("晚上") || input.contains("夜里") {
            date = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: date) ?? date
        }

        return date
    }

    /// 提取交易类型
    private func extractTransactionType(from input: String) -> String {
        let incomeKeywords = ["收入", "赚", "工资", "奖金", "红包", "报销", "退款"]
        let expenseKeywords = ["花", "买", "付", "支出", "消费"]

        for keyword in incomeKeywords {
            if input.contains(keyword) {
                return "income"
            }
        }

        // 默认为支出（更常见）
        return "expense"
    }

    /// 计算置信度
    private func calculateConfidence(_ transaction: ParsedTransaction) -> Float {
        var score: Float = 0.0
        var total: Float = 0.0

        // 金额（权重 40%）
        total += 40
        if transaction.amount != nil {
            score += 40
        }

        // 商家（权重 30%）
        total += 30
        if let merchant = transaction.merchant, merchant.count >= 2 {
            score += 30
        }

        // 分类（权重 20%）
        total += 20
        if transaction.category != nil {
            score += 20
        }

        // 时间（权重 10%）
        total += 10
        if transaction.date != nil {
            score += 10
        }

        return total > 0 ? score / total : 0.0
    }

    // MARK: - Helper Methods

    private func extractFirstNumberMatch(pattern: String, from text: String) -> Double? {
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

    private func isTimeKeyword(_ word: String) -> Bool {
        return timeKeywords.keys.contains(word) ||
               ["上午", "下午", "晚上", "中午", "早上", "夜里"].contains(word)
    }

    private func isAmountKeyword(_ word: String) -> Bool {
        return ["元", "块", "钱", "rmb", "RMB", "¥", "￥"].contains(word)
    }

    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = ["花了", "买了", "去", "在", "的", "了", "是", "和", "有", "个", "我", "你", "他"]
        return commonWords.contains(word)
    }
}
