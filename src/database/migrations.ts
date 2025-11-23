/**
 * 数据库迁移配置
 * 用于数据库版本升级
 */

import { schemaMigrations } from '@nozbe/watermelondb/Schema/migrations';

export default schemaMigrations({
  migrations: [
    // 未来版本的迁移将在这里添加
    // {
    //   toVersion: 2,
    //   steps: [
    //     // 迁移步骤
    //   ],
    // },
  ],
});
