/**
 * 数据库提供者组件
 * 初始化数据库并提供 Context
 */

import React, { createContext, useContext, useEffect, useState } from 'react';
import { Database } from '@nozbe/watermelondb';
import database from '../database';
import { initializeDefaultCategories } from './DatabaseInitializer';

interface DatabaseContextType {
  database: Database;
  isReady: boolean;
}

const DatabaseContext = createContext<DatabaseContextType | null>(null);

export const DatabaseProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    const initialize = async () => {
      try {
        // 初始化默认分类
        await initializeDefaultCategories(database);
        setIsReady(true);
      } catch (error) {
        console.error('Failed to initialize database:', error);
      }
    };

    initialize();
  }, []);

  if (!isReady) {
    return null; // 或者显示加载界面
  }

  return (
    <DatabaseContext.Provider value={{ database, isReady }}>
      {children}
    </DatabaseContext.Provider>
  );
};

export const useDatabase = (): Database => {
  const context = useContext(DatabaseContext);
  if (!context) {
    throw new Error('useDatabase must be used within DatabaseProvider');
  }
  return context.database;
};
