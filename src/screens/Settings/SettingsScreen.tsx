/**
 * 设置界面
 * 对应 Swift 版本的 SettingsView.swift
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Alert,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import DataManager from '../../services/DataManager';
import CategoryEngine from '../../services/CategoryEngine';

const SettingsScreen: React.FC = () => {
  const handleClearData = () => {
    Alert.alert(
      '确认清除数据',
      '此操作将删除所有交易记录、自定义分类和预算设置，且无法恢复。确定要继续吗？',
      [
        { text: '取消', style: 'cancel' },
        {
          text: '确定',
          style: 'destructive',
          onPress: async () => {
            try {
              await DataManager.clearAllData();
              await CategoryEngine.clearUserData();
              Alert.alert('成功', '所有数据已清除');
            } catch (error) {
              Alert.alert('错误', '清除数据失败');
              console.error('Failed to clear data:', error);
            }
          },
        },
      ]
    );
  };

  const renderSettingItem = (
    icon: string,
    title: string,
    onPress: () => void,
    color: string = '#007AFF'
  ) => (
    <TouchableOpacity style={styles.settingItem} onPress={onPress}>
      <View style={styles.settingLeft}>
        <Icon name={icon} size={24} color={color} />
        <Text style={styles.settingTitle}>{title}</Text>
      </View>
      <Icon name="chevron-forward" size={20} color="#C7C7CC" />
    </TouchableOpacity>
  );

  const renderSectionHeader = (title: string) => (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionTitle}>{title}</Text>
    </View>
  );

  return (
    <ScrollView style={styles.container}>
      {/* 数据管理 */}
      {renderSectionHeader('数据管理')}
      <View style={styles.settingGroup}>
        {renderSettingItem('folder-outline', '分类管理', () => {
          Alert.alert('提示', '分类管理功能开发中');
        })}
        {renderSettingItem('wallet-outline', '预算管理', () => {
          Alert.alert('提示', '预算管理功能开发中');
        })}
        {renderSettingItem('cloud-download-outline', '数据导出', () => {
          Alert.alert('提示', '数据导出功能开发中');
        })}
        {renderSettingItem(
          'trash-outline',
          '清除所有数据',
          handleClearData,
          '#FF3B30'
        )}
      </View>

      {/* 快捷指令 */}
      {renderSectionHeader('快捷指令')}
      <View style={styles.settingGroup}>
        {renderSettingItem('flash-outline', '配置快捷指令', () => {
          Alert.alert('提示', '快捷指令配置功能开发中');
        })}
        {renderSettingItem('notifications-outline', '通知设置', () => {
          Alert.alert('提示', '通知设置功能开发中');
        })}
      </View>

      {/* 关于 */}
      {renderSectionHeader('关于')}
      <View style={styles.settingGroup}>
        {renderSettingItem('information-circle-outline', '关于应用', () => {
          Alert.alert(
            '无感记账',
            '版本: 1.0.0\n\n一款基于 React Native 的智能记账应用'
          );
        })}
        {renderSettingItem('help-circle-outline', '使用帮助', () => {
          Alert.alert('提示', '使用帮助功能开发中');
        })}
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>无感记账 v1.0.0</Text>
        <Text style={styles.footerSubText}>
          React Native 版本
        </Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F2F2F7',
  },
  sectionHeader: {
    paddingHorizontal: 16,
    paddingTop: 20,
    paddingBottom: 8,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#8E8E93',
    textTransform: 'uppercase',
  },
  settingGroup: {
    backgroundColor: '#FFFFFF',
    marginBottom: 20,
  },
  settingItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E5E5EA',
  },
  settingLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  settingTitle: {
    fontSize: 16,
    color: '#000000',
    marginLeft: 12,
  },
  footer: {
    paddingVertical: 40,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 14,
    color: '#8E8E93',
    marginBottom: 4,
  },
  footerSubText: {
    fontSize: 12,
    color: '#C7C7CC',
  },
});

export default SettingsScreen;
