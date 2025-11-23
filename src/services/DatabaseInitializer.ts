/**
 * 数据库初始化服务
 * 负责创建默认分类等初始数据
 */

import { Database } from '@nozbe/watermelondb';
import Category, { DEFAULT_CATEGORIES } from '../models/Category';

/**
 * 初始化默认分类
 * 检查数据库中是否已有分类，如果没有则创建默认分类
 */
export async function initializeDefaultCategories(
  database: Database
): Promise<void> {
  const categoriesCollection = database.get<Category>('categories');
  const existingCategories = await categoriesCollection.query().fetch();

  // 如果已有分类，则不重复创建
  if (existingCategories.length > 0) {
    return;
  }

  // 批量创建默认分类
  await database.write(async () => {
    for (const categoryData of DEFAULT_CATEGORIES) {
      await categoriesCollection.create(category => {
        category.name = categoryData.name;
        category.icon = categoryData.icon;
        category.color = categoryData.color;
        category._keywords = JSON.stringify(categoryData.keywords);
        category.isSystem = categoryData.isSystem;
        category.order = categoryData.order;
      });
    }
  });

  console.log('Default categories initialized');
}
