/**
 * 交易记录数据模型
 * 对应 Swift 版本的 Transaction.swift
 */

import { Model } from '@nozbe/watermelondb';
import { field, date, readonly } from '@nozbe/watermelondb/decorators';
import { format, isToday, isYesterday } from 'date-fns';

export type TransactionType = 'expense' | 'income';

export default class Transaction extends Model {
  static table = 'transactions';

  // MARK: - Properties

  /** 交易金额 */
  @field('amount') amount!: number;

  /** 商家名称 */
  @field('merchant') merchant!: string;

  /** 分类名称 */
  @field('category_name') categoryName!: string;

  /** 交易类型 (expense/income) */
  @field('type') type!: TransactionType;

  /** 支付方式 (微信/支付宝等) */
  @field('payment_method') paymentMethod?: string;

  /** OCR 识别的原始文本 */
  @field('raw_text') rawText?: string;

  /** 交易时间 */
  @date('timestamp') timestamp!: Date;

  /** 备注 */
  @field('note') note?: string;

  /** 是否已删除 (软删除) */
  @field('is_deleted') isDeleted!: boolean;

  /** 创建时间 */
  @readonly @date('created_at') createdAt!: Date;

  /** 更新时间 */
  @readonly @date('updated_at') updatedAt!: Date;

  // MARK: - Computed Properties

  /** 格式化金额字符串 */
  get formattedAmount(): string {
    return `¥${this.amount.toFixed(2)}`;
  }

  /** 格式化日期字符串 */
  get formattedDate(): string {
    return format(this.timestamp, 'yyyy-MM-dd HH:mm');
  }

  /** 简短日期（今天/昨天/具体日期） */
  get shortDate(): string {
    if (isToday(this.timestamp)) {
      return '今天';
    } else if (isYesterday(this.timestamp)) {
      return '昨天';
    } else {
      return format(this.timestamp, 'MM月dd日');
    }
  }

  /** 是否为支出 */
  get isExpense(): boolean {
    return this.type === 'expense';
  }

  /** 是否为收入 */
  get isIncome(): boolean {
    return this.type === 'income';
  }

  // MARK: - Methods

  /**
   * 更新交易信息
   */
  async updateTransaction(updates: {
    amount?: number;
    merchant?: string;
    categoryName?: string;
    note?: string;
  }): Promise<void> {
    await this.update(record => {
      if (updates.amount !== undefined) {
        record.amount = updates.amount;
      }
      if (updates.merchant !== undefined) {
        record.merchant = updates.merchant;
      }
      if (updates.categoryName !== undefined) {
        record.categoryName = updates.categoryName;
      }
      if (updates.note !== undefined) {
        record.note = updates.note;
      }
    });
  }

  /**
   * 软删除
   */
  async softDelete(): Promise<void> {
    await this.update(record => {
      record.isDeleted = true;
    });
  }

  /**
   * 恢复删除
   */
  async restore(): Promise<void> {
    await this.update(record => {
      record.isDeleted = false;
    });
  }
}
