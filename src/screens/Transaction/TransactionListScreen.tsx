/**
 * 交易列表界面
 * 对应 Swift 版本的 TransactionListView.swift
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  Platform,
} from 'react-native';
import { useDatabase } from '../../services/DatabaseProvider';
import DataManager from '../../services/DataManager';
import Transaction from '../../models/Transaction';
import { format, startOfDay, isSameDay } from 'date-fns';
import Icon from 'react-native-vector-icons/Ionicons';
import * as Haptics from 'expo-haptics';
import AddTransactionModal from './AddTransactionModal';
import EditTransactionModal from './EditTransactionModal';

const TransactionListScreen: React.FC = () => {
  const database = useDatabase();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [selectedTransaction, setSelectedTransaction] = useState<Transaction | null>(null);

  useEffect(() => {
    DataManager.initialize(database);
    loadTransactions();

    // 监听数据变更
    const listener = () => {
      loadTransactions();
    };
    DataManager.on('transactionDidChange', listener);

    return () => {
      DataManager.off('transactionDidChange', listener);
    };
  }, [database]);

  const loadTransactions = async () => {
    try {
      const data = await DataManager.fetchTransactions();
      setTransactions(data);
    } catch (error) {
      console.error('Failed to load transactions:', error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadTransactions();
  };

  const handleDelete = async (transaction: Transaction) => {
    try {
      await DataManager.deleteTransaction(transaction);
    } catch (error) {
      console.error('Failed to delete transaction:', error);
    }
  };

  const handleTransactionPress = (transaction: Transaction) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setSelectedTransaction(transaction);
    setShowEditModal(true);
  };

  const renderTransactionItem = ({ item }: { item: Transaction }) => (
    <TouchableOpacity
      style={styles.transactionCard}
      onPress={() => handleTransactionPress(item)}
    >
      <View style={styles.transactionLeft}>
        <View style={styles.iconContainer}>
          <Icon name="card-outline" size={24} color="#007AFF" />
        </View>
        <View style={styles.transactionInfo}>
          <Text style={styles.merchantText}>{item.merchant}</Text>
          <Text style={styles.categoryText}>
            {item.categoryName}
            {item.paymentMethod ? ` · ${item.paymentMethod}` : ''}
          </Text>
        </View>
      </View>
      <View style={styles.transactionRight}>
        <Text
          style={[
            styles.amountText,
            item.isExpense ? styles.expenseAmount : styles.incomeAmount,
          ]}
        >
          {item.isExpense ? '-' : '+'}
          {item.formattedAmount}
        </Text>
        <Text style={styles.dateText}>{item.shortDate}</Text>
      </View>
    </TouchableOpacity>
  );

  const renderSectionHeader = (date: Date) => (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionTitle}>
        {isSameDay(date, new Date())
          ? '今天'
          : format(date, 'MM月dd日')}
      </Text>
    </View>
  );

  // 按日期分组
  const groupedTransactions = transactions.reduce((groups, transaction) => {
    const dateKey = format(startOfDay(transaction.timestamp), 'yyyy-MM-dd');
    if (!groups[dateKey]) {
      groups[dateKey] = [];
    }
    groups[dateKey].push(transaction);
    return groups;
  }, {} as { [key: string]: Transaction[] });

  const sections = Object.entries(groupedTransactions).map(([date, items]) => ({
    date: new Date(date),
    data: items,
  }));

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <Text>加载中...</Text>
      </View>
    );
  }

  if (transactions.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <Icon name="receipt-outline" size={80} color="#C7C7CC" />
        <Text style={styles.emptyText}>暂无交易记录</Text>
        <Text style={styles.emptySubText}>点击 + 按钮添加第一笔记账</Text>

        {/* Floating Action Button */}
        <TouchableOpacity
          style={styles.fab}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
            setShowAddModal(true);
          }}
        >
          <Icon name="add" size={32} color="#FFFFFF" />
        </TouchableOpacity>

        {/* Add Transaction Modal */}
        <AddTransactionModal
          visible={showAddModal}
          onClose={() => setShowAddModal(false)}
        />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={sections}
        keyExtractor={item => item.date.toISOString()}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        renderItem={({ item: section }) => (
          <View>
            {renderSectionHeader(section.date)}
            {section.data.map(transaction => (
              <View key={transaction.id}>
                {renderTransactionItem({ item: transaction })}
              </View>
            ))}
          </View>
        )}
      />

      {/* Floating Action Button */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
          setShowAddModal(true);
        }}
      >
        <Icon name="add" size={32} color="#FFFFFF" />
      </TouchableOpacity>

      {/* Add Transaction Modal */}
      <AddTransactionModal
        visible={showAddModal}
        onClose={() => setShowAddModal(false)}
      />

      {/* Edit Transaction Modal */}
      <EditTransactionModal
        visible={showEditModal}
        transaction={selectedTransaction}
        onClose={() => {
          setShowEditModal(false);
          setSelectedTransaction(null);
        }}
      />
    </View>
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
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
  },
  emptyText: {
    fontSize: 20,
    fontWeight: '600',
    color: '#8E8E93',
    marginTop: 20,
  },
  emptySubText: {
    fontSize: 14,
    color: '#C7C7CC',
    marginTop: 8,
    textAlign: 'center',
  },
  sectionHeader: {
    backgroundColor: '#F2F2F7',
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#8E8E93',
  },
  transactionCard: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  transactionLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  iconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F2F2F7',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  transactionInfo: {
    flex: 1,
  },
  merchantText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#000000',
    marginBottom: 4,
  },
  categoryText: {
    fontSize: 13,
    color: '#8E8E93',
  },
  transactionRight: {
    alignItems: 'flex-end',
  },
  amountText: {
    fontSize: 17,
    fontWeight: '600',
    marginBottom: 4,
  },
  expenseAmount: {
    color: '#FF3B30',
  },
  incomeAmount: {
    color: '#34C759',
  },
  dateText: {
    fontSize: 12,
    color: '#C7C7CC',
  },
  fab: {
    position: 'absolute',
    right: 20,
    bottom: Platform.OS === 'ios' ? 100 : 20,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
});

export default TransactionListScreen;
