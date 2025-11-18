//
//  Category.swift
//  AutoBookkeeping
//
//  分类数据模型
//

import Foundation
import SwiftData

/// 分类模型
@Model
class Category {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: UUID

    /// 分类名称
    var name: String

    /// 图标名称 (SF Symbols)
    var icon: String

    /// 颜色（十六进制）
    var color: String

    /// 分类关键词（用于智能匹配）
    var keywords: [String]

    /// 是否为系统预设分类
    var isSystem: Bool

    /// 排序顺序
    var order: Int

    /// 创建时间
    var createdAt: Date

    // MARK: - Computed Properties

    /// 颜色对象（用于 UI）
    var colorHex: String {
        color
    }

    // MARK: - Initialization

    /// 初始化分类
    /// - Parameters:
    ///   - name: 分类名称
    ///   - icon: 图标名称
    ///   - color: 颜色（十六进制）
    ///   - keywords: 关键词列表
    ///   - isSystem: 是否为系统预设
    ///   - order: 排序顺序
    init(
        name: String,
        icon: String,
        color: String = "#007AFF",
        keywords: [String] = [],
        isSystem: Bool = false,
        order: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.keywords = keywords
        self.isSystem = isSystem
        self.order = order
        self.createdAt = Date()
    }

    // MARK: - Methods

    /// 添加关键词
    func addKeyword(_ keyword: String) {
        if !keywords.contains(keyword) {
            keywords.append(keyword)
        }
    }

    /// 移除关键词
    func removeKeyword(_ keyword: String) {
        keywords.removeAll { $0 == keyword }
    }

    /// 检查是否匹配关键词
    func matches(text: String) -> Bool {
        let lowercaseText = text.lowercased()
        return keywords.contains { lowercaseText.contains($0.lowercased()) }
    }
}

// MARK: - Default Categories

extension Category {
    /// 默认分类列表
    static var defaultCategories: [Category] {
        [
            Category(
                name: "餐饮",
                icon: "fork.knife",
                color: "#FF6B6B",
                keywords: [
                    "麦当劳", "肯德基", "星巴克", "喜茶", "奈雪", "瑞幸",
                    "美团外卖", "饿了么", "餐厅", "饭店", "咖啡", "奶茶",
                    "烧烤", "火锅", "料理", "食品", "小吃", "甜品"
                ],
                isSystem: true,
                order: 1
            ),
            Category(
                name: "交通",
                icon: "car.fill",
                color: "#4ECDC4",
                keywords: [
                    "滴滴", "出租", "地铁", "公交", "12306", "高铁", "飞机",
                    "火车", "打车", "uber", "T3出行", "加油", "停车"
                ],
                isSystem: true,
                order: 2
            ),
            Category(
                name: "购物",
                icon: "cart.fill",
                color: "#FFE66D",
                keywords: [
                    "淘宝", "京东", "拼多多", "超市", "便利店", "商场",
                    "屈臣氏", "万宁", "沃尔玛", "家乐福", "7-11", "罗森"
                ],
                isSystem: true,
                order: 3
            ),
            Category(
                name: "娱乐",
                icon: "gamecontroller.fill",
                color: "#A8E6CF",
                keywords: [
                    "电影", "KTV", "游戏", "Steam", "Apple", "腾讯",
                    "网易", "健身", "运动", "游乐", "主题乐园"
                ],
                isSystem: true,
                order: 4
            ),
            Category(
                name: "生活",
                icon: "house.fill",
                color: "#FFDAC1",
                keywords: [
                    "水费", "电费", "物业", "房租", "话费", "网费", "宽带"
                ],
                isSystem: true,
                order: 5
            ),
            Category(
                name: "医疗",
                icon: "cross.case.fill",
                color: "#FF8B94",
                keywords: [
                    "医院", "药店", "体检", "挂号", "诊所", "门诊", "药房"
                ],
                isSystem: true,
                order: 6
            ),
            Category(
                name: "教育",
                icon: "book.fill",
                color: "#C7CEEA",
                keywords: [
                    "培训", "课程", "书店", "学费", "教材", "补习", "知识付费"
                ],
                isSystem: true,
                order: 7
            ),
            Category(
                name: "其他",
                icon: "ellipsis.circle.fill",
                color: "#B4A7D6",
                keywords: [],
                isSystem: true,
                order: 99
            )
        ]
    }

    /// 预览数据
    static var preview: Category {
        Category(
            name: "餐饮",
            icon: "fork.knife",
            color: "#FF6B6B",
            keywords: ["星巴克", "麦当劳"]
        )
    }
}
