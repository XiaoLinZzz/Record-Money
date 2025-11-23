/**
 * 统计分析界面
 * 对应 Swift 版本的 StatisticsView.swift
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import { useDatabase } from '../../services/DatabaseProvider';
import DataManager, { StatisticsSummary } from '../../services/DataManager';
import { startOfMonth, endOfMonth, startOfWeek, endOfWeek, startOfYear, endOfYear } from 'date-fns';

type TimePeriod = 'today' | 'week' | 'month' | 'year';

const StatisticsScreen: React.FC = () => {
  const database = useDatabase();
  const [period, setPeriod] = useState<TimePeriod>('month');
  const [summary, setSummary] = useState<StatisticsSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    DataManager.initialize(database);
    loadStatistics();
  }, [database, period]);

  const getDateRange = (): { startDate: Date; endDate: Date } => {
    const now = new Date();
    switch (period) {
      case 'today':
        return { startDate: new Date(now.setHours(0, 0, 0, 0)), endDate: new Date(now.setHours(23, 59, 59, 999)) };
      case 'week':
        return { startDate: startOfWeek(now, { weekStartsOn: 1 }), endDate: endOfWeek(now, { weekStartsOn: 1 }) };
      case 'month':
        return { startDate: startOfMonth(now), endDate: endOfMonth(now) };
      case 'year':
        return { startDate: startOfYear(now), endDate: endOfYear(now) };
    }
  };

  const loadStatistics = async () => {
    try {
      const { startDate, endDate } = getDateRange();
      const data = await DataManager.getStatisticsSummary(startDate, endDate);
      setSummary(data);
    } catch (error) {
      console.error('Failed to load statistics:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatAmount = (amount: number): string => {
    return `¥${amount.toFixed(2)}`;
  };

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <Text>加载中...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      {/* 时间段选择器 */}
      <View style={styles.periodSelector}>
        {(['today', 'week', 'month', 'year'] as TimePeriod[]).map(p => (
          <TouchableOpacity
            key={p}
            style={[styles.periodButton, period === p && styles.periodButtonActive]}
            onPress={() => setPeriod(p)}
          >
            <Text style={[styles.periodText, period === p && styles.periodTextActive]}>
              {p === 'today' ? '今天' : p === 'week' ? '本周' : p === 'month' ? '本月' : '本年'}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* 总览卡片 */}
      <View style={styles.summaryContainer}>
        <View style={styles.summaryCard}>
          <Text style={styles.summaryLabel}>总支出</Text>
          <Text style={[styles.summaryAmount, styles.expenseText]}>
            {formatAmount(summary?.totalExpense || 0)}
          </Text>
        </View>

        <View style={styles.summaryCard}>
          <Text style={styles.summaryLabel}>总收入</Text>
          <Text style={[styles.summaryAmount, styles.incomeText]}>
            {formatAmount(summary?.totalIncome || 0)}
          </Text>
        </View>

        <View style={styles.summaryCard}>
          <Text style={styles.summaryLabel}>结余</Text>
          <Text style={[styles.summaryAmount, styles.balanceText]}>
            {formatAmount(summary?.balance || 0)}
          </Text>
        </View>
      </View>

      {/* 分类统计 */}
      <View style={styles.categorySection}>
        <Text style={styles.sectionTitle}>分类统计</Text>
        {summary?.categoryBreakdown &&
          Object.entries(summary.categoryBreakdown)
            .sort(([, a], [, b]) => b - a)
            .map(([category, amount]) => {
              const percentage = summary.totalExpense > 0
                ? (amount / summary.totalExpense) * 100
                : 0;

              return (
                <View key={category} style={styles.categoryItem}>
                  <View style={styles.categoryInfo}>
                    <Text style={styles.categoryName}>{category}</Text>
                    <Text style={styles.categoryAmount}>
                      {formatAmount(amount)}
                    </Text>
                  </View>
                  <View style={styles.progressBarContainer}>
                    <View
                      style={[
                        styles.progressBar,
                        { width: `${percentage}%` },
                      ]}
                    />
                  </View>
                  <Text style={styles.percentageText}>
                    {percentage.toFixed(1)}%
                  </Text>
                </View>
              );
            })}

        {(!summary?.categoryBreakdown ||
          Object.keys(summary.categoryBreakdown).length === 0) && (
          <View style={styles.emptyState}>
            <Text style={styles.emptyText}>暂无数据</Text>
          </View>
        )}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  periodSelector: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#FFFFFF',
  },
  periodButton: {
    flex: 1,
    paddingVertical: 8,
    marginHorizontal: 4,
    borderRadius: 8,
    backgroundColor: '#F2F2F7',
    alignItems: 'center',
  },
  periodButtonActive: {
    backgroundColor: '#007AFF',
  },
  periodText: {
    fontSize: 14,
    color: '#8E8E93',
    fontWeight: '500',
  },
  periodTextActive: {
    color: '#FFFFFF',
  },
  summaryContainer: {
    flexDirection: 'row',
    paddingHorizontal: 12,
    paddingVertical: 16,
    gap: 8,
  },
  summaryCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
  },
  summaryLabel: {
    fontSize: 13,
    color: '#8E8E93',
    marginBottom: 8,
  },
  summaryAmount: {
    fontSize: 20,
    fontWeight: '600',
  },
  expenseText: {
    color: '#FF3B30',
  },
  incomeText: {
    color: '#34C759',
  },
  balanceText: {
    color: '#007AFF',
  },
  categorySection: {
    backgroundColor: '#FFFFFF',
    marginTop: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  sectionTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 16,
  },
  categoryItem: {
    marginBottom: 16,
  },
  categoryInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  categoryName: {
    fontSize: 15,
    color: '#000000',
  },
  categoryAmount: {
    fontSize: 15,
    fontWeight: '500',
    color: '#000000',
  },
  progressBarContainer: {
    height: 8,
    backgroundColor: '#F2F2F7',
    borderRadius: 4,
    overflow: 'hidden',
    marginBottom: 4,
  },
  progressBar: {
    height: '100%',
    backgroundColor: '#007AFF',
    borderRadius: 4,
  },
  percentageText: {
    fontSize: 12,
    color: '#8E8E93',
    textAlign: 'right',
  },
  emptyState: {
    paddingVertical: 40,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 14,
    color: '#C7C7CC',
  },
});

export default StatisticsScreen;
