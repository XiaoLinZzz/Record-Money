/**
 * 设置预算界面
 * 对应 Swift 版本的 SetBudgetView.swift
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Modal,
  Platform,
  Alert,
  KeyboardAvoidingView,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import * as Haptics from 'expo-haptics';
import { useDatabase } from '../../services/DatabaseProvider';
import BudgetManager from '../../services/BudgetManager';
import Budget, { BudgetPeriod, BudgetPeriodDisplay } from '../../models/Budget';
import Category from '../../models/Category';

interface SetBudgetModalProps {
  visible: boolean;
  budget: Budget | null;
  categories: Category[];
  onClose: () => void;
}

const SetBudgetModal: React.FC<SetBudgetModalProps> = ({
  visible,
  budget,
  categories,
  onClose,
}) => {
  const database = useDatabase();
  const budgetManager = BudgetManager.getInstance();

  const [selectedCategory, setSelectedCategory] = useState('');
  const [amount, setAmount] = useState('');
  const [period, setPeriod] = useState<BudgetPeriod>('monthly');
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (visible) {
      if (budget) {
        // 编辑模式
        setSelectedCategory(budget.categoryName || '');
        setAmount(budget.amount.toFixed(2));
        setPeriod(budget.period);
      } else {
        // 新建模式
        setSelectedCategory(categories[0]?.name || '');
        setAmount('');
        setPeriod('monthly');
      }
    }
  }, [visible, budget, categories]);

  const isValid = (): boolean => {
    const amountValue = parseFloat(amount);
    if (isNaN(amountValue) || amountValue <= 0) {
      return false;
    }
    return selectedCategory.trim().length > 0;
  };

  const handleSave = async () => {
    if (!isValid()) {
      Alert.alert('错误', '请填写有效的金额和选择分类');
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }

    setIsSubmitting(true);

    try {
      const amountValue = parseFloat(amount);

      if (budget) {
        // 编辑现有预算
        await budgetManager.updateBudget(budget, {
          categoryName: selectedCategory.trim(),
          amount: amountValue,
          period,
        });
      } else {
        // 创建新预算
        await budgetManager.saveBudget({
          categoryName: selectedCategory.trim(),
          amount: amountValue,
          period,
          startDate: new Date(),
          alertThreshold: 0.9,
        });
      }

      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      onClose();
    } catch (error) {
      console.error('保存失败:', error);
      Alert.alert('错误', '保存失败，请重试');
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCancel = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onClose();
  };

  const formatPreviewAmount = (): string => {
    const amountValue = parseFloat(amount);
    if (isNaN(amountValue) || amountValue <= 0) return '';
    return amountValue.toFixed(2);
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={handleCancel}
    >
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={handleCancel} style={styles.headerButton}>
            <Text style={styles.cancelText}>取消</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>
            {budget ? '编辑预算' : '新建预算'}
          </Text>
          <TouchableOpacity
            onPress={handleSave}
            style={styles.headerButton}
            disabled={isSubmitting || !isValid()}
          >
            <Text
              style={[
                styles.saveText,
                (!isValid() || isSubmitting) && styles.saveTextDisabled,
              ]}
            >
              {budget ? '保存' : '创建'}
            </Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content}>
          {/* 分类选择 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>预算分类</Text>
            <View style={styles.pickerContainer}>
              <Picker
                selectedValue={selectedCategory}
                onValueChange={(value) => {
                  setSelectedCategory(value);
                  Haptics.selectionAsync();
                }}
                style={styles.picker}
              >
                {categories.map((category) => (
                  <Picker.Item
                    key={category.id}
                    label={category.name}
                    value={category.name}
                  />
                ))}
              </Picker>
            </View>
          </View>

          {/* 金额输入 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>预算金额</Text>
            <View style={styles.amountContainer}>
              <Text style={styles.currencySymbol}>¥</Text>
              <TextInput
                style={styles.amountInput}
                value={amount}
                onChangeText={setAmount}
                placeholder="0.00"
                placeholderTextColor="#C7C7CC"
                keyboardType="decimal-pad"
                autoFocus={!budget}
              />
            </View>
            <Text style={styles.sectionFooter}>设置该分类的预算上限</Text>
          </View>

          {/* 周期选择 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>预算周期</Text>
            <View style={styles.segmentedControl}>
              <TouchableOpacity
                style={[
                  styles.segment,
                  period === 'monthly' && styles.segmentActive,
                ]}
                onPress={() => {
                  Haptics.selectionAsync();
                  setPeriod('monthly');
                }}
              >
                <Text
                  style={[
                    styles.segmentText,
                    period === 'monthly' && styles.segmentTextActive,
                  ]}
                >
                  每月
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.segment,
                  period === 'yearly' && styles.segmentActive,
                ]}
                onPress={() => {
                  Haptics.selectionAsync();
                  setPeriod('yearly');
                }}
              >
                <Text
                  style={[
                    styles.segmentText,
                    period === 'yearly' && styles.segmentTextActive,
                  ]}
                >
                  每年
                </Text>
              </TouchableOpacity>
            </View>
          </View>

          {/* 预览 */}
          {formatPreviewAmount() && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>预览</Text>
              <View style={styles.previewCard}>
                <View style={styles.previewInfo}>
                  <Text style={styles.previewCategory}>{selectedCategory}</Text>
                  <Text style={styles.previewPeriod}>
                    {BudgetPeriodDisplay[period]}预算
                  </Text>
                </View>
                <Text style={styles.previewAmount}>
                  ¥{formatPreviewAmount()}
                </Text>
              </View>
            </View>
          )}
        </ScrollView>
      </KeyboardAvoidingView>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: Platform.OS === 'ios' ? 60 : 20,
    paddingBottom: 16,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  headerButton: {
    paddingVertical: 8,
    paddingHorizontal: 4,
    minWidth: 60,
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
  },
  cancelText: {
    fontSize: 17,
    color: '#007AFF',
  },
  saveText: {
    fontSize: 17,
    fontWeight: '600',
    color: '#007AFF',
    textAlign: 'right',
  },
  saveTextDisabled: {
    color: '#C7C7CC',
  },
  content: {
    flex: 1,
  },
  section: {
    backgroundColor: '#FFFFFF',
    marginTop: 20,
    paddingHorizontal: 16,
    paddingVertical: 16,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#8E8E93',
    marginBottom: 12,
    textTransform: 'uppercase',
  },
  sectionFooter: {
    fontSize: 13,
    color: '#8E8E93',
    marginTop: 8,
  },
  pickerContainer: {
    borderWidth: 1,
    borderColor: '#E5E5EA',
    borderRadius: 8,
    overflow: 'hidden',
  },
  picker: {
    height: 50,
  },
  amountContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E5E5EA',
    borderRadius: 8,
    paddingHorizontal: 16,
  },
  currencySymbol: {
    fontSize: 24,
    fontWeight: '600',
    color: '#8E8E93',
    marginRight: 8,
  },
  amountInput: {
    fontSize: 24,
    fontWeight: '600',
    color: '#000000',
    flex: 1,
    paddingVertical: 12,
  },
  segmentedControl: {
    flexDirection: 'row',
    backgroundColor: '#F2F2F7',
    borderRadius: 8,
    padding: 2,
  },
  segment: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    borderRadius: 6,
  },
  segmentActive: {
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  segmentText: {
    fontSize: 15,
    color: '#8E8E93',
    fontWeight: '500',
  },
  segmentTextActive: {
    color: '#000000',
    fontWeight: '600',
  },
  previewCard: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#F2F2F7',
    borderRadius: 8,
  },
  previewInfo: {
    flex: 1,
  },
  previewCategory: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 4,
  },
  previewPeriod: {
    fontSize: 13,
    color: '#8E8E93',
  },
  previewAmount: {
    fontSize: 20,
    fontWeight: '700',
    color: '#007AFF',
  },
});

export default SetBudgetModal;
