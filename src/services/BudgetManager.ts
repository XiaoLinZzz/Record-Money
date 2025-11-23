/**
 * 预算管理服务
 * 对应 Swift 版本的 BudgetManager.swift
 */

import { EventEmitter } from 'events';
import { Database, Q } from '@nozbe/watermelondb';
import Budget, { BudgetPeriod } from '../models/Budget';
import Transaction from '../models/Transaction';

export interface BudgetDetail {
  budget: Budget;
  spending: number;
  usage: number;
  remaining: number;
  overage: number;
  isOver: boolean;
  progressColor: 'green' | 'orange' | 'red';
}

export interface BudgetWarning {
  budget: Budget;
  type: 'exceeded' | 'approaching';
  message: string;
}

/**
 * 预算管理器 - Singleton
 */
class BudgetManager extends EventEmitter {
  private static instance: BudgetManager | null = null;
  private database!: Database;
  private _budgets: Budget[] = [];
  private _totalBudget: Budget | null = null;

  private constructor() {
    super();
  }

  static getInstance(): BudgetManager {
    if (!BudgetManager.instance) {
      BudgetManager.instance = new BudgetManager();
    }
    return BudgetManager.instance;
  }

  initialize(database: Database) {
    this.database = database;
    this.loadBudgets();
  }

  // MARK: - Getters

  get budgets(): Budget[] {
    return this._budgets;
  }

  get totalBudget(): Budget | null {
    return this._totalBudget;
  }

  // MARK: - CRUD Operations

  async loadBudgets(): Promise<void> {
    try {
      const budgetCollection = this.database.get<Budget>('budgets');
      const budgets = await budgetCollection
        .query(
          Q.where('is_active', true),
          Q.sortBy('created_at', Q.desc)
        )
        .fetch();

      this._budgets = budgets;
      this._totalBudget = budgets.find(b => b.isTotalBudget) || null;

      this.emit('budgetsChanged');
    } catch (error) {
      console.error('❌ 加载预算失败:', error);
    }
  }

  async saveBudget(data: {
    amount: number;
    categoryName?: string;
    period: BudgetPeriod;
    startDate: Date;
    alertThreshold?: number;
  }): Promise<Budget> {
    const budget = await this.database.write(async () => {
      const budgetCollection = this.database.get<Budget>('budgets');
      return await budgetCollection.create(b => {
        b.amount = data.amount;
        b.categoryName = data.categoryName;
        b.period = data.period;
        b.startDate = data.startDate;
        b.alertThreshold = data.alertThreshold || 0.9;
        b.isActive = true;
      });
    });

    await this.loadBudgets();
    this.emit('budgetDidChange');
    return budget;
  }

  async updateBudget(
    budget: Budget,
    updates: {
      amount?: number;
      categoryName?: string | null;
      period?: BudgetPeriod;
      startDate?: Date;
      alertThreshold?: number;
      isActive?: boolean;
    }
  ): Promise<void> {
    await this.database.write(async () => {
      await budget.update(b => {
        if (updates.amount !== undefined) b.amount = updates.amount;
        if (updates.categoryName !== undefined) b.categoryName = updates.categoryName;
        if (updates.period !== undefined) b.period = updates.period;
        if (updates.startDate !== undefined) b.startDate = updates.startDate;
        if (updates.alertThreshold !== undefined) b.alertThreshold = updates.alertThreshold;
        if (updates.isActive !== undefined) b.isActive = updates.isActive;
        b.updatedAt = new Date();
      });
    });

    await this.loadBudgets();
    this.emit('budgetDidChange');
  }

  async deleteBudget(budget: Budget): Promise<void> {
    await this.database.write(async () => {
      await budget.destroyPermanently();
    });

    await this.loadBudgets();
    this.emit('budgetDidChange');
  }

  // MARK: - Budget Calculations

  /**
   * 获取当前周期的支出
   */
  async getCurrentSpending(
    category: string | null | undefined,
    period: BudgetPeriod,
    startDate: Date
  ): Promise<number> {
    const dateRange = this.getDateRange(period, startDate);

    try {
      const transactionCollection = this.database.get<Transaction>('transactions');

      const queries = [
        Q.where('type', 'expense'),
        Q.where('timestamp', Q.gte(dateRange.start.getTime())),
        Q.where('timestamp', Q.lt(dateRange.end.getTime())),
        Q.where('is_deleted', false),
      ];

      if (category) {
        queries.push(Q.where('category_name', category));
      }

      const transactions = await transactionCollection.query(...queries).fetch();

      return transactions.reduce((sum, t) => sum + t.amount, 0);
    } catch (error) {
      console.error('❌ 获取支出失败:', error);
      return 0;
    }
  }

