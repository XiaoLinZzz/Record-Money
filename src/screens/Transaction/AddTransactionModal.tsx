/**
 * 添加交易界面
 * 对应 Swift 版本的 AddTransactionView.swift
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
import DateTimePicker from '@react-native-community/datetimepicker';
import * as Haptics from 'expo-haptics';
import { useDatabase } from '../../services/DatabaseProvider';
import DataManager from '../../services/DataManager';
import CategoryEngine from '../../services/CategoryEngine';
import Category from '../../models/Category';

interface AddTransactionModalProps {
  visible: boolean;
  onClose: () => void;
}

const AddTransactionModal: React.FC<AddTransactionModalProps> = ({
  visible,
  onClose,
}) => {
  const database = useDatabase();

  // State
  const [amount, setAmount] = useState('');
  const [merchant, setMerchant] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('餐饮');
  const [transactionType, setTransactionType] = useState<'expense' | 'income'>('expense');
  const [note, setNote] = useState('');
  const [date, setDate] = useState(new Date());
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showCategoryPicker, setShowCategoryPicker] = useState(false);

  const [categories, setCategories] = useState<Category[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (visible) {
      loadCategories();
    }
  }, [visible]);

  // 智能分类建议
  useEffect(() => {
    if (merchant.trim()) {
      const suggestCategory = async () => {
        const suggested = await CategoryEngine.suggestCategory(merchant);
        if (suggested) {
          setSelectedCategory(suggested);
        }
      };
      suggestCategory();
    }
  }, [merchant]);

  const loadCategories = async () => {
    try {
      DataManager.initialize(database);
      const fetchedCategories = await DataManager.fetchCategories();
      setCategories(fetchedCategories);
      if (fetchedCategories.length > 0 && !selectedCategory) {
        setSelectedCategory(fetchedCategories[0].name);
      }
    } catch (error) {
      console.error('Failed to load categories:', error);
      Alert.alert('错误', '加载分类失败');
    }
  };

  const isValid = (): boolean => {
    const amountValue = parseFloat(amount);
    if (isNaN(amountValue) || amountValue <= 0) {
      return false;
    }
    return merchant.trim().length > 0;
  };

  const handleSave = async () => {
    if (!isValid()) {
      Alert.alert('错误', '请填写有效的金额和商家名称');
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }

    setIsSubmitting(true);

    try {
      const amountValue = parseFloat(amount);

      await DataManager.saveTransaction({
        amount: amountValue,
        merchant: merchant.trim(),
        categoryName: selectedCategory,
        type: transactionType,
        paymentMethod: '手动添加',
        timestamp: date,
        note: note.trim() || undefined,
      });

      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

      // 学习用户的分类选择
      const inferredCategory = CategoryEngine.inferCategory(merchant);
      if (inferredCategory !== selectedCategory) {
        await CategoryEngine.learnFromUserCorrection(merchant, selectedCategory);
      }

      resetForm();
      onClose();
    } catch (error) {
      console.error('Failed to save transaction:', error);
      Alert.alert('错误', '保存失败，请重试');
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCancel = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    resetForm();
    onClose();
  };

  const resetForm = () => {
    setAmount('');
    setMerchant('');
    setSelectedCategory('餐饮');
    setTransactionType('expense');
    setNote('');
    setDate(new Date());
  };

  const formatDate = (date: Date): string => {
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
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
          <Text style={styles.headerTitle}>添加交易</Text>
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
              保存
            </Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content}>
          {/* 金额 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>金额</Text>
            <View style={styles.amountContainer}>
              <Text style={styles.currencySymbol}>¥</Text>
              <TextInput
                style={styles.amountInput}
                value={amount}
                onChangeText={setAmount}
                placeholder="0.00"
                keyboardType="decimal-pad"
                autoFocus
              />
            </View>
          </View>

          {/* 商家 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>商家</Text>
            <TextInput
              style={styles.input}
              value={merchant}
              onChangeText={setMerchant}
              placeholder="商家名称"
              returnKeyType="done"
            />
          </View>

          {/* 分类 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>分类</Text>
            <TouchableOpacity
              style={styles.picker}
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                setShowCategoryPicker(true);
              }}
            >
              <Text style={styles.pickerText}>{selectedCategory}</Text>
              <Text style={styles.chevron}>›</Text>
            </TouchableOpacity>
          </View>

          {/* 类型 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>类型</Text>
            <View style={styles.segmentedControl}>
              <TouchableOpacity
                style={[
                  styles.segment,
                  transactionType === 'expense' && styles.segmentActive,
                ]}
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  setTransactionType('expense');
                }}
              >
                <Text
                  style={[
                    styles.segmentText,
                    transactionType === 'expense' && styles.segmentTextActive,
                  ]}
                >
                  支出
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.segment,
                  transactionType === 'income' && styles.segmentActive,
                ]}
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  setTransactionType('income');
                }}
              >
                <Text
                  style={[
                    styles.segmentText,
                    transactionType === 'income' && styles.segmentTextActive,
                  ]}
                >
                  收入
                </Text>
              </TouchableOpacity>
            </View>
          </View>

          {/* 日期 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>日期</Text>
            <TouchableOpacity
              style={styles.picker}
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                setShowDatePicker(true);
              }}
            >
              <Text style={styles.pickerText}>{formatDate(date)}</Text>
              <Text style={styles.chevron}>›</Text>
            </TouchableOpacity>
          </View>

          {/* 备注 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>备注</Text>
            <TextInput
              style={styles.noteInput}
              value={note}
              onChangeText={setNote}
              placeholder="添加备注（可选）"
              multiline
              numberOfLines={3}
              textAlignVertical="top"
            />
          </View>
        </ScrollView>

        {/* Date Picker */}
        {showDatePicker && (
          <Modal transparent animationType="slide">
            <View style={styles.pickerModal}>
              <View style={styles.pickerHeader}>
                <TouchableOpacity
                  onPress={() => setShowDatePicker(false)}
                  style={styles.pickerButton}
                >
                  <Text style={styles.pickerButtonText}>完成</Text>
                </TouchableOpacity>
              </View>
              <DateTimePicker
                value={date}
                mode="datetime"
                display="spinner"
                onChange={(event, selectedDate) => {
                  if (selectedDate) {
                    setDate(selectedDate);
                  }
                }}
                locale="zh-CN"
              />
            </View>
          </Modal>
        )}

        {/* Category Picker */}
        {showCategoryPicker && (
          <Modal transparent animationType="slide">
            <View style={styles.pickerModal}>
              <View style={styles.pickerHeader}>
                <TouchableOpacity
                  onPress={() => setShowCategoryPicker(false)}
                  style={styles.pickerButton}
                >
                  <Text style={styles.pickerButtonText}>完成</Text>
                </TouchableOpacity>
              </View>
              <ScrollView style={styles.categoryList}>
                {categories.map(category => (
                  <TouchableOpacity
                    key={category.id}
                    style={styles.categoryItem}
                    onPress={() => {
                      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                      setSelectedCategory(category.name);
                      setShowCategoryPicker(false);
                    }}
                  >
                    <Text
                      style={[
                        styles.categoryItemText,
                        selectedCategory === category.name &&
                          styles.categoryItemTextActive,
                      ]}
                    >
                      {category.name}
                    </Text>
                    {selectedCategory === category.name && (
                      <Text style={styles.checkmark}>✓</Text>
                    )}
                  </TouchableOpacity>
                ))}
              </ScrollView>
            </View>
          </Modal>
        )}
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
    paddingVertical: 12,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#8E8E93',
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  amountContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  currencySymbol: {
    fontSize: 28,
    fontWeight: '600',
    color: '#8E8E93',
    marginRight: 8,
  },
  amountInput: {
    fontSize: 28,
    fontWeight: '600',
    color: '#000000',
    flex: 1,
  },
  input: {
    fontSize: 17,
    color: '#000000',
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  picker: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  pickerText: {
    fontSize: 17,
    color: '#000000',
  },
  chevron: {
    fontSize: 20,
    color: '#C7C7CC',
  },
  segmentedControl: {
    flexDirection: 'row',
    backgroundColor: '#F2F2F7',
    borderRadius: 8,
    padding: 2,
  },
  segment: {
    flex: 1,
    paddingVertical: 8,
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
  },
  noteInput: {
    fontSize: 17,
    color: '#000000',
    paddingVertical: 8,
    minHeight: 80,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#E5E5EA',
    borderRadius: 8,
    padding: 12,
  },
  pickerModal: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    marginTop: 'auto',
    borderTopLeftRadius: 12,
    borderTopRightRadius: 12,
  },
  pickerHeader: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  pickerButton: {
    paddingVertical: 8,
  },
  pickerButtonText: {
    fontSize: 17,
    fontWeight: '600',
    color: '#007AFF',
  },
  categoryList: {
    flex: 1,
  },
  categoryItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  categoryItemText: {
    fontSize: 17,
    color: '#000000',
  },
  categoryItemTextActive: {
    color: '#007AFF',
    fontWeight: '600',
  },
  checkmark: {
    fontSize: 20,
    color: '#007AFF',
    fontWeight: '600',
  },
});

export default AddTransactionModal;
