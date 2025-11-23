/**
 * 自然语言解析器
 * 对应 Swift 版本的 NLPParser.swift
 * 解析用户输入的自然语言，提取交易信息
 */

export interface ParsedTransaction {
  amount?: number;
  merchant?: string;
  category?: string;
  date?: Date;
  transactionType: 'expense' | 'income';
  rawInput: string;
  confidence: number;
}

/**
 * NLP 解析器类
 */
class NLPParser {
  private static instance: NLPParser;

  // 分类关键词
  private readonly categoryKeywords: { [category: string]: string[] } = {
    餐饮: ['吃', '餐', '饭', '星巴克', '麦当劳', '肯德基', '咖啡', '奶茶', '火锅', '烧烤', '外卖', '美团', '饿了么'],
    交通: ['打车', '滴滴', '出租', '地铁', '公交', '加油', '停车', '高速', 'uber'],
    购物: ['买', '购', '淘宝', '京东', '拼多多', '衣服', '鞋', '包', '化妆品'],
    娱乐: ['电影', 'KTV', '游戏', '唱歌', '娱乐', '演唱会', '游乐园'],
    医疗: ['医院', '药', '看病', '体检', '挂号', '药店'],
    教育: ['书', '课程', '培训', '学费', '教育', '学习'],
    生活: ['房租', '水费', '电费', '网费', '话费', '物业'],
  };

  // 时间关键词（秒）
  private readonly timeKeywords: { [keyword: string]: number } = {
    今天: 0,
    今日: 0,
    刚才: 0,
    刚刚: 0,
    昨天: -86400 * 1000,
    昨日: -86400 * 1000,
    前天: -172800 * 1000,
    大前天: -259200 * 1000,
  };

  // 交易类型关键词
  private readonly incomeKeywords = ['收到', '收入', '进账', '工资', '奖金', '转入', '赚'];
  private readonly expenseKeywords = ['花', '支出', '付', '买', '消费', '转出', '用'];