  /**
   * 计算预算使用百分比
   */
  async getBudgetUsage(budget: Budget): Promise<number> {
    const spending = await this.getCurrentSpending(
      budget.categoryName,
      budget.period as BudgetPeriod,
      budget.startDate
    );
    return Math.min(spending / budget.amount, 1.0);
  }

  /**
   * 检查是否超支
   */
  async isOverBudget(budget: Budget): Promise<boolean> {
    const spending = await this.getCurrentSpending(
      budget.categoryName,
      budget.period as BudgetPeriod,
      budget.startDate
    );
    return spending > budget.amount;
  }

  /**
   * 获取超支金额
   */
  async getOverage(budget: Budget): Promise<number> {
    const spending = await this.getCurrentSpending(
      budget.categoryName,
      budget.period as BudgetPeriod,
      budget.startDate
    );
    return Math.max(spending - budget.amount, 0);
  }

  /**
   * 获取剩余预算
   */
  async getRemaining(budget: Budget): Promise<number> {
    const spending = await this.getCurrentSpending(
      budget.categoryName,
      budget.period as BudgetPeriod,
      budget.startDate
    );
    return Math.max(budget.amount - spending, 0);
  }

  /**
   * 获取预算详情
   */
  async getBudgetDetail(budget: Budget): Promise<BudgetDetail> {
    const spending = await this.getCurrentSpending(
      budget.categoryName,
      budget.period as BudgetPeriod,
      budget.startDate
    );

    const usage = spending / budget.amount;
    const remaining = Math.max(budget.amount - spending, 0);
    const overage = Math.max(spending - budget.amount, 0);
    const isOver = spending > budget.amount;

    let progressColor: 'green' | 'orange' | 'red';
    if (usage < 0.7) {
      progressColor = 'green';
    } else if (usage < 0.9) {
      progressColor = 'orange';
    } else {
      progressColor = 'red';
    }

    return {
      budget,
      spending,
      usage,
      remaining,
      overage,
      isOver,
      progressColor,
    };
  }

  /**
   * 获取所有预算详情
   */
  async getAllBudgetDetails(): Promise<BudgetDetail[]> {
    const details: BudgetDetail[] = [];

    for (const budget of this._budgets) {
      const detail = await this.getBudgetDetail(budget);
      details.push(detail);
    }

    // 排序：未超支的在前，超支的在后
    return details.sort((a, b) => {
      if (!a.isOver && b.isOver) return -1;
      if (a.isOver && !b.isOver) return 1;
      return 0;
    });
  }

  /**
   * 检查所有预算警告
   */
  async checkBudgetWarnings(): Promise<BudgetWarning[]> {
    const warnings: BudgetWarning[] = [];

    for (const budget of this._budgets) {
      const detail = await this.getBudgetDetail(budget);

      // 超支警告
      if (detail.isOver) {
        warnings.push({
          budget,
          type: 'exceeded',
          message: `${budget.displayName}已超支 ¥${detail.overage.toFixed(2)}`,
        });
      }
      // 接近预算警告（90%）
      else if (detail.usage >= 0.9) {
        warnings.push({
          budget,
          type: 'approaching',
          message: `${budget.displayName}已使用 ${Math.round(detail.usage * 100)}%`,
        });
      }
    }

    return warnings;
  }

  // MARK: - Helper Methods

  private getDateRange(period: BudgetPeriod, startDate: Date): { start: Date; end: Date } {
    const now = new Date();

    switch (period) {
      case 'daily': {
        const start = new Date(now);
        start.setHours(0, 0, 0, 0);
        const end = new Date(start);
        end.setDate(end.getDate() + 1);
        return { start, end };
      }

      case 'weekly': {
        const start = new Date(now);
        const day = start.getDay();
        const diff = start.getDate() - day + (day === 0 ? -6 : 1); // 调整到周一
        start.setDate(diff);
        start.setHours(0, 0, 0, 0);
        const end = new Date(start);
        end.setDate(end.getDate() + 7);
        return { start, end };
      }

      case 'monthly': {
        const start = new Date(now.getFullYear(), now.getMonth(), 1);
        const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
        return { start, end };
      }

      case 'yearly': {
        const start = new Date(now.getFullYear(), 0, 1);
        const end = new Date(now.getFullYear() + 1, 0, 1);
        return { start, end };
      }

      default:
        throw new Error(`Unknown period: ${period}`);
    }
  }
}

export default BudgetManager;
