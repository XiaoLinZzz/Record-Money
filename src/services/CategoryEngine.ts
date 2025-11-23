/**
 * 智能分类引擎
 * 对应 Swift 版本的 CategoryEngine.swift
 * 负责根据商家名称和交易信息推断分类
 */

import AsyncStorage from '@react-native-async-storage/async-storage';

interface CorrectionRecord {
  merchant: string;
  category: string;
}

/**
 * 智能分类引擎类
 * 使用规则匹配的方式进行分类推断
 */
class CategoryEngine {
  private static instance: CategoryEngine;

  // 预设分类规则
  private readonly categoryRules: { [category: string]: string[] } = {
    餐饮: [
      '麦当劳', '肯德基', '星巴克', '喜茶', '奈雪', '瑞幸',
      '美团外卖', '饿了么', '餐厅', '饭店', '咖啡', '奶茶',
      '烧烤', '火锅', '料理', '食品', '小吃', '甜品', '茶饮',
      '快餐', '中餐', '西餐', '日料', '韩餐', '自助餐',
    ],
    交通: [
      '滴滴', '出租', '地铁', '公交', '12306', '高铁', '飞机',
      '火车', '打车', 'uber', 'T3出行', '加油', '停车',
      '充电', '车费', '票务', '租车', '代驾',
    ],
    购物: [
      '淘宝', '京东', '拼多多', '超市', '便利店', '商场',
      '屈臣氏', '万宁', '沃尔玛', '家乐福', '7-11', '罗森',
      '天猫', '唯品会', '苏宁', '国美', '大润发', '永辉',
    ],
    娱乐: [
      '电影', 'KTV', '游戏', 'Steam', 'Apple', '腾讯',
      '网易', '健身', '运动', '游乐', '主题乐园', '剧本杀',
      '密室', '桌游', '游泳', '球馆', '保龄球',
    ],
    生活: [
      '水费', '电费', '物业', '房租', '话费', '网费', '宽带',
      '燃气', '暖气', '维修', '清洁', '搬家', '快递',
    ],
    医疗: [
      '医院', '药店', '体检', '挂号', '诊所', '门诊', '药房',
      '牙科', '眼科', '中医', '理疗', '按摩', '康复',
    ],
    教育: [
      '培训', '课程', '书店', '学费', '教材', '补习', '知识付费',
      '图书', '教育', '学校', '驾校', '兴趣班',
    ],
  };

  // 用户自定义规则
  private userRules: { [category: string]: Set<string> } = {};

  // 用户修正历史
  private correctionHistory: CorrectionRecord[] = [];

  // AsyncStorage keys
  private readonly USER_RULES_KEY = 'userCategoryRules';
  private readonly CORRECTION_HISTORY_KEY = 'categoryCorrections';

  private constructor() {
    this.loadUserRules();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): CategoryEngine {
    if (!CategoryEngine.instance) {
      CategoryEngine.instance = new CategoryEngine();
    }
    return CategoryEngine.instance;
  }

  // MARK: - Public Methods

  /**
   * 推荐分类（供 UI 使用）
   */
  async suggestCategory(merchant: string): Promise<string | null> {
    const trimmedMerchant = merchant.trim();
    if (!trimmedMerchant) {
      return null;
    }

    const category = this.inferCategory(merchant);
    return category === '其他' ? null : category;
  }

  /**
   * 推断分类
   */
  inferCategory(merchant?: string, rawText?: string): string {
    const text = `${merchant || ''} ${rawText || ''}`.toLowerCase();

    if (!text.trim()) {
      return '其他';
    }

    // 1. 优先匹配用户自定义规则
    const userMatch = this.matchUserRules(text);
    if (userMatch) return userMatch;

    // 2. 匹配预设规则
    const presetMatch = this.matchPresetRules(text);
    if (presetMatch) return presetMatch;

    // 3. 正则模式匹配
    const patternMatch = this.matchByPattern(text);
    if (patternMatch) return patternMatch;

    // 4. 字符特征分析
    const characterMatch = this.analyzeCharacteristics(text);
    if (characterMatch) return characterMatch;

    // 5. 检查历史修正记录
    if (merchant) {
      const historyMatch = this.checkCorrectionHistory(merchant);
      if (historyMatch) return historyMatch;
    }

    // 6. 默认分类
    return '其他';
  }

