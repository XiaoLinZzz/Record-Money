/**
 * 数据管理器
 * 对应 Swift 版本的 DataManager.swift
 * 提供统一的数据访问接口
 */

import { Database, Q } from '@nozbe/watermelondb';
import { startOfMonth, endOfMonth, startOfDay, endOfDay } from 'date-fns';
import Transaction, { TransactionType } from '../models/Transaction';
import Category from '../models/Category';
import Budget, { BudgetPeriod } from '../models/Budget';
import { EventEmitter } from 'events';

export interface StatisticsSummary {
  totalExpense: number;
  totalIncome: number;
  balance: number;
  transactionCount: number;
  categoryBreakdown: { [categoryName: string]: number };
}

export interface TransactionFilter {
  startDate?: Date;
  endDate?: Date;
  category?: string;
  type?: TransactionType;
}

/**
 * 数据管理器类
 * 单例模式，提供统一的数据访问接口
 */
class DataManager extends EventEmitter {
  private static instance: DataManager;
  private database!: Database;

  private constructor() {
    super();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): DataManager {
    if (!DataManager.instance) {
      DataManager.instance = new DataManager();
    }
    return DataManager.instance;
  }

  /**
   * 初始化数据库
   */
  initialize(database: Database): void {
    this.database = database;
  }

  // MARK: - Transaction Operations

  /**
   * 保存交易记录
   */
  async saveTransaction(data: {
    amount: number;
    merchant: string;
    categoryName: string;
    type?: TransactionType;
    paymentMethod?: string;
    rawText?: string;
    timestamp?: Date;
    note?: string;
  }): Promise<Transaction> {
    const transaction = await this.database.write(async () => {
      return await this.database.get<Transaction>('transactions').create(t => {
        t.amount = data.amount;
        t.merchant = data.merchant;
        t.categoryName = data.categoryName;
        t.type = data.type || 'expense';
        t.paymentMethod = data.paymentMethod;
        t.rawText = data.rawText;
        t.timestamp = data.timestamp || new Date();
        t.note = data.note;
        t.isDeleted = false;
      });
    });

    // 发送数据变更事件
    this.emit('transactionDidChange');
    return transaction;
  }

  /**
   * 获取所有交易记录
   */
  async fetchTransactions(filter?: TransactionFilter): Promise<Transaction[]> {
    const collection = this.database.get<Transaction>('transactions');

    const conditions = [Q.where('is_deleted', false)];

    if (filter?.startDate) {
      conditions.push(Q.where('timestamp', Q.gte(filter.startDate.getTime())));
    }

    if (filter?.endDate) {
      conditions.push(Q.where('timestamp', Q.lte(filter.endDate.getTime())));
    }

    if (filter?.category) {
      conditions.push(Q.where('category_name', filter.category));
    }

    if (filter?.type) {
      conditions.push(Q.where('type', filter.type));
    }

    const transactions = await collection
      .query(...conditions, Q.sortBy('timestamp', Q.desc))
      .fetch();

    return transactions;
  }

  /**
   * 更新交易记录
   */
  async updateTransaction(
    transaction: Transaction,
    updates: {
      amount?: number;
      merchant?: string;
      categoryName?: string;
      type?: TransactionType;
      timestamp?: Date;
      note?: string;
    }
  ): Promise<void> {
    await this.database.write(async () => {
      await transaction.update(t => {
        if (updates.amount !== undefined) t.amount = updates.amount;
        if (updates.merchant !== undefined) t.merchant = updates.merchant;
        if (updates.categoryName !== undefined) t.categoryName = updates.categoryName;
        if (updates.type !== undefined) t.type = updates.type;
        if (updates.timestamp !== undefined) t.timestamp = updates.timestamp;
        if (updates.note !== undefined) t.note = updates.note;
      });
    });

    this.emit('transactionDidChange');
  }

  /**
   * 删除交易记录（软删除）
   */
  async deleteTransaction(transaction: Transaction): Promise<void> {
    await this.database.write(async () => {
      await transaction.softDelete();
    });

    this.emit('transactionDidChange');
  }

  /**
   * 永久删除交易记录
   */
  async permanentlyDeleteTransaction(transaction: Transaction): Promise<void> {
    await this.database.write(async () => {
      await transaction.markAsDeleted();
    });

    this.emit('transactionDidChange');
  }

  // MARK: - Category Operations

  /**
   * 获取所有分类
   */
  async fetchCategories(): Promise<Category[]> {
    const collection = this.database.get<Category>('categories');
    return await collection.query(Q.sortBy('order', Q.asc)).fetch();
  }

  /**
   * 根据名称获取分类
   */
  async getCategoryByName(name: string): Promise<Category | null> {
    const collection = this.database.get<Category>('categories');
    const categories = await collection
      .query(Q.where('name', name))
      .fetch();
    return categories[0] || null;
  }

  /**
   * 保存分类
   */
  async saveCategory(data: {
    name: string;
    icon: string;
    color: string;
    keywords?: string[];
    isSystem?: boolean;
    order?: number;
  }): Promise<Category> {
    return await this.database.write(async () => {
      return await this.database.get<Category>('categories').create(c => {
        c.name = data.name;
        c.icon = data.icon;
        c.color = data.color;
        c._keywords = JSON.stringify(data.keywords || []);
        c.isSystem = data.isSystem || false;
        c.order = data.order || 0;
      });
    });
  }

