/**
 * 分类数据模型
 * 对应 Swift 版本的 Category.swift
 */

import { Model } from '@nozbe/watermelondb';
import { field, date, readonly } from '@nozbe/watermelondb/decorators';

export interface CategoryData {
  name: string;
  icon: string;
  color: string;
  keywords: string[];
  isSystem: boolean;
  order: number;
}

export default class Category extends Model {
  static table = 'categories';

  // MARK: - Properties

  /** 分类名称 */
  @field('name') name!: string;

  /** 图标名称 (SF Symbols / Icon name) */
  @field('icon') icon!: string;

  /** 颜色（十六进制） */
  @field('color') color!: string;

  /** 分类关键词（JSON 字符串） */
  @field('keywords') _keywords!: string;

  /** 是否为系统预设分类 */
  @field('is_system') isSystem!: boolean;

  /** 排序顺序 */
  @field('order') order!: number;

  /** 创建时间 */
  @readonly @date('created_at') createdAt!: Date;

  /** 更新时间 */
  @readonly @date('updated_at') updatedAt!: Date;

  // MARK: - Computed Properties

  /** 关键词列表 */
  get keywords(): string[] {
    try {
      return JSON.parse(this._keywords || '[]');
    } catch {
      return [];
    }
  }

  /** 颜色十六进制值 */
  get colorHex(): string {
    return this.color;
  }

  /** 是否为自定义分类 */
  get isCustom(): boolean {
    return !this.isSystem;
  }

  // MARK: - Methods

  /**
   * 添加关键词
   */
  async addKeyword(keyword: string): Promise<void> {
    const currentKeywords = this.keywords;
    if (!currentKeywords.includes(keyword)) {
      await this.update(record => {
        record._keywords = JSON.stringify([...currentKeywords, keyword]);
      });
    }
  }

  /**
   * 移除关键词
   */
  async removeKeyword(keyword: string): Promise<void> {
    const currentKeywords = this.keywords;
    await this.update(record => {
      record._keywords = JSON.stringify(
        currentKeywords.filter(k => k !== keyword)
      );
    });
  }

  /**
   * 检查是否匹配关键词
   */
  matches(text: string): boolean {
    const lowercaseText = text.toLowerCase();
    return this.keywords.some(keyword =>
      lowercaseText.includes(keyword.toLowerCase())
    );
  }

  /**
   * 设置关键词列表
   */
  async setKeywords(keywords: string[]): Promise<void> {
    await this.update(record => {
      record._keywords = JSON.stringify(keywords);
    });
  }
}

// MARK: - Default Categories

/**
 * 默认分类列表
 * 与 Swift 版本保持一致
 */
export const DEFAULT_CATEGORIES: CategoryData[] = [
  {
    name: '餐饮',
    icon: 'fork.knife',
    color: '#FF6B6B',
    keywords: [
      '麦当劳', '肯德基', '星巴克', '喜茶', '奈雪', '瑞幸',
      '美团外卖', '饿了么', '餐厅', '饭店', '咖啡', '奶茶',
      '烧烤', '火锅', '料理', '食品', '小吃', '甜品',
    ],
    isSystem: true,
    order: 1,
  },
  {
    name: '交通',
    icon: 'car.fill',
    color: '#4ECDC4',
    keywords: [
      '滴滴', '出租', '地铁', '公交', '12306', '高铁', '飞机',
      '火车', '打车', 'uber', 'T3出行', '加油', '停车',
    ],
    isSystem: true,
    order: 2,
  },
  {
    name: '购物',
    icon: 'cart.fill',
    color: '#FFE66D',
    keywords: [
      '淘宝', '京东', '拼多多', '超市', '便利店', '商场',
      '屈臣氏', '万宁', '沃尔玛', '家乐福', '7-11', '罗森',
    ],
    isSystem: true,
    order: 3,
  },
  {
    name: '娱乐',
    icon: 'gamecontroller.fill',
    color: '#A8E6CF',
    keywords: [
      '电影', 'KTV', '游戏', 'Steam', 'Apple', '腾讯',
      '网易', '健身', '运动', '游乐', '主题乐园',
    ],
    isSystem: true,
    order: 4,
  },
  {
    name: '生活',
    icon: 'house.fill',
    color: '#FFDAC1',
    keywords: [
      '水费', '电费', '物业', '房租', '话费', '网费', '宽带',
    ],
    isSystem: true,
    order: 5,
  },
  {
    name: '医疗',
    icon: 'cross.case.fill',
    color: '#FF8B94',
    keywords: [
      '医院', '药店', '体检', '挂号', '诊所', '门诊', '药房',
    ],
    isSystem: true,
    order: 6,
  },
  {
    name: '教育',
    icon: 'book.fill',
    color: '#C7CEEA',
    keywords: [
      '培训', '课程', '书店', '学费', '教材', '补习', '知识付费',
    ],
    isSystem: true,
    order: 7,
  },
  {
    name: '其他',
    icon: 'ellipsis.circle.fill',
    color: '#B4A7D6',
    keywords: [],
    isSystem: true,
    order: 99,
  },
];