  /**
   * 用户修正分类后的学习
   */
  async learnFromUserCorrection(
    merchant: string,
    correctedCategory: string
  ): Promise<void> {
    const normalizedMerchant = merchant.toLowerCase();

    // 添加到用户规则
    if (!this.userRules[correctedCategory]) {
      this.userRules[correctedCategory] = new Set();
    }
    this.userRules[correctedCategory].add(normalizedMerchant);

    // 记录修正历史
    this.correctionHistory.push({
      merchant: normalizedMerchant,
      category: correctedCategory,
    });

    // 保存到持久化存储
    await this.saveUserRules();
  }

  /**
   * 获取分类的匹配置信度
   */
  getConfidence(merchant: string, category: string): number {
    const text = merchant.toLowerCase();

    // 用户规则匹配：最高置信度
    const userKeywords = this.userRules[category];
    if (userKeywords) {
      for (const keyword of userKeywords) {
        if (text.includes(keyword)) {
          return 1.0;
        }
      }
    }

    // 预设规则匹配：高置信度
    const keywords = this.categoryRules[category];
    if (keywords) {
      for (const keyword of keywords) {
        if (text.includes(keyword.toLowerCase())) {
          return 0.8;
        }
      }
    }

    return 0.0;
  }

  // MARK: - Private Methods

  /**
   * 匹配用户自定义规则
   */
  private matchUserRules(text: string): string | null {
    for (const [categoryName, keywords] of Object.entries(this.userRules)) {
      for (const keyword of keywords) {
        if (text.includes(keyword)) {
          return categoryName;
        }
      }
    }
    return null;
  }

  /**
   * 匹配预设规则
   */
  private matchPresetRules(text: string): string | null {
    // 按关键词数量排序（避免泛化匹配）
    const sortedCategories = Object.entries(this.categoryRules).sort(
      (a, b) => b[1].length - a[1].length
    );

    for (const [categoryName, keywords] of sortedCategories) {
      for (const keyword of keywords) {
        if (text.includes(keyword.toLowerCase())) {
          return categoryName;
        }
      }
    }

    return null;
  }

  /**
   * 正则模式匹配
   */
  private matchByPattern(text: string): string | null {
    const patterns: Array<{ pattern: RegExp; category: string }> = [
      // 餐饮相关
      { pattern: /[咖啡茶饮]/, category: '餐饮' },
      { pattern: /[餐厅饭店]/, category: '餐饮' },
      { pattern: /外卖/, category: '餐饮' },

      // 医疗相关
      { pattern: /[医院药店诊所]/, category: '医疗' },
      { pattern: /[体检挂号]/, category: '医疗' },

      // 娱乐相关
      { pattern: /[电影院影城]/, category: '娱乐' },
      { pattern: /KTV/i, category: '娱乐' },

      // 购物相关
      { pattern: /[超市商场]/, category: '购物' },
      { pattern: /[便利店]/, category: '购物' },

      // 交通相关
      { pattern: /[地铁公交]/, category: '交通' },
      { pattern: /[出租车]/, category: '交通' },
      { pattern: /[加油站]/, category: '交通' },

      // 生活相关
      { pattern: /[水电费]/, category: '生活' },
      { pattern: /[物业]/, category: '生活' },
    ];

    for (const { pattern, category } of patterns) {
      if (pattern.test(text)) {
        return category;
      }
    }

    return null;
  }

  /**
   * 字符特征分析
   */
  private analyzeCharacteristics(text: string): string | null {
    // 包含"店"字的处理
    if (text.includes('店')) {
      if (text.includes('饭') || text.includes('餐') || text.includes('食')) {
        return '餐饮';
      }
      if (text.includes('药')) {
        return '医疗';
      }
      if (text.includes('书')) {
        return '教育';
      }
      // 默认为购物
      return '购物';
    }

    // 包含"院"字
    if (text.includes('院')) {
      if (text.includes('医') || text.includes('诊')) {
        return '医疗';
      }
      if (text.includes('影') || text.includes('电影')) {
        return '娱乐';
      }
    }

    // 包含"场"字
    if (text.includes('场')) {
      if (text.includes('商')) {
        return '购物';
      }
      if (text.includes('停车')) {
        return '交通';
      }
    }

    return null;
  }

  /**
   * 检查修正历史
   */
  private checkCorrectionHistory(merchant: string): string | null {
    const normalizedMerchant = merchant.toLowerCase();

    // 查找历史记录中完全匹配的商家
    const exactMatch = this.correctionHistory.find(
      record => record.merchant === normalizedMerchant
    );
    if (exactMatch) return exactMatch.category;

    // 查找部分匹配
    const partialMatch = this.correctionHistory.find(
      record =>
        normalizedMerchant.includes(record.merchant) ||
        record.merchant.includes(normalizedMerchant)
    );
    if (partialMatch) return partialMatch.category;

    return null;
  }

