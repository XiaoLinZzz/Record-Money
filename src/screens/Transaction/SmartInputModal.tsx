/**
 * 智能输入界面
 * 对应 Swift 版本的 SmartInputView.swift
 * 支持自然语言输入交易信息
 */

import React, { useState, useEffect, useRef } from 'react';
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
import * as Haptics from 'expo-haptics';
import Icon from 'react-native-vector-icons/Ionicons';
import { useDatabase } from '../../services/DatabaseProvider';
import DataManager from '../../services/DataManager';
import NLPParser, { ParsedTransaction } from '../../services/NLPParser';
import { format } from 'date-fns';

interface SmartInputModalProps {
  visible: boolean;
  onClose: () => void;
}

const SmartInputModal: React.FC<SmartInputModalProps> = ({
  visible,
  onClose,
}) => {
  const database = useDatabase();

  const [inputText, setInputText] = useState('');
  const [parsedTransaction, setParsedTransaction] = useState<ParsedTransaction | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (visible) {
      DataManager.initialize(database);
      setInputText('');
      setParsedTransaction(null);
    }
  }, [visible]);

  // 实时解析（带防抖）
  useEffect(() => {
    if (inputText.trim()) {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }

      debounceTimerRef.current = setTimeout(() => {
        parseInput();
      }, 500); // 500ms 防抖
    } else {
      setParsedTransaction(null);
    }

    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
    };
  }, [inputText]);

  const parseInput = () => {
    if (!inputText.trim()) return;

    try {
      const parsed = NLPParser.parse(inputText);
      setParsedTransaction(parsed);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch (error) {
      console.error('Failed to parse input:', error);
    }
  };

  const handleClear = () => {
    setInputText('');
    setParsedTransaction(null);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const handleConfirm = async () => {
    if (!parsedTransaction || !parsedTransaction.amount || !parsedTransaction.merchant) {
      Alert.alert('提示', '请确保至少包含金额和商家信息');
      return;
    }

    setIsProcessing(true);

    try {
      await DataManager.saveTransaction({
        amount: parsedTransaction.amount,
        merchant: parsedTransaction.merchant,
        categoryName: parsedTransaction.category || '其他',
        type: parsedTransaction.transactionType,
        timestamp: parsedTransaction.date || new Date(),
        rawText: inputText,
        paymentMethod: '智能输入',
      });

      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

      setInputText('');
      setParsedTransaction(null);
      onClose();
    } catch (error) {
      console.error('Failed to save transaction:', error);
      Alert.alert('错误', '保存失败，请重试');
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleClose = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onClose();
  };

  const getConfidenceColor = (confidence: number): string => {
    if (confidence >= 0.8) return '#34C759';
    if (confidence >= 0.5) return '#FF9500';
    return '#FF3B30';
  };

  const getConfidenceIcon = (confidence: number): string => {
    if (confidence >= 0.8) return 'checkmark-circle';
    if (confidence >= 0.5) return 'alert-circle';
    return 'close-circle';
  };

  const examples = [
    '今天中午星巴克花了35块',
    '昨天打车用了20元',
    '晚上在麦当劳吃饭42元',
    '收到工资5000元',
  ];

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={handleClose}
    >
      <KeyboardAvoidingView
        style={styles.container}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={handleClose} style={styles.headerButton}>
            <Text style={styles.cancelText}>取消</Text>
          </TouchableOpacity>
          <Text style={styles.headerTitle}>智能记账</Text>
          <View style={styles.headerButton} />
        </View>

        <ScrollView style={styles.content} keyboardShouldPersistTaps="handled">
          {/* 说明区域 */}
          <View style={styles.instructionCard}>
            <View style={styles.instructionHeader}>
              <Icon name="sparkles" size={24} color="#007AFF" />
              <Text style={styles.instructionTitle}>用自然语言描述交易</Text>
            </View>
            <Text style={styles.instructionText}>
              例如："今天中午星巴克花了35块" 或 "昨天打车20元"
            </Text>
          </View>

          {/* 输入区域 */}
          <View style={styles.inputCard}>
            <Text style={styles.inputLabel}>输入交易描述</Text>
            <TextInput
              style={styles.input}
              value={inputText}
              onChangeText={setInputText}
              placeholder="例如：星巴克买咖啡35元"
              placeholderTextColor="#C7C7CC"
              multiline
              numberOfLines={2}
              autoFocus
              returnKeyType="done"
              onSubmitEditing={parseInput}
            />

            <View style={styles.buttonRow}>
              <TouchableOpacity
                style={[styles.button, styles.clearButton]}
                onPress={handleClear}
                disabled={!inputText}
              >
                <Icon name="close-circle" size={20} color="#8E8E93" />
                <Text style={styles.clearButtonText}>清空</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.button, styles.parseButton]}
                onPress={parseInput}
                disabled={!inputText}
              >
                <Icon name="flash" size={20} color="#FFFFFF" />
                <Text style={styles.parseButtonText}>解析</Text>
              </TouchableOpacity>
            </View>
          </View>

          {/* 解析结果 */}
          {parsedTransaction && (
            <View style={styles.resultCard}>
              <View style={styles.resultHeader}>
                <Text style={styles.resultTitle}>识别结果</Text>
                <View style={styles.confidenceBadge}>
                  <Icon
                    name={getConfidenceIcon(parsedTransaction.confidence)}
                    size={16}
                    color={getConfidenceColor(parsedTransaction.confidence)}
                  />
                  <Text
                    style={[
                      styles.confidenceText,
                      { color: getConfidenceColor(parsedTransaction.confidence) },
                    ]}
                  >
                    {Math.round(parsedTransaction.confidence * 100)}%
                  </Text>
                </View>
              </View>

              <View style={styles.resultItems}>
                {parsedTransaction.amount !== undefined && (
                  <View style={styles.resultItem}>
                    <Icon name="cash" size={20} color="#34C759" />
                    <Text style={styles.resultLabel}>金额</Text>
                    <Text style={styles.resultValue}>
                      ¥{parsedTransaction.amount.toFixed(2)}
                    </Text>
                  </View>
                )}

                {parsedTransaction.merchant && (
                  <View style={styles.resultItem}>
                    <Icon name="business" size={20} color="#007AFF" />
                    <Text style={styles.resultLabel}>商家</Text>
                    <Text style={styles.resultValue}>
                      {parsedTransaction.merchant}
                    </Text>
                  </View>
                )}

                {parsedTransaction.category && (
                  <View style={styles.resultItem}>
                    <Icon name="pricetag" size={20} color="#FF9500" />
                    <Text style={styles.resultLabel}>分类</Text>
                    <Text style={styles.resultValue}>
                      {parsedTransaction.category}
                    </Text>
                  </View>
                )}

                {parsedTransaction.date && (
                  <View style={styles.resultItem}>
                    <Icon name="calendar" size={20} color="#5856D6" />
                    <Text style={styles.resultLabel}>日期</Text>
                    <Text style={styles.resultValue}>
                      {format(parsedTransaction.date, 'MM月dd日 HH:mm')}
                    </Text>
                  </View>
                )}

                <View style={styles.resultItem}>
                  <Icon
                    name={parsedTransaction.transactionType === 'income' ? 'arrow-down-circle' : 'arrow-up-circle'}
                    size={20}
                    color={parsedTransaction.transactionType === 'income' ? '#34C759' : '#FF3B30'}
                  />
                  <Text style={styles.resultLabel}>类型</Text>
                  <Text style={styles.resultValue}>
                    {parsedTransaction.transactionType === 'income' ? '收入' : '支出'}
                  </Text>
                </View>
              </View>

              {/* 确认按钮 */}
              <TouchableOpacity
                style={[
                  styles.confirmButton,
                  (!parsedTransaction.amount || !parsedTransaction.merchant || isProcessing) &&
                    styles.confirmButtonDisabled,
                ]}
                onPress={handleConfirm}
                disabled={!parsedTransaction.amount || !parsedTransaction.merchant || isProcessing}
              >
                <Text style={styles.confirmButtonText}>
                  {isProcessing ? '保存中...' : '确认并保存'}
                </Text>
              </TouchableOpacity>
            </View>
          )}

          {/* 示例 */}
          <View style={styles.exampleCard}>
            <Text style={styles.exampleTitle}>试试这些示例：</Text>
            {examples.map((example, index) => (
              <TouchableOpacity
                key={index}
                style={styles.exampleItem}
                onPress={() => {
                  setInputText(example);
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                }}
              >
                <Icon name="bulb-outline" size={16} color="#8E8E93" />
                <Text style={styles.exampleText}>{example}</Text>
              </TouchableOpacity>
            ))}
          </View>
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
  content: {
    flex: 1,
  },
  instructionCard: {
    backgroundColor: '#FFFFFF',
    margin: 16,
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  instructionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  instructionTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
    marginLeft: 8,
  },
  instructionText: {
    fontSize: 13,
    color: '#8E8E93',
    lineHeight: 18,
  },
  inputCard: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginBottom: 16,
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  inputLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: '#8E8E93',
    marginBottom: 8,
  },
  input: {
    fontSize: 17,
    color: '#000000',
    borderWidth: 1,
    borderColor: '#E5E5EA',
    borderRadius: 8,
    padding: 12,
    minHeight: 60,
    marginBottom: 12,
    textAlignVertical: 'top',
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 12,
  },
  button: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 8,
    gap: 6,
  },
  clearButton: {
    backgroundColor: '#F2F2F7',
  },
  clearButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#8E8E93',
  },
  parseButton: {
    backgroundColor: '#007AFF',
  },
  parseButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  resultCard: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginBottom: 16,
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  resultHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  resultTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
  },
  confidenceBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  confidenceText: {
    fontSize: 13,
    fontWeight: '600',
  },
  resultItems: {
    gap: 12,
  },
  resultItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  resultLabel: {
    fontSize: 15,
    color: '#8E8E93',
    marginLeft: 12,
    flex: 1,
  },
  resultValue: {
    fontSize: 15,
    fontWeight: '500',
    color: '#000000',
  },
  confirmButton: {
    backgroundColor: '#007AFF',
    paddingVertical: 14,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 16,
  },
  confirmButtonDisabled: {
    backgroundColor: '#C7C7CC',
  },
  confirmButtonText: {
    fontSize: 17,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  exampleCard: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    marginBottom: 16,
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  exampleTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 12,
  },
  exampleItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    gap: 8,
  },
  exampleText: {
    fontSize: 15,
    color: '#007AFF',
  },
});

export default SmartInputModal;