  /**
   * 删除分类
   */
  async deleteCategory(category: Category): Promise<void> {
    if (category.isSystem) {
      throw new Error('无法删除系统预设分类');
    }

    await this.database.write(async () => {
      await category.markAsDeleted();
    });
  }

  // MARK: - Budget Operations

  /**
   * 获取预算
   */
  async getBudget(categoryName: string): Promise<Budget | null> {
    const collection = this.database.get<Budget>('budgets');
    const budgets = await collection
      .query(
        Q.where('category_name', categoryName),
        Q.where('is_enabled', true)
      )
      .fetch();
    return budgets[0] || null;
  }

  /**
   * 获取所有启用的预算
   */
  async fetchBudgets(): Promise<Budget[]> {
    const collection = this.database.get<Budget>('budgets');
    return await collection.query(Q.where('is_enabled', true)).fetch();
  }

  /**
   * 保存预算
   */
  async saveBudget(data: {
    categoryName: string;
    amount: number;
    period?: BudgetPeriod;
    startDate?: Date;
  }): Promise<Budget> {
    return await this.database.write(async () => {
      return await this.database.get<Budget>('budgets').create(b => {
        b.categoryName = data.categoryName;
        b.amount = data.amount;
        b.period = data.period || 'monthly';
        b.startDate = data.startDate || new Date();
        b.isEnabled = true;
      });
    });
  }

  /**
   * 更新预算
   */
  async updateBudget(budget: Budget, amount: number): Promise<void> {
    await this.database.write(async () => {
      await budget.updateAmount(amount);
    });
  }

  /**
   * 删除预算
   */
  async deleteBudget(budget: Budget): Promise<void> {
    await this.database.write(async () => {
      await budget.markAsDeleted();
    });
  }

  // MARK: - Statistics

  /**
   * 获取月度支出总额
   */
  async getMonthlyExpense(year: number, month: number): Promise<number> {
    const date = new Date(year, month - 1, 1);
    const startDate = startOfMonth(date);
    const endDate = endOfMonth(date);

    const transactions = await this.fetchTransactions({
      startDate,
      endDate,
      type: 'expense',
    });

    return transactions.reduce((sum, t) => sum + t.amount, 0);
  }

  /**
   * 获取月度收入总额
   */
  async getMonthlyIncome(year: number, month: number): Promise<number> {
    const date = new Date(year, month - 1, 1);
    const startDate = startOfMonth(date);
    const endDate = endOfMonth(date);

    const transactions = await this.fetchTransactions({
      startDate,
      endDate,
      type: 'income',
    });

    return transactions.reduce((sum, t) => sum + t.amount, 0);
  }

  /**
   * 获取指定分类的月度支出
   */
  async getMonthlySpent(categoryName: string): Promise<number> {
    const now = new Date();
    const startDate = startOfMonth(now);
    const endDate = endOfMonth(now);

    const transactions = await this.fetchTransactions({
      startDate,
      endDate,
      category: categoryName,
      type: 'expense',
    });

    return transactions.reduce((sum, t) => sum + t.amount, 0);
  }

  /**
   * 按分类统计支出
   */
  async getCategoryStats(
    startDate: Date,
    endDate: Date
  ): Promise<{ [categoryName: string]: number }> {
    const transactions = await this.fetchTransactions({
      startDate,
      endDate,
      type: 'expense',
    });

    const stats: { [categoryName: string]: number } = {};
    for (const transaction of transactions) {
      stats[transaction.categoryName] =
        (stats[transaction.categoryName] || 0) + transaction.amount;
    }

    return stats;
  }

  /**
   * 获取统计摘要
   */
  async getStatisticsSummary(
    startDate: Date,
    endDate: Date
  ): Promise<StatisticsSummary> {
    const allTransactions = await this.fetchTransactions({
      startDate,
      endDate,
    });

    const expenses = allTransactions.filter(t => t.type === 'expense');
    const incomes = allTransactions.filter(t => t.type === 'income');

    const totalExpense = expenses.reduce((sum, t) => sum + t.amount, 0);
    const totalIncome = incomes.reduce((sum, t) => sum + t.amount, 0);

    const categoryBreakdown: { [categoryName: string]: number } = {};
    for (const transaction of expenses) {
      categoryBreakdown[transaction.categoryName] =
        (categoryBreakdown[transaction.categoryName] || 0) + transaction.amount;
    }

    return {
      totalExpense,
      totalIncome,
      balance: totalIncome - totalExpense,
      transactionCount: allTransactions.length,
      categoryBreakdown,
    };
  }

  /**
   * 清除所有数据
   */
  async clearAllData(): Promise<void> {
    const transactions = await this.fetchTransactions();
    for (const transaction of transactions) {
      await this.permanentlyDeleteTransaction(transaction);
    }

    const categories = await this.fetchCategories();
    for (const category of categories) {
      if (!category.isSystem) {
        await this.deleteCategory(category);
      }
    }

    const budgets = await this.fetchBudgets();
    for (const budget of budgets) {
      await this.deleteBudget(budget);
    }
  }
}

export default DataManager.getInstance();