  // MARK: - Persistence

  /**
   * 加载用户规则
   */
  private async loadUserRules(): Promise<void> {
    try {
      // 加载用户自定义规则
      const rulesData = await AsyncStorage.getItem(this.USER_RULES_KEY);
      if (rulesData) {
        const parsed = JSON.parse(rulesData);
        this.userRules = {};
        for (const [category, keywords] of Object.entries(parsed)) {
          this.userRules[category] = new Set(keywords as string[]);
        }
      }

      // 加载修正历史
      const historyData = await AsyncStorage.getItem(
        this.CORRECTION_HISTORY_KEY
      );
      if (historyData) {
        this.correctionHistory = JSON.parse(historyData);
      }
    } catch (error) {
      console.error('Failed to load user rules:', error);
    }
  }

  /**
   * 保存用户规则
   */
  private async saveUserRules(): Promise<void> {
    try {
      // 保存用户自定义规则
      const rulesData: { [category: string]: string[] } = {};
      for (const [category, keywords] of Object.entries(this.userRules)) {
        rulesData[category] = Array.from(keywords);
      }
      await AsyncStorage.setItem(
        this.USER_RULES_KEY,
        JSON.stringify(rulesData)
      );

      // 保存修正历史（最多保存 1000 条）
      const recentHistory = this.correctionHistory.slice(-1000);
      await AsyncStorage.setItem(
        this.CORRECTION_HISTORY_KEY,
        JSON.stringify(recentHistory)
      );
    } catch (error) {
      console.error('Failed to save user rules:', error);
    }
  }

  /**
   * 清除用户数据
   */
  async clearUserData(): Promise<void> {
    this.userRules = {};
    this.correctionHistory = [];
    await AsyncStorage.removeItem(this.USER_RULES_KEY);
    await AsyncStorage.removeItem(this.CORRECTION_HISTORY_KEY);
  }

  /**
   * 导出用户规则（用于备份）
   */
  async exportUserRules(): Promise<string> {
    const exportData = {
      rules: {} as { [category: string]: string[] },
      history: this.correctionHistory,
    };

    for (const [category, keywords] of Object.entries(this.userRules)) {
      exportData.rules[category] = Array.from(keywords);
    }

    return JSON.stringify(exportData);
  }

  /**
   * 导入用户规则（从备份恢复）
   */
  async importUserRules(data: string): Promise<void> {
    try {
      const parsed = JSON.parse(data);

      if (parsed.rules) {
        this.userRules = {};
        for (const [category, keywords] of Object.entries(parsed.rules)) {
          this.userRules[category] = new Set(keywords as string[]);
        }
      }

      if (parsed.history) {
        this.correctionHistory = parsed.history;
      }

      await this.saveUserRules();
    } catch (error) {
      throw new Error('Invalid data format');
    }
  }

  // MARK: - Statistics

  /**
   * 获取用户规则统计
   */
  getUserRulesStatistics(): { [category: string]: number } {
    const stats: { [category: string]: number } = {};
    for (const [category, keywords] of Object.entries(this.userRules)) {
      stats[category] = keywords.size;
    }
    return stats;
  }

  /**
   * 获取修正次数统计
   */
  getCorrectionStatistics(): { [category: string]: number } {
    const stats: { [category: string]: number } = {};
    for (const record of this.correctionHistory) {
      stats[record.category] = (stats[record.category] || 0) + 1;
    }
    return stats;
  }

  /**
   * 获取训练数据数量
   */
  getTrainingDataCount(): number {
    return this.correctionHistory.length;
  }

  /**
   * 导出训练数据（用于机器学习）
   */
  exportTrainingDataForML(): string {
    let csv = 'text,label\n';

    for (const record of this.correctionHistory) {
      const escapedMerchant = record.merchant.replace(/"/g, '""');
      csv += `"${escapedMerchant}","${record.category}"\n`;
    }

    return csv;
  }

  /**
   * 获取训练数据数组
   */
  getTrainingData(): Array<{ text: string; label: string }> {
    return this.correctionHistory.map(record => ({
      text: record.merchant,
      label: record.category,
    }));
  }
}

export default CategoryEngine.getInstance();