  // 常见词汇（需要过滤）
  private readonly commonWords = new Set([
    '今天', '昨天', '前天', '刚才', '刚刚', '上午', '下午', '中午', '晚上', '早上', '夜里',
    '花了', '用了', '买了', '吃了', '喝了', '去了', '在', '的', '了', '块', '元', '钱',
    '一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '百', '千', '万',
  ]);

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): NLPParser {
    if (!NLPParser.instance) {
      NLPParser.instance = new NLPParser();
    }
    return NLPParser.instance;
  }

  /**
   * 解析自然语言输入
   */
  parse(input: string): ParsedTransaction {
    const transaction: ParsedTransaction = {
      rawInput: input,
      transactionType: 'expense',
      confidence: 0,
    };

    // 1. 提取金额
    transaction.amount = this.extractAmount(input);

    // 2. 提取商家
    transaction.merchant = this.extractMerchant(input);

    // 3. 提取分类
    transaction.category = this.extractCategory(input);

    // 4. 提取时间
    transaction.date = this.extractDate(input);

    // 5. 判断收入/支出
    transaction.transactionType = this.extractTransactionType(input);

    // 6. 计算置信度
    transaction.confidence = this.calculateConfidence(transaction);

    return transaction;
  }

  /**
   * 提取金额
   */
  private extractAmount(input: string): number | undefined {
    // 金额匹配模式
    const patterns = [
      /(\d+\.?\d{0,2})(?:元|块|rmb|RMB)/,  // 35.50元
      /(?:¥|￥)(\d+(?:\.\d{1,2})?)/,      // ¥35.50
      /(\d+\.?\d{0,2})/,                 // 35.5 (纯数字，作为最后的选择)
    ];

    for (const pattern of patterns) {
      const match = input.match(pattern);
      if (match && match[1]) {
        const amount = parseFloat(match[1]);
        if (!isNaN(amount) && amount > 0) {
          return amount;
        }
      }
    }

    return undefined;
  }

  /**
   * 提取商家名称
   */
  private extractMerchant(input: string): string | undefined {
    // 移除金额部分
    let cleanedInput = input.replace(/(\d+\.?\d{0,2})(?:元|块|rmb|RMB)?/g, '');
    cleanedInput = cleanedInput.replace(/(?:¥|￥)(\d+(?:\.\d{1,2})?)/g, '');

    // 移除时间关键词
    Object.keys(this.timeKeywords).forEach(keyword => {
      cleanedInput = cleanedInput.replace(keyword, '');
    });

    // 移除常见动词
    ['花了', '用了', '买了', '吃了', '喝了', '去了', '在', '打车', '买'].forEach(word => {
      cleanedInput = cleanedInput.replace(word, '');
    });

    // 简单分词（按空格、标点分隔）
    const words = cleanedInput.split(/[\s，。！？、]+/).filter(w => w.length >= 2);

    // 过滤掉常见词汇
    const merchants = words.filter(word => {
      return !this.commonWords.has(word) &&
             !this.isTimeKeyword(word) &&
             !this.isExpenseKeyword(word) &&
             !this.isIncomeKeyword(word);
    });

    // 返回第一个候选商家
    if (merchants.length > 0) {
      return merchants[0];
    }

    // 如果没有找到，尝试提取第一个中文词组（2-8个字符）
    const match = cleanedInput.match(/[\u4e00-\u9fa5]{2,8}/);
    if (match) {
      const word = match[0];
      if (!this.commonWords.has(word)) {
        return word;
      }
    }

    return undefined;
  }

  /**
   * 提取分类
   */
  private extractCategory(input: string): string | undefined {
    // 遍历分类关键词，查找匹配
    for (const [category, keywords] of Object.entries(this.categoryKeywords)) {
      for (const keyword of keywords) {
        if (input.includes(keyword)) {
          return category;
        }
      }
    }

    return undefined;
  }

  /**
   * 提取日期
   */
  private extractDate(input: string): Date | undefined {
    const now = new Date();

    // 检查时间关键词
    for (const [keyword, offset] of Object.entries(this.timeKeywords)) {
      if (input.includes(keyword)) {
        return new Date(now.getTime() + offset);
      }
    }

    // 检查具体时间段
    let date = new Date(now);

    if (input.includes('上午') || input.includes('早上')) {
      date.setHours(9, 0, 0, 0);
    } else if (input.includes('中午')) {
      date.setHours(12, 0, 0, 0);
    } else if (input.includes('下午')) {
      date.setHours(15, 0, 0, 0);
    } else if (input.includes('晚上') || input.includes('夜里')) {
      date.setHours(19, 0, 0, 0);
    }

    return date;
  }

  /**
   * 提取交易类型
   */
  private extractTransactionType(input: string): 'expense' | 'income' {
    // 检查收入关键词
    for (const keyword of this.incomeKeywords) {
      if (input.includes(keyword)) {
        return 'income';
      }
    }

    // 默认为支出
    return 'expense';
  }

  /**
   * 计算置信度
   */
  private calculateConfidence(transaction: ParsedTransaction): number {
    let confidence = 0;

    // 金额权重：40%
    if (transaction.amount !== undefined && transaction.amount > 0) {
      confidence += 0.4;
    }

    // 商家权重：30%
    if (transaction.merchant && transaction.merchant.length >= 2) {
      confidence += 0.3;
    }

    // 分类权重：20%
    if (transaction.category) {
      confidence += 0.2;
    }

    // 时间权重：10%
    if (transaction.date) {
      confidence += 0.1;
    }

    return confidence;
  }

  /**
   * 检查是否为时间关键词
   */
  private isTimeKeyword(word: string): boolean {
    return Object.keys(this.timeKeywords).includes(word) ||
           ['上午', '下午', '中午', '晚上', '早上', '夜里'].includes(word);
  }

  /**
   * 检查是否为支出关键词
   */
  private isExpenseKeyword(word: string): boolean {
    return this.expenseKeywords.some(keyword => word.includes(keyword));
  }

  /**
   * 检查是否为收入关键词
   */
  private isIncomeKeyword(word: string): boolean {
    return this.incomeKeywords.some(keyword => word.includes(keyword));
  }
}

export default NLPParser.getInstance();
