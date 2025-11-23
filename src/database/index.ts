/**
 * WatermelonDB 数据库配置
 */

import { Database } from '@nozbe/watermelondb';
import SQLiteAdapter from '@nozbe/watermelondb/adapters/sqlite';

import { schema } from './schema';
import Transaction from '../models/Transaction';
import Category from '../models/Category';
import Budget from '../models/Budget';
import migrations from './migrations';

// 数据库适配器配置
const adapter = new SQLiteAdapter({
  schema,
  migrations,
  jsi: true, // 使用 JSI for better performance
  onSetUpError: error => {
    console.error('Database setup error:', error);
  },
});

// 创建数据库实例
export const database = new Database({
  adapter,
  modelClasses: [Transaction, Category, Budget],
});

export { Transaction, Category, Budget };
export default database;
