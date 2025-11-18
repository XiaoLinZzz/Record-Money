//
//  CategoryEngine.swift
//  AutoBookkeeping
//
//  智能分类引擎
//  负责根据商家名称和交易信息推断分类
//

import Foundation

/// 智能分类引擎
/// 使用规则匹配 + 机器学习（未来）的方式进行分类推断
@MainActor
class CategoryEngine {

    // MARK: - Singleton

    static let shared = CategoryEngine()

    private init() {
        loadUserRules()
    }

    // MARK: - Properties

    /// 预设分类规则
    private let categoryRules: [String: [String]] = [
        "餐饮": [
            "麦当劳", "肯德基", "星巴克", "喜茶", "奈雪", "瑞幸",
            "美团外卖", "饿了么", "餐厅", "饭店", "咖啡", "奶茶",
            "烧烤", "火锅", "料理", "食品", "小吃", "甜品", "茶饮",
            "快餐", "中餐", "西餐", "日料", "韩餐", "自助餐"
        ],
        "交通": [
            "滴滴", "出租", "地铁", "公交", "12306", "高铁", "飞机",
            "火车", "打车", "uber", "T3出行", "加油", "停车",
            "充电", "车费", "票务", "租车", "代驾"
        ],
        "购物": [
            "淘宝", "京东", "拼多多", "超市", "便利店", "商场",
            "屈臣氏", "万宁", "沃尔玛", "家乐福", "7-11", "罗森",
            "天猫", "唯品会", "苏宁", "国美", "大润发", "永辉"
        ],
        "娱乐": [
            "电影", "KTV", "游戏", "Steam", "Apple", "腾讯",
            "网易", "健身", "运动", "游乐", "主题乐园", "剧本杀",
            "密室", "桌游", "游泳", "球馆", "保龄球"
        ],
        "生活": [
            "水费", "电费", "物业", "房租", "话费", "网费", "宽带",
            "燃气", "暖气", "维修", "清洁", "搬家", "快递"
        ],
        "医疗": [
            "医院", "药店", "体检", "挂号", "诊所", "门诊", "药房",
            "牙科", "眼科", "中医", "理疗", "按摩", "康复"
        ],
        "教育": [
            "培训", "课程", "书店", "学费", "教材", "补习", "知识付费",
            "图书", "教育", "学校", "驾校", "兴趣班"
        ]
    ]

    /// 用户自定义规则（从持久化存储加载）
    private var userRules: [String: Set<String>] = [:]

    /// 用户修正历史（用于学习）
    private var correctionHistory: [(merchant: String, category: String)] = []

    // MARK: - Public Methods

    /// 推荐分类（供 UI 使用）
    /// - Parameter merchant: 商家名称
    /// - Returns: 推荐的分类名称
    func suggestCategory(for merchant: String) async -> String? {
        // 如果商家名称为空，返回 nil
        guard !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        // 使用推断引擎
        let category = inferCategory(merchant: merchant, rawText: nil)

        // 如果是"其他"，则不推荐
        return category == "其他" ? nil : category
    }

    /// 推断分类
    /// - Parameters:
    ///   - merchant: 商家名称
    ///   - rawText: OCR 识别的原始文本
    /// - Returns: 分类名称
    func inferCategory(merchant: String?, rawText: String?) -> String {
        // 组合文本用于匹配
        let text = "\(merchant ?? "") \(rawText ?? "")".lowercased()

        // 空文本返回默认分类
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "其他"
        }

        // 1. 优先匹配用户自定义规则
        if let category = matchUserRules(text: text) {
            return category
        }

        // 2. 匹配预设规则
        if let category = matchPresetRules(text: text) {
            return category
        }

        // 3. 正则模式匹配
        if let category = matchByPattern(text: text) {
            return category
        }

        // 4. 字符特征分析
        if let category = analyzeCharacteristics(text: text) {
            return category
        }

        // 5. 检查历史修正记录
        if let category = checkCorrectionHistory(merchant: merchant ?? "") {
            return category
        }

