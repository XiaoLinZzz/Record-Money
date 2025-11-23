/**
 * 预算概览界面
 * 对应 Swift 版本的 BudgetOverviewView.swift
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Alert,
  Platform,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import * as Haptics from 'expo-haptics';
import { useDatabase } from '../../services/DatabaseProvider';
import DataManager from '../../services/DataManager';
import BudgetManager, { BudgetDetail } from '../../services/BudgetManager';
import Category from '../../models/Category';
import Budget from '../../models/Budget';
import SetBudgetModal from './SetBudgetModal';

interface BudgetOverviewScreenProps {
  navigation: any;
}

const BudgetOverviewScreen: React.FC<BudgetOverviewScreenProps> = ({ navigation }) => {
  const database = useDatabase();

  const [budgetDetails, setBudgetDetails] = useState<BudgetDetail[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [showAddBudget, setShowAddBudget] = useState(false);
  const [budgetToEdit, setBudgetToEdit] = useState<Budget | null>(null);

  const budgetManager = BudgetManager.getInstance();

  useEffect(() => {
    if (database) {
      DataManager.initialize(database);
      budgetManager.initialize(database);
      loadData();
    }
  }, [database]);

  useEffect(() => {
    // 监听预算变化
    const handleBudgetChange = () => {
      loadData();
    };

    budgetManager.on('budgetDidChange', handleBudgetChange);
    budgetManager.on('budgetsChanged', handleBudgetChange);

    return () => {
      budgetManager.off('budgetDidChange', handleBudgetChange);
      budgetManager.off('budgetsChanged', handleBudgetChange);
    };
  }, []);

  useEffect(() => {
    // 设置导航栏按钮
    navigation.setOptions({
      headerRight: () => (
        <TouchableOpacity
          style={styles.headerButton}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            setShowAddBudget(true);
          }}
        >
          <Icon name="add-circle" size={28} color="#007AFF" />
        </TouchableOpacity>
      ),
    });
  }, [navigation]);

  const loadData = async () => {
    setIsLoading(true);

    try {
      // 加载分类
      const fetchedCategories = await DataManager.fetchCategories();
      setCategories(fetchedCategories);

      // 加载预算详情
      const details = await budgetManager.getAllBudgetDetails();
      setBudgetDetails(details);
    } catch (error) {
      console.error('加载失败:', error);
      Alert.alert('错误', '加载失败，请重试');
    } finally {
      setIsLoading(false);
    }
  };

  const handleRefresh = useCallback(async () => {
    await loadData();
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  }, []);

  const handleDeleteBudget = (budget: Budget) => {
    Alert.alert(
      '确认删除',
      '确定要删除这个预算吗？',
      [
        {
          text: '取消',
          style: 'cancel',
          onPress: () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light),
        },
        {
          text: '删除',
          style: 'destructive',
          onPress: async () => {
            try {
              await budgetManager.deleteBudget(budget);
              await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
            } catch (error) {
              console.error('删除失败:', error);
              Alert.alert('错误', '删除失败，请重试');
              await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
            }
          },
        },
      ]
    );
  };

  const getProgressColor = (detail: BudgetDetail): string => {
    if (detail.usage < 0.7) return '#34C759';
    if (detail.usage < 0.9) return '#FF9500';
    return '#FF3B30';
  };

  const renderBudgetRow = (detail: BudgetDetail) => {
    const progressColor = getProgressColor(detail);

    return (
      <TouchableOpacity
        key={detail.budget.id}
        style={styles.budgetRow}
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          setBudgetToEdit(detail.budget);
        }}
      >
        <View style={styles.budgetContent}>
          {/* 标题行 */}
          <View style={styles.budgetHeader}>
            <Text style={styles.categoryName}>{detail.budget.displayName}</Text>
            <View style={styles.amountContainer}>
              <Text style={[styles.spendingAmount, { color: progressColor }]}>
                ¥{detail.spending.toFixed(2)}
              </Text>
              <Text style={styles.totalAmount}>
                / ¥{detail.budget.amount.toFixed(2)}
              </Text>
            </View>
          </View>

          {/* 进度条 */}
          <View style={styles.progressBarContainer}>
            <View style={styles.progressBarBackground}>
              <View
                style={[
                  styles.progressBarFill,
                  {
                    width: `${Math.min(detail.usage * 100, 100)}%`,
                    backgroundColor: progressColor,
                  },
                ]}
              />
            </View>
          </View>

          {/* 信息行 */}
          <View style={styles.budgetFooter}>
            <Text style={styles.usageText}>{Math.round(detail.usage * 100)}%</Text>
            {detail.isOver ? (
              <Text style={styles.overageText}>
                超支 ¥{detail.overage.toFixed(2)}
              </Text>
            ) : (
              <Text style={styles.remainingText}>
                剩余 ¥{detail.remaining.toFixed(2)}
              </Text>
            )}
          </View>
        </View>

        {/* 操作按钮 */}
        <View style={styles.actionsContainer}>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              setBudgetToEdit(detail.budget);
            }}
          >
            <Icon name="pencil" size={20} color="#007AFF" />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.actionButton}
            onPress={() => handleDeleteBudget(detail.budget)}
          >
            <Icon name="trash" size={20} color="#FF3B30" />
          </TouchableOpacity>
        </View>
      </TouchableOpacity>
    );
  };

  const renderWarningRow = (detail: BudgetDetail) => {
    const isOverBudget = detail.isOver;

    return (
      <View key={detail.budget.id} style={styles.warningRow}>
        <Icon
          name={isOverBudget ? 'warning' : 'alert-circle'}
          size={24}
          color={isOverBudget ? '#FF3B30' : '#FF9500'}
        />
        <View style={styles.warningInfo}>
          <Text style={styles.warningCategory}>{detail.budget.displayName}</Text>
          {isOverBudget ? (
            <Text style={styles.warningTextRed}>
              已超支 ¥{detail.overage.toFixed(2)}
            </Text>
          ) : (
            <Text style={styles.warningTextOrange}>
              已使用 {Math.round(detail.usage * 100)}%
            </Text>
          )}
        </View>
        <Text style={[styles.warningAmount, { color: isOverBudget ? '#FF3B30' : '#FF9500' }]}>
          ¥{detail.spending.toFixed(2)}
        </Text>
      </View>
    );
  };

  // 分组预算
  const overdueBudgets = budgetDetails.filter(d => d.isOver);
  const approachingBudgets = budgetDetails.filter(d => !d.isOver && d.usage >= 0.9);
  const normalBudgets = budgetDetails.filter(d => !d.isOver && d.usage < 0.9);

  const renderEmptyState = () => (
    <View style={styles.emptyContainer}>
      <Icon name="pie-chart-outline" size={80} color="#C7C7CC" />
      <Text style={styles.emptyTitle}>暂无预算</Text>
      <Text style={styles.emptyDescription}>
        设置预算有助于控制支出{'\n'}点击右上角 + 创建第一个预算
      </Text>
      <TouchableOpacity
        style={styles.createButton}
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          setShowAddBudget(true);
        }}
      >
        <Text style={styles.createButtonText}>创建预算</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        refreshControl={
          <RefreshControl refreshing={isLoading} onRefresh={handleRefresh} />
        }
      >
        {budgetDetails.length === 0 ? (
          renderEmptyState()
        ) : (
          <>
            {/* 超支警告 */}
            {overdueBudgets.length > 0 && (
              <View style={styles.section}>
                <View style={styles.sectionHeader}>
                  <Icon name="warning" size={20} color="#FF3B30" />
                  <Text style={[styles.sectionTitle, { color: '#FF3B30' }]}>
                    超支警告
                  </Text>
                </View>
                {overdueBudgets.map(renderWarningRow)}
              </View>
            )}

            {/* 接近预算警告 */}
            {approachingBudgets.length > 0 && (
              <View style={styles.section}>
                <View style={styles.sectionHeader}>
                  <Icon name="alert-circle" size={20} color="#FF9500" />
                  <Text style={[styles.sectionTitle, { color: '#FF9500' }]}>
                    接近预算
                  </Text>
                </View>
                {approachingBudgets.map(renderWarningRow)}
              </View>
            )}

            {/* 正常预算 */}
            {normalBudgets.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>正常预算</Text>
                {normalBudgets.map(renderBudgetRow)}
              </View>
            )}
          </>
        )}
      </ScrollView>

      {/* Add Budget Modal */}
      <SetBudgetModal
        visible={showAddBudget}
        budget={null}
        categories={categories}
        onClose={() => setShowAddBudget(false)}
      />

      {/* Edit Budget Modal */}
      {budgetToEdit && (
        <SetBudgetModal
          visible={!!budgetToEdit}
          budget={budgetToEdit}
          categories={categories}
          onClose={() => setBudgetToEdit(null)}
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
  },
  scrollView: {
    flex: 1,
  },
  headerButton: {
    paddingRight: 16,
  },
  section: {
    marginTop: 20,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingBottom: 8,
    gap: 8,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#8E8E93',
    textTransform: 'uppercase',
  },
  budgetRow: {
    flexDirection: 'row',
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginBottom: 12,
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  budgetContent: {
    flex: 1,
  },
  budgetHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  categoryName: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
  },
  amountContainer: {
    alignItems: 'flex-end',
  },
  spendingAmount: {
    fontSize: 20,
    fontWeight: '700',
  },
  totalAmount: {
    fontSize: 13,
    color: '#8E8E93',
    marginTop: 2,
  },
  progressBarContainer: {
    marginBottom: 12,
  },
  progressBarBackground: {
    height: 8,
    backgroundColor: '#E5E5EA',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    borderRadius: 4,
  },
  budgetFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  usageText: {
    fontSize: 13,
    color: '#8E8E93',
  },
  overageText: {
    fontSize: 13,
    fontWeight: '500',
    color: '#FF3B30',
  },
  remainingText: {
    fontSize: 13,
    fontWeight: '500',
    color: '#34C759',
  },
  actionsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginLeft: 12,
  },
  actionButton: {
    padding: 8,
  },
  warningRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginBottom: 8,
    padding: 16,
    borderRadius: 12,
    gap: 12,
  },
  warningInfo: {
    flex: 1,
  },
  warningCategory: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 4,
  },
  warningTextRed: {
    fontSize: 13,
    color: '#FF3B30',
  },
  warningTextOrange: {
    fontSize: 13,
    color: '#FF9500',
  },
  warningAmount: {
    fontSize: 17,
    fontWeight: '600',
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingTop: 100,
    paddingHorizontal: 40,
  },
  emptyTitle: {
    fontSize: 22,
    fontWeight: '600',
    color: '#000000',
    marginTop: 20,
  },
  emptyDescription: {
    fontSize: 15,
    color: '#8E8E93',
    textAlign: 'center',
    marginTop: 12,
    lineHeight: 22,
  },
  createButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    marginTop: 24,
  },
  createButtonText: {
    fontSize: 17,
    fontWeight: '600',
    color: '#FFFFFF',
  },
});

export default BudgetOverviewScreen;
