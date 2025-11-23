/**
 * 添加/编辑分类界面
 * 对应 Swift 版本的 AddCategoryView.swift
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
import Icon from 'react-native-vector-icons/Ionicons';
import * as Haptics from 'expo-haptics';
import { useDatabase } from '../../services/DatabaseProvider';
import DataManager from '../../services/DataManager';
import Category from '../../models/Category';

interface AddCategoryModalProps {
  visible: boolean;
  category: Category | null;
  onClose: () => void;
}

// 预定义图标
const ICONS = [
  'fast-food', 'car', 'cart', 'game-controller', 'home', 'medical',
  'school', 'wallet', 'airplane', 'gift', 'cafe', 'shirt',
  'fitness', 'film', 'book', 'beer', 'phone-portrait', 'build',
];

// 预定义颜色
const COLORS = [
  { name: '蓝色', value: '#007AFF' },
  { name: '绿色', value: '#34C759' },
  { name: '橙色', value: '#FF9500' },
  { name: '红色', value: '#FF3B30' },
  { name: '紫色', value: '#AF52DE' },
  { name: '粉色', value: '#FF2D55' },
  { name: '青色', value: '#5AC8FA' },
  { name: '黄色', value: '#FFCC00' },
];

const AddCategoryModal: React.FC<AddCategoryModalProps> = ({
  visible,
  category,
  onClose,
}) => {
  const database = useDatabase();

  const [name, setName] = useState('');
  const [icon, setIcon] = useState('tag');
  const [color, setColor] = useState('#007AFF');
  const [keywords, setKeywords] = useState('');
  const [showIconPicker, setShowIconPicker] = useState(false);
  const [showColorPicker, setShowColorPicker] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (visible) {
      if (category) {
        // 编辑模式
        setName(category.name);
        setIcon(category.icon);
        setColor(category.color);
        setKeywords(category.keywords.join(', '));
      } else {
        // 新建模式
        setName('');
        setIcon('tag');
        setColor('#007AFF');
        setKeywords('');
      }
    }
  }, [visible, category]);

  const isValid = (): boolean => {
    return name.trim().length > 0;
  };

  const handleSave = async () => {
    if (!isValid()) {
      Alert.alert('错误', '请填写分类名称');
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }

    setIsSubmitting(true);

    try {
      const trimmedName = name.trim();

      // 解析关键词
      const keywordArray = keywords
        .split(',')
        .map(k => k.trim())
        .filter(k => k.length > 0);

      if (category) {
        // 编辑现有分类
        await DataManager.updateCategory(category, {
          name: trimmedName,
          icon,
          color,
          keywords: keywordArray,
        });
      } else {
        // 创建新分类
        await DataManager.saveCategory({
          name: trimmedName,
          icon,
          color,
          keywords: keywordArray,
          isSystem: false,
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

  const renderIconPicker = () => (
    <Modal
      visible={showIconPicker}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={() => setShowIconPicker(false)}
    >
      <View style={styles.pickerContainer}>
        {/* Header */}
        <View style={styles.pickerHeader}>
          <TouchableOpacity onPress={() => setShowIconPicker(false)}>
            <Text style={styles.pickerDone}>完成</Text>
          </TouchableOpacity>
        </View>

        {/* Icon Grid */}
        <ScrollView style={styles.pickerContent}>
          <View style={styles.iconGrid}>
            {ICONS.map((iconName) => (
              <TouchableOpacity
                key={iconName}
                style={[
                  styles.iconItem,
                  icon === iconName && styles.iconItemSelected,
                ]}
                onPress={() => {
                  setIcon(iconName);
                  Haptics.selectionAsync();
                  setTimeout(() => setShowIconPicker(false), 200);
                }}
              >
                <Icon
                  name={iconName}
                  size={32}
                  color={icon === iconName ? color : '#8E8E93'}
                />
              </TouchableOpacity>
            ))}
          </View>
        </ScrollView>
      </View>
    </Modal>
  );

  const renderColorPicker = () => (
    <Modal
      visible={showColorPicker}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={() => setShowColorPicker(false)}
    >
      <View style={styles.pickerContainer}>
        {/* Header */}
        <View style={styles.pickerHeader}>
          <TouchableOpacity onPress={() => setShowColorPicker(false)}>
            <Text style={styles.pickerDone}>完成</Text>
          </TouchableOpacity>
        </View>

        {/* Color Grid */}
        <ScrollView style={styles.pickerContent}>
          <View style={styles.colorGrid}>
            {COLORS.map((colorItem) => (
              <TouchableOpacity
                key={colorItem.value}
                style={styles.colorItem}
                onPress={() => {
                  setColor(colorItem.value);
                  Haptics.selectionAsync();
                  setTimeout(() => setShowColorPicker(false), 200);
                }}
              >
                <View
                  style={[
                    styles.colorCircle,
                    { backgroundColor: colorItem.value },
                    color === colorItem.value && styles.colorCircleSelected,
                  ]}
                >
                  {color === colorItem.value && (
                    <Icon name="checkmark" size={24} color="#FFFFFF" />
                  )}
                </View>
                <Text style={styles.colorName}>{colorItem.name}</Text>
              </TouchableOpacity>
            ))}
          </View>
        </ScrollView>
      </View>
    </Modal>
  );

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
            {category ? '编辑分类' : '新建分类'}
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
              {category ? '保存' : '创建'}
            </Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.content}>
          {/* 预览 */}
          <View style={styles.previewSection}>
            <View style={styles.previewContainer}>
              <View style={[styles.previewIcon, { backgroundColor: color + '33' }]}>
                <Icon name={icon} size={40} color={color} />
              </View>
              <Text style={styles.previewName}>
                {name || '分类名称'}
              </Text>
            </View>
          </View>

          {/* 基本信息 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>基本信息</Text>
            <View style={styles.inputGroup}>
              <TextInput
                style={styles.input}
                value={name}
                onChangeText={(text) => {
                  setName(text);
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                }}
                placeholder="分类名称"
                placeholderTextColor="#C7C7CC"
                autoFocus={!category}
              />

              <TouchableOpacity
                style={styles.selectButton}
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  setShowIconPicker(true);
                }}
              >
                <Text style={styles.selectLabel}>图标</Text>
                <View style={styles.selectValue}>
                  <Icon name={icon} size={24} color={color} />
                  <Icon name="chevron-forward" size={20} color="#C7C7CC" />
                </View>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.selectButton}
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  setShowColorPicker(true);
                }}
              >
                <Text style={styles.selectLabel}>颜色</Text>
                <View style={styles.selectValue}>
                  <View style={[styles.colorPreview, { backgroundColor: color }]} />
                  <Icon name="chevron-forward" size={20} color="#C7C7CC" />
                </View>
              </TouchableOpacity>
            </View>
          </View>

          {/* 关键词 */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>关键词</Text>
            <View style={styles.inputGroup}>
              <TextInput
                style={[styles.input, styles.textArea]}
                value={keywords}
                onChangeText={(text) => {
                  setKeywords(text);
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                }}
                placeholder="例如：麦当劳, 肯德基, 餐厅"
                placeholderTextColor="#C7C7CC"
                multiline
              />
            </View>
            <Text style={styles.sectionFooter}>
              用逗号分隔多个关键词，用于智能分类识别
            </Text>
          </View>
        </ScrollView>

        {/* Icon Picker */}
        {renderIconPicker()}

        {/* Color Picker */}
        {renderColorPicker()}
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
  previewSection: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 32,
    marginBottom: 20,
  },
  previewContainer: {
    alignItems: 'center',
  },
  previewIcon: {
    width: 80,
    height: 80,
    borderRadius: 40,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  previewName: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
  },
  section: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#8E8E93',
    marginBottom: 8,
    paddingHorizontal: 16,
    textTransform: 'uppercase',
  },
  sectionFooter: {
    fontSize: 13,
    color: '#8E8E93',
    paddingHorizontal: 16,
    marginTop: 8,
  },
  inputGroup: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    marginHorizontal: 16,
    overflow: 'hidden',
  },
  input: {
    fontSize: 17,
    color: '#000000',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  textArea: {
    minHeight: 80,
    textAlignVertical: 'top',
  },
  selectButton: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  selectLabel: {
    fontSize: 17,
    color: '#000000',
  },
  selectValue: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  colorPreview: {
    width: 24,
    height: 24,
    borderRadius: 12,
  },
  pickerContainer: {
    flex: 1,
    backgroundColor: '#F2F2F7',
  },
  pickerHeader: {
    paddingHorizontal: 16,
    paddingTop: Platform.OS === 'ios' ? 60 : 20,
    paddingBottom: 16,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
    alignItems: 'flex-end',
  },
  pickerDone: {
    fontSize: 17,
    fontWeight: '600',
    color: '#007AFF',
  },
  pickerContent: {
    flex: 1,
    padding: 16,
  },
  iconGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 16,
  },
  iconItem: {
    width: 64,
    height: 64,
    borderRadius: 12,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: 'transparent',
  },
  iconItemSelected: {
    borderColor: '#007AFF',
  },
  colorGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 20,
  },
  colorItem: {
    alignItems: 'center',
    width: 80,
  },
  colorCircle: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  colorCircleSelected: {
    borderWidth: 3,
    borderColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 4,
  },
  colorName: {
    fontSize: 13,
    color: '#000000',
  },
});

export default AddCategoryModal;