        // 6. 默认分类
        return "其他"
    }

    /// 用户修正分类后的学习
    /// - Parameters:
    ///   - merchant: 商家名称
    ///   - correctedCategory: 用户修正后的分类
    func learnFromUserCorrection(merchant: String, correctedCategory: String) {
        // 添加到用户规则
        if userRules[correctedCategory] == nil {
            userRules[correctedCategory] = Set<String>()
        }

        let normalizedMerchant = merchant.lowercased()
        userRules[correctedCategory]?.insert(normalizedMerchant)

        // 记录修正历史
        correctionHistory.append((merchant: normalizedMerchant, category: correctedCategory))

        // 保存到持久化存储
        saveUserRules()
    }

    /// 获取分类的匹配置信度
    /// - Parameters:
    ///   - merchant: 商家名称
    ///   - category: 分类名称
    /// - Returns: 置信度 (0.0 - 1.0)
    func getConfidence(merchant: String, category: String) -> Double {
        let text = merchant.lowercased()

        // 用户规则匹配：最高置信度
        if let userKeywords = userRules[category],
           userKeywords.contains(where: { text.contains($0) }) {
            return 1.0
        }

        // 预设规则匹配：高置信度
        if let keywords = categoryRules[category],
           keywords.contains(where: { text.contains($0.lowercased()) }) {
            return 0.8
        }

        // 其他情况：低置信度
        return 0.0
    }

    // MARK: - Private Methods

    /// 匹配用户自定义规则
    private func matchUserRules(text: String) -> String? {
        for (categoryName, keywords) in userRules {
            for keyword in keywords {
                if text.contains(keyword) {
                    return categoryName
                }
            }
        }
        return nil
    }

    /// 匹配预设规则
    private func matchPresetRules(text: String) -> String? {
        // 使用优先级排序，避免误匹配
        let sortedCategories = categoryRules.sorted { lhs, rhs in
            // 关键词越多，优先级越低（避免泛化匹配）
            lhs.value.count > rhs.value.count
        }

        for (categoryName, keywords) in sortedCategories {
            for keyword in keywords {
                if text.contains(keyword.lowercased()) {
                    return categoryName
                }
            }
        }

        return nil
    }

    /// 正则模式匹配
    private func matchByPattern(text: String) -> String? {
        let patterns: [(pattern: String, category: String)] = [
            // 餐饮相关
            (".*[咖啡茶饮].*", "餐饮"),
            (".*[餐厅饭店].*", "餐饮"),
            (".*外卖.*", "餐饮"),

            // 医疗相关
            (".*[医院药店诊所].*", "医疗"),
            (".*[体检挂号].*", "医疗"),

            // 娱乐相关
            (".*[电影院影城].*", "娱乐"),
            (".*KTV.*", "娱乐"),

            // 购物相关
            (".*[超市商场].*", "购物"),
            (".*[便利店].*", "购物"),

            // 交通相关
            (".*[地铁公交].*", "交通"),
            (".*[出租车].*", "交通"),
            (".*[加油站].*", "交通"),

            // 生活相关
            (".*[水电费].*", "生活"),
            (".*[物业].*", "生活")
        ]

        for (pattern, categoryName) in patterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return categoryName
            }
        }

        return nil
    }

    /// 字符特征分析
    private func analyzeCharacteristics(text: String) -> String? {
        // 包含"店"字的处理
        if text.contains("店") {
            if text.contains("饭") || text.contains("餐") || text.contains("食") {
                return "餐饮"
            }
            if text.contains("药") {
                return "医疗"
            }
            if text.contains("书") {
                return "教育"
            }
            // 默认为购物
            return "购物"
        }

        // 包含"院"字
        if text.contains("院") {
            if text.contains("医") || text.contains("诊") {
                return "医疗"
            }
            if text.contains("影") || text.contains("电影") {
                return "娱乐"
            }
        }

        // 包含"场"字
        if text.contains("场") {
            if text.contains("商") {
                return "购物"
            }
            if text.contains("停车") {
                return "交通"
            }
        }

        return nil
    }

    /// 检查修正历史
    private func checkCorrectionHistory(merchant: String) -> String? {
        let normalizedMerchant = merchant.lowercased()

        // 查找历史记录中完全匹配的商家
        if let record = correctionHistory.first(where: {
            $0.merchant == normalizedMerchant
        }) {
            return record.category
        }

        // 查找部分匹配
        if let record = correctionHistory.first(where: {
            normalizedMerchant.contains($0.merchant) || $0.merchant.contains(normalizedMerchant)
        }) {
            return record.category
        }

        return nil
    }

    // MARK: - Persistence

    private let userRulesKey = "userCategoryRules"
    private let correctionHistoryKey = "categoryCorrections"

    /// 加载用户规则
    private func loadUserRules() {
        // 加载用户自定义规则
        if let data = UserDefaults.standard.data(forKey: userRulesKey),
           let decoded = try? JSONDecoder().decode([String: Set<String>].self, from: data) {
            userRules = decoded
        }

        // 加载修正历史
        if let data = UserDefaults.standard.data(forKey: correctionHistoryKey),
           let decoded = try? JSONDecoder().decode([(merchant: String, category: String)].self, from: data) {
            correctionHistory = decoded
        }
    }

    /// 保存用户规则
    private func saveUserRules() {
        // 保存用户自定义规则
        if let encoded = try? JSONEncoder().encode(userRules) {
            UserDefaults.standard.set(encoded, forKey: userRulesKey)
        }

        // 保存修正历史（最多保存 1000 条）
        let recentHistory = Array(correctionHistory.suffix(1000))
        if let encoded = try? JSONEncoder().encode(recentHistory) {
            UserDefaults.standard.set(encoded, forKey: correctionHistoryKey)
        }
    }

    /// 清除用户数据
    func clearUserData() {
        userRules.removeAll()
        correctionHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: userRulesKey)
        UserDefaults.standard.removeObject(forKey: correctionHistoryKey)
    }

    /// 导出用户规则（用于备份）
    func exportUserRules() -> Data? {
        let export = [
            "rules": userRules,
            "history": correctionHistory.map { ["merchant": $0.merchant, "category": $0.category] }
        ] as [String : Any]

        return try? JSONSerialization.data(withJSONObject: export)
    }

    /// 导入用户规则（从备份恢复）
    func importUserRules(from data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "CategoryEngine", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid data format"
            ])
        }

        if let rules = json["rules"] as? [String: Set<String>] {
            userRules = rules
        }

        if let history = json["history"] as? [[String: String]] {
            correctionHistory = history.compactMap { dict in
                guard let merchant = dict["merchant"],
                      let category = dict["category"] else {
                    return nil
                }
                return (merchant: merchant, category: category)
            }
        }

        saveUserRules()
    }
}

// MARK: - Statistics

extension CategoryEngine {
    /// 获取用户规则统计
    func getUserRulesStatistics() -> [String: Int] {
        var stats: [String: Int] = [:]
        for (category, keywords) in userRules {
            stats[category] = keywords.count
        }
        return stats
    }

    /// 获取修正次数统计
    func getCorrectionStatistics() -> [String: Int] {
        var stats: [String: Int] = [:]
        for record in correctionHistory {
            stats[record.category, default: 0] += 1
        }
        return stats
    }

    /// 获取训练数据数量
    func getTrainingDataCount() -> Int {
        return correctionHistory.count
    }

    /// 导出训练数据（用于 CoreML 训练）
    /// - Returns: CSV 格式的训练数据
    func exportTrainingDataForML() -> String {
        var csv = "text,label\n"

        for record in correctionHistory {
            // 转义逗号和引号
            let escapedMerchant = record.merchant.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(escapedMerchant)\",\"\(record.category)\"\n"
        }

        return csv
    }

    /// 获取训练数据数组（用于 CoreML 训练）
    func getTrainingData() -> [(text: String, label: String)] {
        return correctionHistory.map { (text: $0.merchant, label: $0.category) }
    }
}
