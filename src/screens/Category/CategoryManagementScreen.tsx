/**
 * 分类管理界面
 * 对应 Swift 版本的 CategoryManagementView.swift
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
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import * as Haptics from 'expo-haptics';
import { useDatabase } from '../../services/DatabaseProvider';
import DataManager from '../../services/DataManager';
import Category from '../../models/Category';
import AddCategoryModal from './AddCategoryModal';

interface CategoryManagementScreenProps {
  navigation: any;
}

const CategoryManagementScreen: React.FC<CategoryManagementScreenProps> = ({ navigation }) => {
  const database = useDatabase();

  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [showAddCategory, setShowAddCategory] = useState(false);
  const [categoryToEdit, setCategoryToEdit] = useState<Category | null>(null);

  useEffect(() => {
    if (database) {
      DataManager.initialize(database);
      loadCategories();
    }
  }, [database]);

  useEffect(() => {
    // 设置导航栏按钮
    navigation.setOptions({
      headerRight: () => (
        <TouchableOpacity
          style={styles.headerButton}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            setShowAddCategory(true);
          }}
        >
          <Icon name="add-circle" size={28} color="#007AFF" />
        </TouchableOpacity>
      ),
    });
  }, [navigation]);

  useEffect(() => {
    // 监听分类变化
    const handleCategoryChange = () => {
      loadCategories();
    };

    DataManager.on('categoryDidChange', handleCategoryChange);

    return () => {
      DataManager.off('categoryDidChange', handleCategoryChange);
    };
  }, []);

  const loadCategories = async () => {
    setIsLoading(true);

    try {
      const fetchedCategories = await DataManager.fetchCategories();
      setCategories(fetchedCategories);
    } catch (error) {
      console.error('加载分类失败:', error);
      Alert.alert('错误', '加载分类失败，请重试');
    } finally {
      setIsLoading(false);
    }
  };

  const handleRefresh = useCallback(async () => {
    await loadCategories();
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  }, []);

  const handleDeleteCategory = async (category: Category) => {
    // 检查是否有交易使用此分类
    try {
      const transactions = await DataManager.fetchTransactions(category.name);

      if (transactions.length > 0) {
        Alert.alert(
          '无法删除',
          `该分类下还有 ${transactions.length} 条交易记录`
        );
        await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        return;
      }

      Alert.alert(
        '确认删除',
        `确定要删除分类 "${category.name}" 吗？`,
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
                await DataManager.deleteCategory(category);
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
    } catch (error) {
      console.error('检查分类使用情况失败:', error);
      Alert.alert('错误', '操作失败，请重试');
    }
  };

  const getColorValue = (colorHex: string): string => {
    return colorHex || '#007AFF';
  };

  const renderCategoryRow = (category: Category, isSystem: boolean) => {
    const colorValue = getColorValue(category.color);

    return (
      <TouchableOpacity
        key={category.id}
        style={styles.categoryRow}
        onPress={() => {
          if (!isSystem) {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            setCategoryToEdit(category);
          }
        }}
        disabled={isSystem}
      >
        {/* 图标 */}
        <View style={[styles.iconContainer, { backgroundColor: colorValue + '33' }]}>
          <Icon name={category.icon} size={24} color={colorValue} />
        </View>

        {/* 信息 */}
        <View style={styles.categoryInfo}>
          <Text style={styles.categoryName}>{category.name}</Text>
          {category.keywords.length > 0 && (
            <Text style={styles.keywords} numberOfLines={1}>
              {category.keywords.join(', ')}
            </Text>
          )}
        </View>

        {/* 自定义标签 */}
        {!isSystem && (
          <View style={styles.customBadge}>
            <Text style={styles.customBadgeText}>自定义</Text>
          </View>
        )}

        {/* 操作按钮 */}
        {!isSystem && (
          <View style={styles.actionsContainer}>
            <TouchableOpacity
              style={styles.actionButton}
              onPress={() => {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                setCategoryToEdit(category);
              }}
            >
              <Icon name="pencil" size={20} color="#007AFF" />
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.actionButton}
              onPress={() => handleDeleteCategory(category)}
            >
              <Icon name="trash" size={20} color="#FF3B30" />
            </TouchableOpacity>
          </View>
        )}
      </TouchableOpacity>
    );
  };

  const systemCategories = categories.filter(c => c.isSystem);
  const customCategories = categories.filter(c => !c.isSystem);

  const renderEmptyState = () => (
    <View style={styles.emptyContainer}>
      <Icon name="folder-outline" size={80} color="#C7C7CC" />
      <Text style={styles.emptyTitle}>暂无自定义分类</Text>
      <Text style={styles.emptyDescription}>
        点击右上角 + 创建自定义分类{'\n'}为你的记账添加个性化标签
      </Text>
      <TouchableOpacity
        style={styles.createButton}
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          setShowAddCategory(true);
        }}
      >
        <Text style={styles.createButtonText}>创建分类</Text>
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
        {categories.length === 0 ? (
          renderEmptyState()
        ) : (
          <>
            {/* 系统分类 */}
            {systemCategories.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>系统分类</Text>
                <View style={styles.categoryList}>
                  {systemCategories.map(cat => renderCategoryRow(cat, true))}
                </View>
              </View>
            )}

            {/* 自定义分类 */}
            {customCategories.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>自定义分类</Text>
                <View style={styles.categoryList}>
                  {customCategories.map(cat => renderCategoryRow(cat, false))}
                </View>
              </View>
            )}
          </>
        )}
      </ScrollView>

      {/* Add Category Modal */}
      <AddCategoryModal
        visible={showAddCategory}
        category={null}
        onClose={() => setShowAddCategory(false)}
      />

      {/* Edit Category Modal */}
      {categoryToEdit && (
        <AddCategoryModal
          visible={!!categoryToEdit}
          category={categoryToEdit}
          onClose={() => setCategoryToEdit(null)}
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
  sectionTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#8E8E93',
    textTransform: 'uppercase',
    paddingHorizontal: 16,
    paddingBottom: 8,
  },
  categoryList: {
    backgroundColor: '#FFFFFF',
    marginHorizontal: 16,
    borderRadius: 12,
    overflow: 'hidden',
  },
  categoryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  iconContainer: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 16,
  },
  categoryInfo: {
    flex: 1,
  },
  categoryName: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 4,
  },
  keywords: {
    fontSize: 13,
    color: '#8E8E93',
  },
  customBadge: {
    backgroundColor: '#007AFF1A',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
    marginRight: 12,
  },
  customBadgeText: {
    fontSize: 12,
    color: '#007AFF',
    fontWeight: '500',
  },
  actionsContainer: {
    flexDirection: 'row',
    gap: 8,
  },
  actionButton: {
    padding: 8,
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

export default CategoryManagementScreen;
