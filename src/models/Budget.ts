/**
 * 预算数据模型
 * 对应 Swift 版本的 Budget.swift
 */

import { Model } from '@nozbe/watermelondb';
import { field, date, readonly } from '@nozbe/watermelondb/decorators';

export type BudgetPeriod = 'daily' | 'weekly' | 'monthly' | 'yearly';

export const BudgetPeriodDisplay: Record<BudgetPeriod, string> = {
  daily: '每日',
  weekly: '每周',
  monthly: '每月',
  yearly: '每年',
};

export default class Budget extends Model {
  static table = 'budgets';

  // MARK: - Properties

  /** 分类名称（空字符串表示总预算） */
  @field('category_name') categoryName?: string;

  /** 预算金额 */
  @field('amount') amount!: number;

  /** 预算周期类型 (daily/weekly/monthly/yearly) */
  @field('period') period!: BudgetPeriod;

  /** 开始日期 */
  @date('start_date') startDate!: Date;

  /** 预警阈值（0-1，默认0.9表示90%） */
  @field('alert_threshold') alertThreshold!: number;

  /** 是否激活 */
  @field('is_active') isActive!: boolean;

  /** 创建时间 */
  @readonly @date('created_at') createdAt!: Date;

  /** 更新时间 */
  @date('updated_at') updatedAt!: Date;

  // MARK: - Computed Properties

  /** 是否为总预算 */
  get isTotalBudget(): boolean {
    return !this.categoryName || this.categoryName === '' || this.categoryName === '总预算';
  }

  /** 显示名称 */
  get displayName(): string {
    return this.isTotalBudget ? '总预算' : (this.categoryName || '未知');
  }

  /** 预算周期显示文本 */
  get periodDisplayText(): string {
    return BudgetPeriodDisplay[this.period] || '每月';
  }

  /** 格式化预算金额 */
  get formattedAmount(): string {
    return `¥${this.amount.toFixed(2)}`;
  }

  // MARK: - Methods

  /**
   * 更新预算金额
   */
  async updateAmount(newAmount: number): Promise<void> {
    await this.update(record => {
      record.amount = newAmount;
      record.updatedAt = new Date();
    });
  }

  /**
   * 切换启用状态
   */
  async toggleActive(): Promise<void> {
    await this.update(record => {
      record.isActive = !record.isActive;
      record.updatedAt = new Date();
    });
  }
}
