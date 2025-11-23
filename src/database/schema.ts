/**
 * WatermelonDB 数据库 Schema
 * 定义所有数据表结构
 */

import { appSchema, tableSchema } from '@nozbe/watermelondb';

export const schema = appSchema({
  version: 1,
  tables: [
    // 交易记录表
    tableSchema({
      name: 'transactions',
      columns: [
        { name: 'amount', type: 'number' },
        { name: 'merchant', type: 'string' },
        { name: 'category_name', type: 'string', isIndexed: true },
        { name: 'type', type: 'string', isIndexed: true }, // expense/income
        { name: 'payment_method', type: 'string', isOptional: true },
        { name: 'raw_text', type: 'string', isOptional: true },
        { name: 'timestamp', type: 'number', isIndexed: true },
        { name: 'note', type: 'string', isOptional: true },
        { name: 'is_deleted', type: 'boolean', isIndexed: true },
        { name: 'created_at', type: 'number' },
        { name: 'updated_at', type: 'number' },
      ],
    }),

    // 分类表
    tableSchema({
      name: 'categories',
      columns: [
        { name: 'name', type: 'string', isIndexed: true },
        { name: 'icon', type: 'string' },
        { name: 'color', type: 'string' },
        { name: 'keywords', type: 'string' }, // JSON array stored as string
        { name: 'is_system', type: 'boolean' },
        { name: 'order', type: 'number' },
        { name: 'created_at', type: 'number' },
        { name: 'updated_at', type: 'number' },
      ],
    }),

    // 预算表
    tableSchema({
      name: 'budgets',
      columns: [
        { name: 'category_name', type: 'string', isIndexed: true },
        { name: 'amount', type: 'number' },
        { name: 'period', type: 'string' }, // daily/weekly/monthly/yearly
        { name: 'start_date', type: 'number' },
        { name: 'is_enabled', type: 'boolean' },
        { name: 'created_at', type: 'number' },
        { name: 'updated_at', type: 'number' },
      ],
    }),
  ],
});
